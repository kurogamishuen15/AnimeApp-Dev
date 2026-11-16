import 'dart:io';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';

/// Normalizes an already-public, direct media URI without owning transport or
/// playback. Host reachability and decoding are verified by the playback path.
final class DirectMediaHostResolver implements PlaybackVideoHostResolver {
  DirectMediaHostResolver({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const String stableHostId = 'direct-media';

  final DateTime Function() _clock;

  @override
  String get hostId => stableHostId;

  @override
  String get resolverId => 'direct-media';

  @override
  bool supports(SourceCandidate candidate) =>
      candidate.hostId == stableHostId &&
      candidate.kind == PlaybackCandidateKind.media &&
      _isSyntacticallyPublicHttps(candidate.endpoint) &&
      _formatFor(candidate.endpoint) != PlaybackMediaFormat.unknown;

  @override
  Future<PlaybackProviderResult<PlayableSource>> resolve(
    PlaybackSource source,
    SourceCandidate candidate, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (cancellation.isCancelled) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );
    }
    if (!supports(candidate)) {
      return const PlaybackProviderUnsupported(
        PlaybackProviderCapability.resolveServer,
      );
    }
    if (candidate.expiresAt case final DateTime expiry
        when !expiry.isAfter(_clock())) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.expired),
      );
    }

    return PlaybackProviderSuccess(
      PlayableSource(
        providerId: source.providerId,
        sourceId: source.id,
        serverId: candidate.id,
        uri: candidate.endpoint,
        format: _formatFor(candidate.endpoint),
        expiresAt: candidate.expiresAt,
        provenance: candidate.provenance,
        httpHeaders: candidate.requestHeaders,
      ),
    );
  }

  static PlaybackMediaFormat _formatFor(Uri uri) {
    final String path = uri.path.toLowerCase();
    if (path.endsWith('.mp4')) return PlaybackMediaFormat.mp4;
    if (path.endsWith('.m3u8')) return PlaybackMediaFormat.hls;
    if (path.endsWith('.mpd')) return PlaybackMediaFormat.dash;
    return PlaybackMediaFormat.unknown;
  }

  /// Rejects obvious local/private destinations before handing a source to
  /// libmpv. DNS names are not resolved here; host-specific network adapters
  /// must validate redirects and resolved addresses at their own boundary.
  static bool _isSyntacticallyPublicHttps(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.port != 443) {
      return false;
    }

    final String host = uri.host.toLowerCase();
    const Set<String> localSuffixes = {
      'localhost',
      'local',
      'internal',
      'test',
      'example',
      'invalid',
      'onion',
    };
    if (localSuffixes.any(
      (String suffix) => host == suffix || host.endsWith('.$suffix'),
    )) {
      return false;
    }

    final InternetAddress? address = InternetAddress.tryParse(host);
    if (address != null) return _isGloballyRoutableAddress(address);

    if (host.length > 253 ||
        !host.contains('.') ||
        host.startsWith('.') ||
        host.endsWith('.') ||
        host.contains('_')) {
      return false;
    }
    final List<String> labels = host.split('.');
    if (labels.any(
      (String label) =>
          label.length > 63 ||
          !RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$').hasMatch(label),
    )) {
      return false;
    }
    // Reject alternate numeric IPv4 spellings such as 127.1 and 2130706433.
    if (labels.every(
      (String label) => RegExp(r'^(?:0x[0-9a-f]+|[0-9]+)$').hasMatch(label),
    )) {
      return false;
    }
    return true;
  }

  static bool _isGloballyRoutableAddress(InternetAddress address) {
    final List<int> bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv4) {
      return _isGloballyRoutableIpv4(bytes);
    }
    if (address.type != InternetAddressType.IPv6 || bytes.length != 16) {
      return false;
    }

    final bool mappedIpv4 =
        bytes.take(10).every((int byte) => byte == 0) &&
        bytes[10] == 0xff &&
        bytes[11] == 0xff;
    if (mappedIpv4) return _isGloballyRoutableIpv4(bytes.sublist(12));

    // Only accept global-unicast 2000::/3. Exclude documentation, 6to4 and
    // Teredo prefixes because they can encode non-public IPv4 destinations.
    final bool globalUnicast = (bytes[0] & 0xe0) == 0x20;
    final bool documentation =
        bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x0d &&
        bytes[3] == 0xb8;
    final bool sixToFour = bytes[0] == 0x20 && bytes[1] == 0x02;
    final bool teredo =
        bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x00 &&
        bytes[3] == 0x00;
    return globalUnicast && !documentation && !sixToFour && !teredo;
  }

  static bool _isGloballyRoutableIpv4(List<int> bytes) {
    if (bytes.length != 4) return false;
    final int first = bytes[0];
    final int second = bytes[1];
    final int third = bytes[2];
    if (first == 0 ||
        first == 10 ||
        first == 127 ||
        first >= 224 ||
        (first == 100 && second >= 64 && second <= 127) ||
        (first == 169 && second == 254) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 0) ||
        (first == 192 && second == 168) ||
        (first == 198 && (second == 18 || second == 19)) ||
        (first == 198 && second == 51 && third == 100) ||
        (first == 203 && second == 0 && third == 113)) {
      return false;
    }
    return true;
  }
}
