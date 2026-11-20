import 'dart:async';

import '../../../../domain/player/providers/playback_provider_contract.dart';
import '../../../../domain/player/providers/playback_source.dart';

enum MockPlaybackScenario {
  valid,
  alternatives,
  unavailableSource,
  timeout,
  empty,
  providerError,
  forbidden,
  malformed,
  wrongEpisode,
  malformedResolution,
}

/// Deterministic provider fixture. It performs no HTTP or filesystem access.
final class MockPlaybackProvider
    implements PlaybackSourceProvider, PlaybackVideoHostResolver {
  MockPlaybackProvider({
    required this.id,
    this.scenario = MockPlaybackScenario.valid,
    this.requestGate,
    this.resolveGate,
    this.requestStarted,
    this.requestCompleted,
    Set<String> unavailableServerIds = const {},
    Map<String, Uri> serverEndpoints = const {},
    Set<PlaybackProviderCapability>? capabilities,
  }) : unavailableServerIds = Set.unmodifiable(unavailableServerIds),
       serverEndpoints = Map.unmodifiable(serverEndpoints),
       capabilitiesOverride = capabilities == null
           ? null
           : Set.unmodifiable(capabilities);

  @override
  final PlaybackProviderId id;
  MockPlaybackScenario scenario;
  Completer<void>? requestGate;
  Completer<void>? resolveGate;
  Completer<void>? requestStarted;
  Completer<void>? requestCompleted;
  final Set<String> unavailableServerIds;
  final Map<String, Uri> serverEndpoints;
  final Set<PlaybackProviderCapability>? capabilitiesOverride;
  int findCalls = 0;
  int resolveCalls = 0;
  final List<String> attemptedServers = [];

  @override
  Set<PlaybackProviderCapability> get capabilities =>
      capabilitiesOverride ??
      const {
        PlaybackProviderCapability.episodeSources,
        PlaybackProviderCapability.sourceAlternatives,
      };

  @override
  String get resolverId => 'mock-${id.value}';

  @override
  String get hostId => id.value;

  @override
  bool supports(SourceCandidate server) =>
      server.endpoint.scheme == 'file' ||
      server.endpoint.host == '${id.value}.mock.invalid';

  @override
  Future<PlaybackProviderResult<List<PlaybackSource>>> findSources(
    PlaybackEpisode episode, {
    required PlaybackCancellationToken cancellation,
  }) async {
    findCalls++;
    if (requestStarted case final Completer<void> started
        when !started.isCompleted) {
      started.complete();
    }
    await requestGate?.future;
    try {
      if (cancellation.isCancelled) {
        return const PlaybackProviderFailed(
          PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
        );
      }
      switch (scenario) {
        case MockPlaybackScenario.timeout:
          return const PlaybackProviderFailed(
            PlaybackProviderFailure(PlaybackProviderFailureKind.timeout),
          );
        case MockPlaybackScenario.unavailableSource:
          return PlaybackProviderSuccess(List.unmodifiable(_sources(episode)));
        case MockPlaybackScenario.providerError:
          return const PlaybackProviderFailed(
            PlaybackProviderFailure(PlaybackProviderFailureKind.network),
          );
        case MockPlaybackScenario.forbidden:
          return const PlaybackProviderFailed(
            PlaybackProviderFailure(
              PlaybackProviderFailureKind.forbidden,
              httpStatus: 403,
            ),
          );
        case MockPlaybackScenario.empty:
          return const PlaybackProviderEmpty();
        case MockPlaybackScenario.malformed:
          return PlaybackProviderSuccess([
            _source(
              'wrong-provider-source',
              PlaybackProviderId('wrong-provider'),
              episode: episode,
              servers: [_server('malformed-server')],
            ),
          ]);
        case MockPlaybackScenario.wrongEpisode:
          return PlaybackProviderSuccess(
            List.unmodifiable(
              _sources(
                PlaybackEpisode(
                  animeId: episode.animeId,
                  episodeNumber: episode.episodeNumber + 1,
                ),
              ),
            ),
          );
        case MockPlaybackScenario.malformedResolution:
          return PlaybackProviderSuccess(List.unmodifiable(_sources(episode)));
        case MockPlaybackScenario.valid:
        case MockPlaybackScenario.alternatives:
          return PlaybackProviderSuccess(List.unmodifiable(_sources(episode)));
      }
    } finally {
      if (requestCompleted case final Completer<void> completed
          when !completed.isCompleted) {
        completed.complete();
      }
    }
  }

  @override
  Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve(
    PlaybackSource source,
    SourceCandidate server, {
    required PlaybackCancellationToken cancellation,
  }) async {
    resolveCalls++;
    attemptedServers.add(server.id);
    await resolveGate?.future;
    if (cancellation.isCancelled) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.cancelled),
      );
    }
    if (scenario == MockPlaybackScenario.unavailableSource ||
        unavailableServerIds.contains(server.id)) {
      return const PlaybackProviderFailed(
        PlaybackProviderFailure(PlaybackProviderFailureKind.unavailable),
      );
    }
    return PlaybackProviderSuccess(
      ResolvedPlaybackStream(
        providerId: id,
        sourceId: scenario == MockPlaybackScenario.malformedResolution
            ? '${source.id}-unexpected'
            : source.id,
        serverId: server.id,
        uri: server.endpoint,
      ),
    );
  }

  List<PlaybackSource> _sources(PlaybackEpisode episode) {
    if (scenario == MockPlaybackScenario.alternatives) {
      return [
        _source(
          'source-japanese-1080p',
          id,
          episode: episode,
          language: 'ja',
          quality: '1080p',
          priority: 20,
          servers: [
            _server('primary-server', priority: 20),
            _server('backup-server', priority: 10),
          ],
        ),
        _source(
          'source-english-720p',
          id,
          episode: episode,
          language: 'en',
          quality: '720p',
          priority: 10,
          servers: [_server('english-server')],
        ),
      ];
    }
    return [
      _source(
        'source-default',
        id,
        episode: episode,
        servers: [_server('default-server')],
      ),
    ];
  }

  PlaybackSource _source(
    String sourceId,
    PlaybackProviderId providerId, {
    required PlaybackEpisode episode,
    String language = 'en',
    String quality = '720p',
    int priority = 0,
    required Iterable<PlaybackServer> servers,
  }) => PlaybackSource(
    id: sourceId,
    providerId: providerId,
    episode: episode,
    language: language,
    quality: quality,
    priority: priority,
    servers: servers,
  );

  PlaybackServer _server(String serverId, {int priority = 0}) => PlaybackServer(
    id: serverId,
    endpoint:
        serverEndpoints[serverId] ??
        Uri.https('${id.value}.mock.invalid', '/stream/$serverId'),
    priority: priority,
  );
}
