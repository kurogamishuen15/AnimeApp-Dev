import 'dart:async';

import 'anime_identity.dart';
import 'episode_source.dart';
import 'playback_source.dart';

enum PlaybackProviderCapability {
  episodeSources,
  sourceAlternatives,
  resolveServer,
}

enum PlaybackProviderFailureKind {
  unavailable,
  network,
  timeout,
  rateLimited,
  invalidResponse,
  unauthorized,
  unsupported,
  cancelled,
  circuitOpen,
  missingId,
  noEpisodes,
  noSources,
  forbidden,
  challenge,
  ipBlocked,
  policyBlocked,
  iframeDenied,
  geoRestricted,
  drm,
  notFound,
  unsupportedEmbed,
  expired,
  invalidManifest,
  decoderFailure,
  blocked,
  unknown,
}

extension PlaybackProviderFailureKindPolicy on PlaybackProviderFailureKind {
  /// Transient provider/service failures count toward the 3/60 breaker.
  bool get countsTowardCircuit => switch (this) {
    PlaybackProviderFailureKind.unavailable ||
    PlaybackProviderFailureKind.network ||
    PlaybackProviderFailureKind.timeout => true,
    PlaybackProviderFailureKind.rateLimited ||
    PlaybackProviderFailureKind.invalidResponse ||
    PlaybackProviderFailureKind.unauthorized ||
    PlaybackProviderFailureKind.unsupported ||
    PlaybackProviderFailureKind.cancelled ||
    PlaybackProviderFailureKind.circuitOpen ||
    PlaybackProviderFailureKind.missingId ||
    PlaybackProviderFailureKind.noEpisodes ||
    PlaybackProviderFailureKind.noSources ||
    PlaybackProviderFailureKind.forbidden ||
    PlaybackProviderFailureKind.challenge ||
    PlaybackProviderFailureKind.ipBlocked ||
    PlaybackProviderFailureKind.policyBlocked ||
    PlaybackProviderFailureKind.iframeDenied ||
    PlaybackProviderFailureKind.geoRestricted ||
    PlaybackProviderFailureKind.drm ||
    PlaybackProviderFailureKind.notFound ||
    PlaybackProviderFailureKind.unsupportedEmbed ||
    PlaybackProviderFailureKind.expired ||
    PlaybackProviderFailureKind.invalidManifest ||
    PlaybackProviderFailureKind.decoderFailure ||
    PlaybackProviderFailureKind.blocked ||
    PlaybackProviderFailureKind.unknown => false,
  };
}

enum PlaybackHttpStage { catalog, anime, episode, embed, media }

final class PlaybackProviderFailure {
  const PlaybackProviderFailure(
    this.kind, {
    this.retryAfter,
    this.httpStatus,
    this.host,
    this.server,
    this.stage,
    this.contentType,
  });

  final int? httpStatus;
  final String? host;
  final String? server;
  final PlaybackHttpStage? stage;
  final String? contentType;

  final PlaybackProviderFailureKind kind;
  final Duration? retryAfter;

  bool get countsTowardCircuit =>
      kind.countsTowardCircuit ||
      (kind == PlaybackProviderFailureKind.rateLimited && retryAfter == null);
}

sealed class PlaybackProviderResult<T> {
  const PlaybackProviderResult();
}

final class PlaybackProviderSuccess<T> extends PlaybackProviderResult<T> {
  const PlaybackProviderSuccess(this.value);
  final T value;
}

final class PlaybackProviderEmpty<T> extends PlaybackProviderResult<T> {
  const PlaybackProviderEmpty();
}

final class PlaybackProviderUnsupported<T> extends PlaybackProviderResult<T> {
  const PlaybackProviderUnsupported(this.capability);
  final PlaybackProviderCapability capability;
}

final class PlaybackProviderFailed<T> extends PlaybackProviderResult<T> {
  const PlaybackProviderFailed(this.failure);
  final PlaybackProviderFailure failure;
}

/// Cooperative cancellation. Providers must check it before expensive work.
final class PlaybackCancellationToken {
  bool _cancelled = false;
  final Completer<void> _cancelledSignal = Completer<void>();
  final Set<void Function()> _cancelListeners = {};

  bool get isCancelled => _cancelled;
  Future<void> get whenCancelled => _cancelledSignal.future;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancelledSignal.complete();
    final List<void Function()> listeners = List.of(_cancelListeners);
    _cancelListeners.clear();
    for (final void Function() listener in listeners) {
      try {
        listener();
      } on Object {
        // Cancellation must reach remaining listeners even when one callback
        // is faulty; callers observe cancellation through [whenCancelled].
      }
    }
  }

  /// Registers a one-shot callback and returns an unregister function.
  /// Registering after cancellation invokes the callback immediately.
  void Function() addCancelListener(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _cancelListeners.add(listener);
    return () => _cancelListeners.remove(listener);
  }
}

abstract interface class PlaybackSourceProvider {
  PlaybackProviderId get id;
  Set<PlaybackProviderCapability> get capabilities;

  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  });
}

/// Resolves an episode server independently from the anime catalog provider.
///
/// Implementations own HTTP host protocols only; they never discover anime,
/// create a playback engine, or own a native player.
abstract interface class PlaybackVideoHostResolver {
  String get resolverId;

  /// Stable host identity for diagnostics and host-scoped health policy.
  String get hostId;

  bool supports(SourceCandidate candidate);

  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve(
    PlaybackSource source,
    SourceCandidate candidate, {
    required PlaybackCancellationToken cancellation,
  });
}

/// Three-phase provider adapter: identify a source anime, enumerate its
/// episodes, then discover host candidates for one provider episode. The
/// existing manager consumes the final `findSources` bridge, so it remains the
/// only registry and fallback coordinator.
abstract base class EpisodeSourceAdapter implements PlaybackSourceProvider {
  String get adapterVersion => '1.0.0';

  Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime(
    AnimeIdentity identity, {
    required PlaybackCancellationToken cancellation,
  });

  Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes(
    SourceAnimeMatch match, {
    required PlaybackCancellationToken cancellation,
  });

  /// Finds a selected episode. The default scans [listEpisodes], while
  /// adapters with paginated catalogs can override it to stop at the requested
  /// episode instead of fetching every page.
  Future<PlaybackProviderResult<EpisodeRef>> findEpisode(
    SourceAnimeMatch match, {
    required int episodeNumber,
    required PlaybackCancellationToken cancellation,
  }) async {
    if (cancellation.isCancelled) return _episodeCancelled();
    try {
      final PlaybackProviderResult<List<EpisodeRef>> result =
          await listEpisodes(match, cancellation: cancellation);
      return switch (result) {
        PlaybackProviderFailed<List<EpisodeRef>>(:final failure) =>
          PlaybackProviderFailed<EpisodeRef>(failure),
        PlaybackProviderUnsupported<List<EpisodeRef>>(:final capability) =>
          PlaybackProviderUnsupported<EpisodeRef>(capability),
        PlaybackProviderEmpty<List<EpisodeRef>>() =>
          const PlaybackProviderEmpty<EpisodeRef>(),
        PlaybackProviderSuccess<List<EpisodeRef>>(:final value) =>
          _selectEpisode(value, match, episodeNumber),
      };
    } on Object {
      return cancellation.isCancelled
          ? _episodeCancelled()
          : const PlaybackProviderFailed<EpisodeRef>(
              PlaybackProviderFailure(PlaybackProviderFailureKind.unavailable),
            );
    }
  }

  Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources(
    EpisodeRef episode, {
    required PlaybackCancellationToken cancellation,
  });

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode requested, {
    required PlaybackCancellationToken cancellation,
  }) async {
    if (cancellation.isCancelled) return _adapterCancelled();
    try {
      final PlaybackProviderResult<List<SourceAnimeMatch>> searchResult =
          await searchAnime(requested.identity, cancellation: cancellation);
      if (searchResult case PlaybackProviderFailed<List<SourceAnimeMatch>>(
        :final failure,
      )) {
        return PlaybackProviderFailed<List<PlaybackSource>>(failure);
      }
      if (searchResult case PlaybackProviderUnsupported<List<SourceAnimeMatch>>(
        :final capability,
      )) {
        return PlaybackProviderUnsupported<List<PlaybackSource>>(capability);
      }
      if (searchResult is PlaybackProviderEmpty<List<SourceAnimeMatch>>) {
        return const PlaybackProviderEmpty<List<PlaybackSource>>();
      }
      final List<SourceAnimeMatch> matches = switch (searchResult) {
        PlaybackProviderSuccess<List<SourceAnimeMatch>>(:final value) =>
          value
              .where(
                (SourceAnimeMatch match) =>
                    match.providerId == id && match.isConservativeMatch(),
              )
              .toList(growable: false),
        _ => const <SourceAnimeMatch>[],
      };
      if (matches.isEmpty) {
        return const PlaybackProviderEmpty<List<PlaybackSource>>();
      }

      PlaybackProviderFailure? lastFailure;
      PlaybackProviderCapability? unsupported;
      for (final SourceAnimeMatch match in matches) {
        if (cancellation.isCancelled) return _adapterCancelled();
        final PlaybackProviderResult<EpisodeRef> episodeResult =
            await findEpisode(
              match,
              episodeNumber: requested.episodeNumber,
              cancellation: cancellation,
            );
        if (episodeResult case PlaybackProviderFailed<EpisodeRef>(
          :final failure,
        )) {
          lastFailure = failure;
          continue;
        }
        if (episodeResult case PlaybackProviderUnsupported<EpisodeRef>(
          :final capability,
        )) {
          unsupported = capability;
          continue;
        }
        if (episodeResult is PlaybackProviderEmpty<EpisodeRef>) continue;
        final EpisodeRef episode =
            (episodeResult as PlaybackProviderSuccess<EpisodeRef>).value;
        if (episode.providerId != id ||
            episode.sourceAnimeId != match.sourceAnimeId ||
            episode.episodeNumber != requested.episodeNumber) {
          lastFailure = const PlaybackProviderFailure(
            PlaybackProviderFailureKind.invalidResponse,
          );
          continue;
        }
        if (cancellation.isCancelled) return _adapterCancelled();
        final PlaybackProviderResult<List<PlaybackSource>> sourceResult =
            await findEpisodeSources(episode, cancellation: cancellation);
        if (sourceResult case PlaybackProviderSuccess<List<PlaybackSource>>(
          :final value,
        )) {
          final List<PlaybackSource> valid = value
              .where(
                (PlaybackSource source) =>
                    source.providerId == id &&
                    source.episode.requestKey == requested.requestKey,
              )
              .toList(growable: false);
          if (valid.isNotEmpty) {
            return PlaybackProviderSuccess<List<PlaybackSource>>(
              List.unmodifiable(valid),
            );
          }
          if (value.isNotEmpty) {
            lastFailure = const PlaybackProviderFailure(
              PlaybackProviderFailureKind.invalidResponse,
            );
          }
        } else if (sourceResult
            case PlaybackProviderFailed<List<PlaybackSource>>(:final failure)) {
          lastFailure = failure;
        } else if (sourceResult
            case PlaybackProviderUnsupported<List<PlaybackSource>>(
              :final capability,
            )) {
          unsupported = capability;
        }
      }
      if (lastFailure != null) {
        return PlaybackProviderFailed<List<PlaybackSource>>(lastFailure);
      }
      if (unsupported != null) {
        return PlaybackProviderUnsupported<List<PlaybackSource>>(unsupported);
      }
      return const PlaybackProviderEmpty<List<PlaybackSource>>();
    } on Object {
      return cancellation.isCancelled
          ? _adapterCancelled()
          : const PlaybackProviderFailed<List<PlaybackSource>>(
              PlaybackProviderFailure(PlaybackProviderFailureKind.unavailable),
            );
    }
  }

  PlaybackProviderFailed<List<PlaybackSource>> _adapterCancelled() =>
      const PlaybackProviderFailed<List<PlaybackSource>>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );

  PlaybackProviderFailed<EpisodeRef> _episodeCancelled() =>
      const PlaybackProviderFailed<EpisodeRef>(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );

  PlaybackProviderResult<EpisodeRef> _selectEpisode(
    List<EpisodeRef> episodes,
    SourceAnimeMatch match,
    int episodeNumber,
  ) {
    for (final EpisodeRef episode in episodes) {
      if (episode.providerId == id &&
          episode.sourceAnimeId == match.sourceAnimeId &&
          episode.episodeNumber == episodeNumber) {
        return PlaybackProviderSuccess<EpisodeRef>(episode);
      }
    }
    return const PlaybackProviderEmpty<EpisodeRef>();
  }
}
