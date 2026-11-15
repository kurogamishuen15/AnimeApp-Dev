import '../providers/playback_source.dart';
import 'skip_segment.dart';

final class MyAnimeListAnimeId {
  factory MyAnimeListAnimeId(int value) {
    if (value < 1) throw ArgumentError.value(value, 'value');
    return MyAnimeListAnimeId._(value);
  }

  const MyAnimeListAnimeId._(this.value);
  final int value;
}

enum SkipCatalogFailureKind {
  network,
  rateLimited,
  server,
  malformedResponse,
  cache,
}

sealed class SkipCatalogResult {
  const SkipCatalogResult();
}

final class SkipCatalogSuccess extends SkipCatalogResult {
  const SkipCatalogSuccess(this.segments);
  final List<SkipSegment> segments;
}

final class SkipCatalogUnavailable extends SkipCatalogResult {
  const SkipCatalogUnavailable(this.reason);
  final String reason;
}

final class SkipCatalogFailure extends SkipCatalogResult {
  const SkipCatalogFailure(this.kind);
  final SkipCatalogFailureKind kind;
}

/// Source contract for episode-specific opening/ending skip segments.
abstract interface class SkipSegmentCatalog {
  Future<SkipCatalogResult> lookup({
    required PlaybackEpisode episode,
    required MyAnimeListAnimeId malAnimeId,
  });
}
