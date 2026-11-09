/// Stable AnimeApp-owned identity, independent of catalog or stream provider.
final class ContentId {
  ContentId(String value) : value = _normalize(value, 'contentId');
  final String value;
  @override
  bool operator ==(Object other) => other is ContentId && value == other.value;
  @override
  int get hashCode => Object.hash(ContentId, value);
}

final class EpisodeId {
  EpisodeId(String value) : value = _normalize(value, 'episodeId');
  final String value;
  @override
  bool operator ==(Object other) => other is EpisodeId && value == other.value;
  @override
  int get hashCode => Object.hash(EpisodeId, value);
}

final class ProgressKey {
  const ProgressKey({required this.contentId, required this.episodeId});
  final ContentId contentId;
  final EpisodeId episodeId;
  String get storageKey =>
      '${contentId.value.length}:${contentId.value}${episodeId.value.length}:${episodeId.value}';
  @override
  bool operator ==(Object other) =>
      other is ProgressKey &&
      contentId == other.contentId &&
      episodeId == other.episodeId;
  @override
  int get hashCode => Object.hash(contentId, episodeId);
}

String _normalize(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
  return normalized;
}
