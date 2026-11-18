import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

import '../../../../domain/catalog/external_anime_id.dart';
import '../../../../domain/player/providers/anime_identity.dart';
import '../../../../domain/player/providers/episode_source.dart';
import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';
import '../hosts/direct_media_host_resolver.dart';
import '../public_playback_http.dart';

enum AllAnimeAudioVariant { sub, dub }

/// Build-pinned crypto materials for the AllAnime/M.Kissa client-crypto
/// protocol. The site rotates the mask and build id per release; the values
/// are public client constants (they live in the site's own JS bundle, chunk
/// `B3DA467b.js` for build 190) and are refreshed per release, exactly like
/// every maintained CLI client does.
///
/// Protocol (verified live 2026-11-18, mission ANILILI):
/// 1. epoch = now / 604800000; boot token =
///    hex(HMAC-SHA256(HMAC-SHA256(mask, bootPrefix), joinPrefix + epoch)) sent
///    as `x-aa-boot` to `/client-crypto/v1/bootstrap?buildId=B&k=k7`, which
///    returns the authoritative `epoch` and `partB` (base64 32 bytes).
/// 2. request key = partB XOR mask (32 bytes).
/// 3. `aaReq` = base64(0x01 ‖ iv ‖ AES-256-GCM(key, iv, payload)) where
///    payload = {v:1, ts:<5-min window>, epoch, buildId, qh, k:k7} and
///    iv = SHA-256("epoch:buildId:qh:ts:lane")[0..12].
/// 4. The episode sources GraphQL query carries `extensions` with the
///    persistedQuery hash, the lane `k`, and `aaReq`, plus `x-build-id` and
///    `x-aa-boot` headers.
/// 5. `tobeparsed` = base64(0x01 ‖ iv ‖ ct ‖ tag) AES-256-GCM with the SAME
///    dynamic key; its `episode.sourceUrls` list contains direct media
///    (`type: "player"`) and iframe routes (skipped, never returned).
final class AllAnimeBootMaterials {
  const AllAnimeBootMaterials({
    required this.buildId,
    required this.maskHex,
    required this.bootPrefix,
    required this.joinPrefix,
    required this.queryHash,
    this.lane = 'k7',
  });

  /// Materials for build 190 (chunk B3DA467b.js, verified live 2026-11-18).
  static const AllAnimeBootMaterials current = AllAnimeBootMaterials(
    buildId: '190',
    maskHex: '65c85a8520d83eafafdff966cc3f5187ab774d238f60338ff4fc0ae7d941ca35',
    bootPrefix: 'rEVwtVi:190',
    joinPrefix: 'mkissa.to~k7~190~mkissa~',
    queryHash: '670bbf38d0868f446e2346c1e956ca2c40c416e733ca248fd54e04f1c8b99145',
  );

  final String buildId;
  final String maskHex;
  final String bootPrefix;
  final String joinPrefix;
  final String queryHash;
  final String lane;

  /// Epoch length in milliseconds (7 days), from the bootstrap response.
  static const int epochMs = 604800000;
}

final class AllAnimePlaybackProvider extends EpisodeSourceAdapter {
  AllAnimePlaybackProvider(
    Dio client, {
    Uri? apiOrigin,
    this.variant = AllAnimeAudioVariant.sub,
    PublicPlaybackHttp? transport,
    AllAnimeBootMaterials materials = AllAnimeBootMaterials.current,
  }) : apiOrigin = apiOrigin ?? Uri.https('api.mkissa.net'),
       _materials = materials {
    if (!DirectMediaHostResolver.isSyntacticallyPublicHttps(this.apiOrigin) ||
        !const {'', '/'}.contains(this.apiOrigin.path) ||
        this.apiOrigin.hasQuery) {
      throw ArgumentError.value(this.apiOrigin, 'apiOrigin');
    }
    final Uint8List mask = _hexDecode(materials.maskHex);
    if (mask.length != 32) {
      throw ArgumentError.value(materials.maskHex, 'materials.maskHex');
    }
    _mask = mask;
    _http = transport ??
        PublicPlaybackHttp(client, {this.apiOrigin.host, 'allanime.day'});
  }

  /// GraphQL API origin; the media relay (`clock.json`) stays on allanime.day.
  final Uri apiOrigin;
  final AllAnimeAudioVariant variant;
  final AllAnimeBootMaterials _materials;
  late final Uint8List _mask;
  late final PublicPlaybackHttp _http;

  static final RegExp _showId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static final RegExp _number = RegExp(r'^[1-9][0-9]{0,9}$');
  static final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _mediaUrl = RegExp(
    r'\.(?:m3u8|mp4)(?:[?#]|$)',
    caseSensitive: false,
  );
  static const int _aaReqWindowMs = 300000;

  @override
  PlaybackProviderId get id => PlaybackProviderId(
    variant == AllAnimeAudioVariant.sub ? 'allanime' : 'allanime-dub',
  );

  @override
  Set<PlaybackProviderCapability> get capabilities => const {
    PlaybackProviderCapability.episodeSources,
    PlaybackProviderCapability.sourceAlternatives,
  };

  PlaybackRequestHeaders get _apiHeaders => PlaybackRequestHeaders({
    'Referer': 'https://mkissa.to/',
    'Origin': 'https://mkissa.to',
  });

  /// Direct media candidates carry a browser User-Agent: the fast4speed CDN
  /// throttles library clients (verified live, same family as vidcache).
  PlaybackRequestHeaders get _mediaHeaders => PlaybackRequestHeaders({
    'Referer': 'https://mkissa.to/',
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  });

  int? _mal(AnimeIdentity identity) {
    final ids = identity.externalIds
        .where((value) => value.providerId.value == 'myanimelist')
        .toList();
    if (ids.length != 1 || !_number.hasMatch(ids.single.value)) return null;
    final int? parsed = int.tryParse(ids.single.value);
    return parsed != null && parsed <= 0x7fffffff ? parsed : null;
  }

  bool _validMatch(SourceAnimeMatch match) =>
      match.providerId == id &&
      match.adapterVersion == adapterVersion &&
      _showId.hasMatch(match.sourceAnimeId) &&
      (match.evidence == AnimeMatchEvidence.externalId ||
          match.evidence == AnimeMatchEvidence.exactTitle) &&
      match.isConservativeMatch();

  EpisodeRef _episode(SourceAnimeMatch match, int number) => EpisodeRef(
    anime: match,
    episodeId: 'allanime:${match.sourceAnimeId}:$number:${variant.name}',
    episodeNumber: number,
    declaredLanguage: variant.name,
    mappingEvidence:
        'AllAnime show id and exact episode string; sources are '
        'verified when the episode is resolved',
  );

  static String _contractTitle(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity identity, {
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    if (identity.titles.isEmpty) return null;
    final int? mal = _mal(identity);
    final List<String> requested = identity.titles
        .map(_contractTitle)
        .where((String title) => title.isNotEmpty)
        .toList();
    final seen = <String>{};
    final candidates = <({String id, String name, String? english, int? mal})>[];
    for (final String title in identity.titles.take(3)) {
      _check(cancellation);
      for (final candidate in await _search(title, cancellation)) {
        if (!seen.add(candidate.id)) continue;
        candidates.add(candidate);
        if (mal != null && candidate.mal == mal) {
          return [
            SourceAnimeMatch(
              providerId: id,
              sourceAnimeId: candidate.id,
              title: candidate.name,
              requestedIdentity: identity,
              evidence: AnimeMatchEvidence.externalId,
              externalIds: [
                ExternalAnimeId(
                  providerId: MetadataProviderId('myanimelist'),
                  value: '$mal',
                ),
              ],
              adapterVersion: adapterVersion,
            ),
          ];
        }
      }
    }
    for (final candidate in candidates.take(40)) {
      final List<String> names = [
        candidate.name,
        if (candidate.english != null) candidate.english!,
      ].map(_contractTitle).toList();
      if (requested.any(names.contains)) {
        return [
          SourceAnimeMatch(
            providerId: id,
            sourceAnimeId: candidate.id,
            title: candidate.name,
            requestedIdentity: identity,
            evidence: AnimeMatchEvidence.exactTitle,
            adapterVersion: adapterVersion,
          ),
        ];
      }
    }
    return null;
  });

  Future<
    List<({String id, String name, String? english, int? mal})>
  >
  _search(String query, PlaybackCancellationToken cancellation) async {
    final String body = jsonEncode({
      'query': _searchQuery,
      'variables': {
        'search': {'allowAdult': false, 'allowUnknown': false, 'query': query},
        'limit': 20,
        'page': 1,
        'translationType': variant.name,
        'countryOrigin': 'ALL',
      },
    });
    final String text = await _http.readJson(
      apiOrigin.resolve('/api'),
      cancellation,
      jsonBody: body,
      stage: PlaybackHttpStage.catalog,
      headers: _apiHeaders,
    );
    final Object? decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid AllAnime search answer');
    }
    final Object? data = decoded['data'];
    final Object? shows = data is Map ? data['shows'] : null;
    final Object? edges = shows is Map ? shows['edges'] : null;
    if (edges is! List) return const [];
    final result = <({String id, String name, String? english, int? mal})>[];
    for (final Object? edge in edges.take(40)) {
      if (edge is! Map) continue;
      final Object? id = edge['_id'];
      final Object? name = edge['name'];
      if (id is! String ||
          !_showId.hasMatch(id) ||
          name is! String ||
          name.trim().isEmpty ||
          name.length > 256) {
        continue;
      }
      final Object? english = edge['englishName'];
      final Object? malId = edge['malId'];
      result.add((
        id: id,
        name: name,
        english: english is String && english.trim().isNotEmpty
            ? english
            : null,
        // The API ships malId as a numeric string; accept both shapes.
        mal: malId is int
            ? malId
            : malId is String && int.tryParse(malId) != null
            ? int.tryParse(malId)
            : null,
      ));
    }
    return result;
  }

  static const String _searchQuery =
      'query(\$search: SearchInput, \$limit: Int, \$page: Int, '
      '\$translationType: VaildTranslationTypeEnumType, '
      '\$countryOrigin: VaildCountryOriginEnumType) '
      '{ shows(search: \$search, limit: \$limit, page: \$page, '
      'translationType: \$translationType, countryOrigin: \$countryOrigin) '
      '{ edges { _id name englishName malId availableEpisodes } } }';

  @override
  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  }) async => cancellation.isCancelled
      ? const PlaybackProviderFailed<List<EpisodeRef>>(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        )
      : const PlaybackProviderUnsupported<List<EpisodeRef>>(
          PlaybackProviderCapability.episodeSources,
        );

  @override
  Future<PlaybackProviderResult<EpisodeRef>> findEpisode(
    SourceAnimeMatch match, {
    required int episodeNumber,
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    if (!_validMatch(match) || episodeNumber < 1) return null;
    return _episode(match, episodeNumber);
  });

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  }) => _read(() async {
    _check(cancellation);
    if (!_validMatch(episode.anime) ||
        episode.episodeId !=
            _episode(episode.anime, episode.episodeNumber).episodeId) {
      throw const FormatException('Invalid episode identity');
    }
    // 1. Bootstrap the per-epoch key material.
    final ({int epoch, Uint8List key}) boot = await _bootstrap(cancellation);
    // 2. Signed sources query.
    final String body = await _sourcesAnswer(episode, boot, cancellation);
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid AllAnime source answer');
    }
    final Object? data = decoded['data'];
    final Map<String, dynamic> episodeData;
    final Object? tobeparsed = data is Map ? data['tobeparsed'] : null;
    if (tobeparsed is String && tobeparsed.isNotEmpty) {
      episodeData = await _decryptTobeparsed(tobeparsed, boot.key);
    } else if (data is Map && data['episode'] is Map) {
      episodeData = data['episode'] as Map<String, dynamic>;
    } else {
      // The API answers HTTP 200 with an errors array when the aaReq token is
      // rejected. A captcha demand is an access challenge (never solved or
      // evaded here); a stale or rejected token degrades to noSources so the
      // manager can fall back to other providers.
      final Object? errors = decoded['errors'];
      final bool captcha = errors is List &&
          errors.any(
            (Object? error) =>
                error is Map &&
                (error['message'] == 'NEED_CAPTCHA' ||
                    (error['extensions'] is Map &&
                        (error['extensions'] as Map)['code'] == 'NEED_CAPTCHA')),
          );
      throw PublicPlaybackFailure(
        captcha
            ? PlaybackProviderFailureKind.challenge
            : PlaybackProviderFailureKind.noSources,
      );
    }
    final List<SourceCandidate> servers = _servers(episodeData, cancellation);
    if (servers.isEmpty) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.noSources);
    }
    return [
      PlaybackSource(
        id: episode.episodeId,
        providerId: id,
        episode: PlaybackEpisode.fromIdentity(
          episode.anime.requestedIdentity,
          episodeNumber: episode.episodeNumber,
        ),
        language: variant.name,
        quality: 'Auto',
        providerAnnouncedLanguage: variant.name,
        displayName: variant == AllAnimeAudioVariant.sub
            ? 'AllAnime · Original (sub)'
            : 'AllAnime · Doblaje (dub)',
        servers: servers,
      ),
    ];
  });

  /// Bootstraps the per-epoch key: HMAC boot token over the current epoch
  /// (plus the previous epoch inside the server's grace window), then
  /// partB XOR mask.
  Future<({int epoch, Uint8List key})> _bootstrap(
    PlaybackCancellationToken cancellation,
  ) async {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int epoch = nowMs ~/ AllAnimeBootMaterials.epochMs;
    Map<String, dynamic>? answer;
    PublicPlaybackFailure? lastFailure;
    for (final int candidate in {epoch, max(epoch - 1, 0)}) {
      _check(cancellation);
      final String token = await _bootToken(candidate);
      try {
        final String text = await _http.read(
          apiOrigin
              .resolve('/client-crypto/v1/bootstrap')
              .replace(queryParameters: {
                'buildId': _materials.buildId,
                'k': _materials.lane,
              }),
          cancellation,
          stage: PlaybackHttpStage.catalog,
          headers: PlaybackRequestHeaders({
            'Referer': 'https://mkissa.to/',
            'Origin': 'https://mkissa.to',
            'User-Agent': _browserUa,
            'x-build-id': _materials.buildId,
            'x-aa-boot': token,
          }),
        );
        final Object? decoded = jsonDecode(text);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid AllAnime bootstrap answer');
        }
        answer = decoded;
        break;
      } on PublicPlaybackFailure catch (error) {
        // {"error":"invalid_boot_token"} means the epoch guess was wrong or
        // the build materials rotated; try the adjacent epoch once.
        lastFailure = error;
      }
    }
    if (answer == null) {
      throw lastFailure ??
          const PublicPlaybackFailure(PlaybackProviderFailureKind.noSources);
    }
    if (answer['error'] == 'invalid_boot_token') {
      // Build materials rotated server-side; a release refresh is required.
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.unavailable);
    }
    final Object? epochValue = answer['epoch'];
    final Object? partBValue = answer['partB'];
    if (epochValue is! int || partBValue is! String) {
      throw const FormatException('Invalid AllAnime bootstrap answer');
    }
    final Uint8List partB = base64.decode(base64.normalize(partBValue));
    if (partB.length != 32) {
      throw const FormatException('Invalid AllAnime partB');
    }
    final Uint8List key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = partB[i] ^ _mask[i];
    }
    return (epoch: epochValue, key: key);
  }

  /// Desktop web client UA: the API demands a captcha for non-desktop client
  /// classes on the sources query (verified live 2026-11-18).
  static const String _browserUa =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  Future<String> _bootToken(int epoch) async {
    final Mac inner = await Hmac.sha256().calculateMac(
      utf8.encode(_materials.bootPrefix),
      secretKey: SecretKey(_mask),
    );
    final Mac outer = await Hmac.sha256().calculateMac(
      utf8.encode('${_materials.joinPrefix}$epoch'),
      secretKey: SecretKey(inner.bytes),
    );
    return outer.bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<String> _sourcesAnswer(
    EpisodeRef episode,
    ({int epoch, Uint8List key}) boot,
    PlaybackCancellationToken cancellation,
  ) async {
    final String aaReq = await _aaReq(boot, cancellation);
    final String variables = jsonEncode({
      'showId': episode.sourceAnimeId,
      'translationType': variant.name,
      'episodeString': '${episode.episodeNumber}',
    });
    final String extensions = jsonEncode({
      'persistedQuery': {'version': 1, 'sha256Hash': _materials.queryHash},
      'k': _materials.lane,
      'aaReq': aaReq,
    });
    final Uri uri = apiOrigin.resolve('/api').replace(
      queryParameters: {'variables': variables, 'extensions': extensions},
    );
    return _http.read(
      uri,
      cancellation,
      stage: PlaybackHttpStage.episode,
      headers: PlaybackRequestHeaders({
        'Referer': 'https://mkissa.to/',
        'Origin': 'https://mkissa.to',
        'User-Agent': _browserUa,
        'x-build-id': _materials.buildId,
        'x-aa-boot': await _bootToken(boot.epoch),
      }),
    );
  }

  Future<String> _aaReq(
    ({int epoch, Uint8List key}) boot,
    PlaybackCancellationToken cancellation,
  ) async {
    final int ts =
        DateTime.now().millisecondsSinceEpoch ~/
        _aaReqWindowMs *
        _aaReqWindowMs;
    final String payload = jsonEncode({
      'v': 1,
      'ts': ts,
      'epoch': boot.epoch,
      'buildId': _materials.buildId,
      'qh': _materials.queryHash,
      'k': _materials.lane,
    });
    final String ivSeed =
        '${boot.epoch}:${_materials.buildId}:${_materials.queryHash}'
        ':$ts:${_materials.lane}';
    final Hash ivHash = await Sha256().hash(utf8.encode(ivSeed));
    final Uint8List iv = Uint8List.fromList(ivHash.bytes.sublist(0, 12));
    final SecretBox box = await AesGcm.with256bits().encrypt(
      utf8.encode(payload),
      secretKey: SecretKey(boot.key),
      nonce: iv,
    );
    // Wire format from the site client: 0x01 || iv || ciphertext || tag.
    final Uint8List wire = Uint8List(
      13 + box.cipherText.length + box.mac.bytes.length,
    );
    wire[0] = 1;
    wire.setRange(1, 13, iv);
    wire.setRange(13, 13 + box.cipherText.length, box.cipherText);
    wire.setRange(
      13 + box.cipherText.length,
      wire.length,
      box.mac.bytes,
    );
    return base64.encode(wire);
  }

  Future<Map<String, dynamic>> _decryptTobeparsed(
    String blob,
    Uint8List key,
  ) async {
    final Uint8List bytes = base64.decode(base64.normalize(blob));
    if (bytes.length < 29 + 1 || bytes[0] != 1) {
      throw const FormatException('Invalid tobeparsed envelope');
    }
    final Uint8List iv = bytes.sublist(1, 13);
    final Uint8List ct = bytes.sublist(13, bytes.length - 16);
    final Uint8List tag = bytes.sublist(bytes.length - 16);
    final List<int> clear = await AesGcm.with256bits().decrypt(
      SecretBox(ct, nonce: iv, mac: Mac(tag)),
      secretKey: SecretKey(key),
    );
    final Object? decoded = jsonDecode(utf8.decode(clear));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid tobeparsed payload');
    }
    return decoded;
  }

  List<SourceCandidate> _servers(
    Map<String, dynamic> episodeData,
    PlaybackCancellationToken cancellation,
  ) {
    final Object? episode = episodeData['episode'];
    final Object? rawUrls = episode is Map ? episode['sourceUrls'] : null;
    if (rawUrls is! List) return const [];
    final servers = <SourceCandidate>[];
    final seen = <String>{};
    for (final Object? entry in rawUrls.take(32)) {
      if (servers.length >= 12) break;
      if (entry is! Map) continue;
      final Object? url = entry['sourceUrl'];
      if (url is! String || url.isEmpty || url.length > 8192) continue;
      final Object? type = entry['type'];
      // Iframe routes need a browser; never returned as playable.
      final bool direct =
          (type is String && type.toLowerCase() == 'player') ||
              _mediaUrl.hasMatch(url);
      if (!direct) continue;
      _addCandidate(servers, seen, url, Map<String, dynamic>.from(entry));
    }
    return servers;
  }

  void _addCandidate(
    List<SourceCandidate> servers,
    Set<String> seen,
    String url,
    Map<String, dynamic> entry,
  ) {
    if (!seen.add(url)) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null ||
        !DirectMediaHostResolver.isSyntacticallyPublicHttps(uri)) {
      return;
    }
    final Object? name = entry['sourceName'];
    final String label = name is String && name.trim().isNotEmpty
        ? name.trim()
        : 'AllAnime';
    servers.add(
      SourceCandidate(
        id: 'allanime-${servers.length}',
        endpoint: uri,
        hostId: DirectMediaHostResolver.stableHostId,
        kind: PlaybackCandidateKind.media,
        mediaFormat: _isHls(url)
            ? PlaybackMediaFormat.hls
            : PlaybackMediaFormat.mp4,
        quality: 'Auto',
        displayName: 'AllAnime $label',
        sourceEpisodeId: null,
        requestHeaders: _mediaHeaders,
        provenance: 'AllAnime client-crypto sources (mkissa build 190)',
      ),
    );
  }

  static bool _isHls(String url) =>
      url.toLowerCase().contains('.m3u8') ||
      url.toLowerCase().contains('repackager.wixmp');

  static Uint8List _hexDecode(String hex) {
    if (hex.length != 64 || !_hex64.hasMatch(hex)) {
      throw ArgumentError.value(hex, 'hex');
    }
    final Uint8List out = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static void _check(PlaybackCancellationToken cancellation) {
    if (cancellation.isCancelled) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.cancelled);
    }
  }

  Future<PlaybackProviderResult<T>> _read<T>(Future<T?> Function() load) async {
    try {
      final T? value = await load();
      return value == null
          ? PlaybackProviderEmpty<T>()
          : PlaybackProviderSuccess<T>(value);
    } on PublicPlaybackFailure catch (error) {
      return error.result<T>();
    } on FormatException {
      return PlaybackProviderFailed<T>(
        const PlaybackProviderFailure(
          PlaybackProviderFailureKind.invalidResponse,
        ),
      );
    } on ArgumentError {
      return PlaybackProviderFailed<T>(
        const PlaybackProviderFailure(
          PlaybackProviderFailureKind.invalidResponse,
        ),
      );
    }
  }
}
