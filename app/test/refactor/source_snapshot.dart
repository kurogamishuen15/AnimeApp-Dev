import 'package:anime_app/domain/player/providers/playback_source.dart';

Map<String, Object?> snapshotSource(PlaybackSource s) => {
  'id': s.id,
  'provider': s.providerId.value,
  'episodeKey': s.episode.requestKey,
  'language': s.language,
  'quality': s.quality,
  'priority': s.priority,
  'audio': s.audioLanguage,
  'subLanguage': s.subtitleLanguage,
  'dubbingType': s.dubbingType.name,
  'announced': s.providerAnnouncedLanguage,
  'label': s.displayName,
  'subtitles': s.subtitles
      .map(
        (t) => {
          'id': t.id,
          'uri': t.uri.toString(),
          'label': t.label,
          'language': t.language,
          'default': t.isDefault,
        },
      )
      .toList(),
  'servers': s.servers
      .map(
        (c) => {
          'id': c.id,
          'endpoint': c.endpoint.toString(),
          'hostId': c.hostId,
          'priority': c.priority,
          'kind': c.kind.name,
          'language': c.declaredLanguage,
          'format': c.mediaFormat.name,
          'quality': c.quality,
          'displayName': c.displayName,
          'availability': c.availability.name,
          'episodeId': c.sourceEpisodeId,
          'expiresAt': c.expiresAt?.toIso8601String(),
          'provenance': c.provenance,
          'headers': c.requestHeaders.values,
        },
      )
      .toList(),
};
