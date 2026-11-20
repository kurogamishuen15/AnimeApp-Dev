import '../../../../domain/player/providers/playback_provider_contract.dart';
import 'public_playback_http.dart';

/// Shared helpers for every `EpisodeSourceAdapter` implementation.
///
/// The adapters previously carried three identical private helpers
/// (`_read`, `_check`, `_contractTitle`); they now delegate here so the
/// failure mapping and the conservative title normalization have exactly
/// one definition. Behavior is unchanged except where noted: MegaPlay used
/// to let `ArgumentError` escape to the adapter's catch-all (`unavailable`)
/// and now maps it to `invalidResponse`, the semantically correct
/// classification for malformed payloads (both are non-transient).
abstract final class EpisodeSourceSupport {
  /// Cancellation guard. Throws the transport's `cancelled` failure so the
  /// provider result maps to the shared cancellation kind.
  static void check(PlaybackCancellationToken cancellation) {
    if (cancellation.isCancelled) {
      throw const PublicPlaybackFailure(PlaybackProviderFailureKind.cancelled);
    }
  }

  /// Conservative contract-title normalization (lowercase, collapsed
  /// whitespace). Matching stays strict: an adapter may only accept a
  /// candidate whose normalized title equals one of the requested titles.
  static String contractTitle(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Wraps a provider load into a result:
  /// `null` → [PlaybackProviderEmpty], transport failures → their own
  /// result, malformed payloads (`FormatException`, `ArgumentError`) →
  /// `invalidResponse`. Cancellation surfaces through the transport failure.
  static Future<PlaybackProviderResult<T>> read<T>(
    Future<T?> Function() load,
  ) async {
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
