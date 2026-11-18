import 'dart:convert';

import 'package:anime_app/domain/player/providers/episode_source.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';

import '../hosts/direct_media_host_resolver.dart';

/// Typed view of the public Miruro catalog config used by Anilili.
final class MiruroProviderConfig {
  const MiruroProviderConfig({
    required this.key,
    required this.label,
    required this.visible,
    this.parent,
    this.isEmbed = false,
    this.announcedLanguage = 'unknown',
  });

  final String key;
  final String label;
  final bool visible;
  final String? parent;
  final bool isEmbed;
  final String announcedLanguage;
}

final class MiruroTitleRecord {
  const MiruroTitleRecord({
    required this.id,
    this.title,
    this.subCount,
    this.dubCount,
  });

  final String id;
  final String? title;
  final int? subCount;
  final int? dubCount;
}

final class MiruroCatalogEpisode {
  const MiruroCatalogEpisode({required this.number, this.title, this.kind});

  final int number;
  final String? title;
  final String? kind;
}

/// Pure parser for the catalog protocol and its provider alternatives.
///
/// It follows Anilili's separation between catalog decoding, provider identity,
/// episode numbering and the streams returned by one `play` response. Direct
/// media URLs are kept as host candidates; quality variants on the same server
/// are collapsed to the highest declared rendition so they are not presented
/// as separate servers.
final class MiruroCatalogParser {
  const MiruroCatalogParser();

  static const int maxProviders = 64;
  static const int maxEpisodes = 20000;
  static const int maxServersPerSource = 32;

  List<MiruroProviderConfig> parseConfig(String body) {
    final Map<String, dynamic> root = _decodeObject(body);
    final Map<String, dynamic>? streaming = _object(root['streaming']);
    if (streaming == null) return const [];
    final List<String> order = _array(root['providerOrder'])
        .whereType<String>()
        .take(maxProviders)
        .toList();
    final List<MiruroProviderConfig> providers = [];
    for (final MapEntry<String, dynamic> entry in streaming.entries) {
      if (providers.length >= maxProviders) break;
      final Map<String, dynamic>? value = _object(entry.value);
      if (value == null || !_validKey(entry.key)) continue;
      final String label = _text(value['label']) ?? entry.key;
      final String? parent = _text(value['parent']);
      final String? language = _languageTag(
        value['language'] ?? value['announcedLanguage'],
      );
      providers.add(
        MiruroProviderConfig(
          key: entry.key,
          label: label,
          visible: value['visible'] is bool ? value['visible'] as bool : true,
          parent: parent != null && _validKey(parent) ? parent : null,
          isEmbed: value['relationship'] == 'embed',
          announcedLanguage: language ?? 'unknown',
        ),
      );
    }
    final Map<String, int> rank = {
      for (int i = 0; i < order.length; i++) order[i]: i,
    };
    providers.sort((MiruroProviderConfig a, MiruroProviderConfig b) {
      final int comparison = (rank[a.key] ?? order.length).compareTo(
        rank[b.key] ?? order.length,
      );
      return comparison != 0 ? comparison : a.key.compareTo(b.key);
    });
    return List.unmodifiable(providers);
  }

  MiruroTitleRecord? parseTitle(String body, {required int anilistId}) {
    final Map<String, dynamic> root = _decodeObject(body);
    final List<Map<String, dynamic>> entries = _array(root['data'])
        .take(maxProviders)
        .map(_object)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final List<Map<String, dynamic>> explicitMatches = entries
        .where((Map<String, dynamic> value) {
          final int? mapped = _int(value['anilist_id'] ?? value['anilistId']);
          return mapped == anilistId;
        })
        .toList(growable: false);
    final List<Map<String, dynamic>> candidates = explicitMatches.isNotEmpty
        ? explicitMatches
        : entries.length == 1 &&
              _int(
                    entries.single['anilist_id'] ?? entries.single['anilistId'],
                  ) ==
                  null
        ? entries
        : const [];
    if (candidates.length != 1) return null;
    for (final Map<String, dynamic> value in candidates) {
      final String? id = _text(value['id']);
      if (id == null || !_validTitleId(id)) continue;
      final Map<String, dynamic>? counts = _object(value['episode_counts']);
      return MiruroTitleRecord(
        id: id,
        title: _title(value['title']),
        subCount: _positiveInt(counts?['sub']),
        dubCount: _positiveInt(counts?['dub']),
      );
    }
    return null;
  }

  ({List<MiruroCatalogEpisode> episodes, String? nextCursor}) parseEpisodes(
    String body,
  ) {
    final Map<String, dynamic> root = _decodeObject(body);
    final List<MiruroCatalogEpisode> episodes = [];
    final Set<int> seen = {};
    for (final Object? raw in _array(root['data']).take(maxEpisodes)) {
      final Map<String, dynamic>? episode = _object(raw);
      if (episode == null) continue;
      final String? kind = _text(episode['kind']);
      if (kind != null && kind.toLowerCase() != 'regular') continue;
      final double? number = _number(episode['episode_number']);
      if (number == null || number <= 0 || number > maxEpisodes) continue;
      final int rounded = number.round();
      if ((number - rounded).abs() > 0.0001 || !seen.add(rounded)) continue;
      episodes.add(
        MiruroCatalogEpisode(
          number: rounded,
          title: _text(episode['title']),
          kind: kind,
        ),
      );
    }
    final bool hasMore = root['has_more'] == true;
    final String? cursor = hasMore ? _text(root['next_cursor']) : null;
    if (hasMore && cursor == null) {
      throw const FormatException('Miruro pagination cursor is missing.');
    }
    return (episodes: List.unmodifiable(episodes), nextCursor: cursor);
  }

  List<PlaybackSource> parsePlaybackSources({
    required String body,
    required List<MiruroProviderConfig> config,
    required EpisodeRef episode,
  }) {
    final Map<String, dynamic> root = _decodeObject(body);
    final Map<String, MiruroProviderConfig> byKey = {
      for (final MiruroProviderConfig provider in config)
        provider.key: provider,
    };
    final List<PlaybackSource> sources = [];
    for (final Object? rawTrack in _array(root['tracks']).take(8)) {
      final Map<String, dynamic>? track = _object(rawTrack);
      final String? trackName = _text(track?['track'])?.toLowerCase();
      if (track == null || !const {'sub', 'ssub', 'dub'}.contains(trackName)) {
        continue;
      }
      for (final Object? rawProvider in _array(
        track['providers'],
      ).take(maxProviders)) {
        final Map<String, dynamic>? provider = _object(rawProvider);
        final String? key = _text(provider?['provider']);
        if (provider == null || key == null || !_validKey(key)) continue;
        final MiruroProviderConfig? entry = byKey[key];
        if (entry == null || !entry.visible || entry.isEmbed) continue;

        final List<SourceCandidate> candidates = _serverCandidates(
          _array(provider['servers']),
          providerKey: key,
          providerLabel: entry.label,
          track: trackName!,
          declaredLanguage: entry.announcedLanguage,
          sourceEpisodeId: episode.episodeId,
        );
        if (candidates.isEmpty) continue;

        final String languageName = switch (trackName) {
          'dub' => 'dub',
          'ssub' => 'soft-sub',
          _ => 'sub',
        };
        final String titleId = episode.sourceAnimeId;
        sources.add(
          PlaybackSource(
            id: 'miruro:$titleId:${episode.episodeNumber}:$key:$trackName',
            providerId: episode.providerId,
            episode: PlaybackEpisode.fromIdentity(
              episode.anime.requestedIdentity,
              episodeNumber: episode.episodeNumber,
            ),
            language: languageName,
            quality: 'Auto',
            displayName: '${entry.label} · $languageName',
            audioLanguage: _languageFrom(provider, 'audio_language'),
            subtitleLanguage: _languageFrom(provider, 'subtitle_language'),
            dubbingType: trackName == 'dub'
                ? _dubbingType(provider['dub_type'] ?? provider['dubbing_type'])
                : PlaybackDubbingType.unknown,
            providerAnnouncedLanguage: entry.announcedLanguage,
            priority: -sources.length,
            servers: candidates,
          ),
        );
      }
    }
    return List.unmodifiable(sources);
  }

  List<SourceCandidate> _serverCandidates(
    List<Object?> rawServers, {
    required String providerKey,
    required String providerLabel,
    required String track,
    required String declaredLanguage,
    required String sourceEpisodeId,
  }) {
    final List<SourceCandidate> candidates = [];
    final Set<String> ids = {};
    for (final Object? rawServer in rawServers.take(maxServersPerSource)) {
      final Map<String, dynamic>? server = _object(rawServer);
      if (server == null) continue;
      final String? serverName = _text(server['server']);
      if (serverName == null) continue;
      final List<({Uri uri, PlaybackMediaFormat format, String? quality})>
      renditions = [];
      for (final Object? rawStream in _array(server['streams']).take(16)) {
        final Map<String, dynamic>? stream = _object(rawStream);
        final String? url = _text(stream?['url']);
        final Uri? uri = url == null ? null : Uri.tryParse(url);
        if (stream == null || uri == null || !_validDirectUri(uri)) continue;
        final PlaybackMediaFormat format = _mediaFormat(
          _text(stream['format']),
          uri,
        );
        if (format == PlaybackMediaFormat.unknown) continue;
        renditions.add((
          uri: uri,
          format: format,
          quality: _text(stream['quality']) ?? _text(stream['resolution']),
        ));
      }
      if (renditions.isEmpty) continue;
      var chosen = renditions.first;
      for (final rendition in renditions.skip(1)) {
        if (_qualityScore(rendition.quality) > _qualityScore(chosen.quality)) {
          chosen = rendition;
        }
      }
      final String baseId = '$providerKey-${_slug(serverName)}';
      String candidateId = baseId;
      int collision = 2;
      if (candidateId.length > 120) {
        candidateId = candidateId.substring(0, 120);
      }
      while (!ids.add(candidateId)) {
        final String suffix = '-$collision';
        final int prefixLength = (120 - suffix.length).clamp(1, 120).toInt();
        candidateId =
            '${baseId.substring(0, baseId.length.clamp(1, prefixLength).toInt())}'
            '$suffix';
        collision++;
      }
      final String? referer = _safeReferer(server['headers']);
      candidates.add(
        SourceCandidate(
          id: candidateId,
          displayName: serverName,
          endpoint: chosen.uri,
          hostId: DirectMediaHostResolver.stableHostId,
          priority: -candidates.length,
          kind: PlaybackCandidateKind.media,
          declaredLanguage: declaredLanguage,
          mediaFormat: chosen.format,
          quality: chosen.quality,
          availability: PlaybackAvailability.listed,
          sourceEpisodeId: sourceEpisodeId,
          provenance: 'Miruro catalog · $providerLabel · $track · $serverName',
          requestHeaders: referer == null
              ? const PlaybackRequestHeaders.empty()
              : PlaybackRequestHeaders({'Referer': referer}),
        ),
      );
    }
    return List.unmodifiable(candidates);
  }

  static String? _safeReferer(Object? rawHeaders) {
    final Map<String, dynamic>? headers = _object(rawHeaders);
    if (headers == null) return null;
    for (final MapEntry<String, dynamic> entry in headers.entries) {
      if (entry.key.toLowerCase() != 'referer') continue;
      final String? value = _text(entry.value);
      final Uri? uri = value == null ? null : Uri.tryParse(value);
      if (uri == null ||
          uri.hasQuery ||
          !DirectMediaHostResolver.isSyntacticallyPublicHttps(uri)) {
        return null;
      }
      return uri.toString();
    }
    return null;
  }

  static String _languageFrom(Map<String, dynamic> provider, String key) =>
      _languageTag(provider[key]) ?? 'unknown';

  static PlaybackDubbingType _dubbingType(Object? value) {
    final String? text = _text(value)?.toLowerCase();
    return switch (text) {
      'original' ||
      'original audio' ||
      'ja' ||
      'ja-jp' => PlaybackDubbingType.originalAudio,
      'latin' ||
      'latino' ||
      'latin spanish' ||
      'es-419' => PlaybackDubbingType.latinSpanish,
      'castellano' ||
      'castilian' ||
      'es-es' => PlaybackDubbingType.castilianSpanish,
      null || '' || 'unknown' => PlaybackDubbingType.unknown,
      _ => PlaybackDubbingType.other,
    };
  }

  static PlaybackMediaFormat _mediaFormat(String? value, Uri uri) {
    final String format = value?.toLowerCase().trim() ?? '';
    final PlaybackMediaFormat declared = switch (format) {
      'mp4' || 'video/mp4' => PlaybackMediaFormat.mp4,
      'hls' ||
      'm3u8' ||
      'application/vnd.apple.mpegurl' => PlaybackMediaFormat.hls,
      'dash' || 'mpd' || 'application/dash+xml' => PlaybackMediaFormat.dash,
      'webm' || 'video/webm' => PlaybackMediaFormat.webm,
      _ => PlaybackMediaFormat.unknown,
    };
    return DirectMediaHostResolver.formatFor(uri, declared: declared);
  }

  static int _qualityScore(String? value) {
    if (value == null) return 0;
    final RegExpMatch? dimensions = RegExp(
      r'(?:\d{3,4}\s*[x×]\s*)?(\d{3,4})p?',
      caseSensitive: false,
    ).firstMatch(value);
    return int.tryParse(dimensions?.group(1) ?? '') ?? 0;
  }

  static bool _validDirectUri(Uri uri) =>
      DirectMediaHostResolver.isSyntacticallyPublicHttps(uri);

  static String _slug(String input) {
    final String slug = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return (slug.isEmpty ? 'server' : slug).substring(
      0,
      (slug.isEmpty ? 'server' : slug).length.clamp(1, 80),
    );
  }

  static Map<String, dynamic> _decodeObject(String body) {
    final Object? value = jsonDecode(body);
    final Map<String, dynamic>? object = _object(value);
    if (object == null) throw const FormatException('Expected a JSON object.');
    return object;
  }

  static Map<String, dynamic>? _object(Object? value) =>
      value is Map<String, dynamic> ? value : null;

  static List<Object?> _array(Object? value) =>
      value is List<Object?> ? value : const [];

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String text = value.trim();
    return text.isEmpty || text.length > 2048 ? null : text;
  }

  static int? _int(Object? value) =>
      value is int ? value : int.tryParse('$value');

  static int? _positiveInt(Object? value) {
    final int? number = _int(value);
    return number != null && number > 0 && number <= maxEpisodes
        ? number
        : null;
  }

  static double? _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value');

  static String? _title(Object? value) {
    if (value is String) return _text(value);
    final Map<String, dynamic>? titles = _object(value);
    return _text(titles?['english']) ??
        _text(titles?['romaji']) ??
        _text(titles?['native']);
  }

  static String? _languageTag(Object? value) {
    final String? text = _text(value);
    if (text == null) return null;
    final String normalized = text.toLowerCase();
    if (!RegExp(r'^[a-z]{2,3}(?:-[a-z0-9]{2,8})*$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  static bool _validKey(String value) =>
      RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(value);

  static bool _validTitleId(String value) =>
      RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value);
}
