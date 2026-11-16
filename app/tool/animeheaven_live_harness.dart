import 'dart:async';
import 'dart:io';

import 'package:anime_app/app/player/playback_route_session.dart';
import 'package:anime_app/app/player/provider_playback_route.dart';
import 'package:anime_app/app/player/spike_player_module.dart';
import 'package:anime_app/data/player/providers/playback_providers_module.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final PlaybackProvidersModule module = PlaybackProvidersModule.open();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimeHeavenLiveHarness(module: module),
    ),
  );
}

/// Manual Wayland harness for exercising the registered public provider and
/// the same player route used by the Anime detail screen. Not product UI.
final class AnimeHeavenLiveHarness extends StatefulWidget {
  const AnimeHeavenLiveHarness({required this.module, super.key});

  final PlaybackProvidersModule module;

  @override
  State<AnimeHeavenLiveHarness> createState() => _AnimeHeavenLiveHarnessState();
}

final class _AnimeHeavenLiveHarnessState extends State<AnimeHeavenLiveHarness> {
  final PlaybackEpisode _episode = PlaybackEpisode(
    animeId: AnimeId('playback.anilist.21'),
    episodeNumber: 1,
    animeTitles: const <String>['One Piece'],
  );
  PlaybackCancellationToken? _cancellation;
  List<ResolvedPlaybackStream> _streams = const <ResolvedPlaybackStream>[];
  String _message = 'Resolviendo One Piece, episodio 1…';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve(autoOpenFirst: true));
  }

  @override
  void dispose() {
    _cancellation?.cancel();
    widget.module.close();
    super.dispose();
  }

  Future<void> _resolve({bool autoOpenFirst = false}) async {
    _cancellation?.cancel();
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken();
    _cancellation = cancellation;
    setState(() {
      _loading = true;
      _streams = const <ResolvedPlaybackStream>[];
      _message = 'Buscando título, episodio y mirrors públicos…';
    });
    try {
      final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
          await widget.module.manager.resolveCandidates(
            _episode,
            cancellation: cancellation,
          );
      if (!mounted || cancellation.isCancelled) return;
      switch (result) {
        case PlaybackProviderSuccess<List<ResolvedPlaybackStream>>(
          :final value,
        ):
          setState(() {
            _streams = value;
            _message = 'Se validaron ${value.length} alternativas MP4.';
          });
          if (autoOpenFirst && value.isNotEmpty) {
            final String? requestedMirror =
                Platform.environment['KONGROO_ANIMEHEAVEN_MIRROR'];
            final ResolvedPlaybackStream? requested = value
                .where(
                  (ResolvedPlaybackStream item) =>
                      item.serverId == requestedMirror,
                )
                .firstOrNull;
            if (requestedMirror != null && requested == null) {
              stdout.writeln(
                'AnimeHeaven requested mirror is not among validated candidates: '
                '$requestedMirror; available=${value.map((item) => item.serverId).join(',')}',
              );
              setState(
                () => _message = 'El mirror solicitado no está disponible entre las alternativas validadas.',
              );
              return;
            }
            final ResolvedPlaybackStream selected = requested ?? value.first;
            stdout.writeln(
              'AnimeHeaven candidates=${value.map((item) => item.serverId).join(',')} '
              'selected=${selected.serverId}',
            );
            await _open(selected, startPlaying: true);
          }
        case PlaybackProviderEmpty<List<ResolvedPlaybackStream>>():
          setState(() => _message = 'El proveedor no publicó una fuente.');
        case PlaybackProviderFailed<List<ResolvedPlaybackStream>>(
          :final failure,
        ):
          setState(() => _message = 'Falló la resolución: ${failure.kind}.');
        case PlaybackProviderUnsupported<List<ResolvedPlaybackStream>>():
          setState(() => _message = 'La fuente no es compatible.');
      }
    } on Object {
      if (mounted && !cancellation.isCancelled) {
        setState(() => _message = 'La búsqueda live falló.');
      }
    } finally {
      if (mounted && identical(_cancellation, cancellation)) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(
    ResolvedPlaybackStream stream, {
    bool startPlaying = false,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ProviderPlaybackRoute(
          manager: widget.module.manager,
          episode: _episode,
          streams: _streams,
          initialStream: stream,
          // ignore: invalid_use_of_visible_for_testing_member, reason: The manual harness supplies Play without synthetic desktop input.
          moduleLoader: startPlaying
              ? (PlaybackRouteOpenCancellation cancellation) async {
                  final SpikePlayerModule player = await SpikePlayerModule.open(
                    null,
                    sourceProviderManager: widget.module.manager,
                    sourceEpisode: _episode,
                    initialResolvedSource: stream,
                    trustedExternalSources: <Uri>{
                      for (final ResolvedPlaybackStream item in _streams)
                        item.uri,
                    },
                    startupCancellation: cancellation,
                  );
                  await player.coordinator.play();
                  return player;
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AnimeHeaven live — prueba local')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('One Piece · episodio 1'),
          const SizedBox(height: 12),
          Text(_message),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _resolve,
            child: Text(_loading ? 'Resolviendo…' : 'Buscar fuentes públicas'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _streams.length,
              itemBuilder: (BuildContext context, int index) {
                final ResolvedPlaybackStream stream = _streams[index];
                return ListTile(
                  title: Text(stream.serverId),
                  subtitle: const Text(
                    'MP4 progresivo · mirror del mismo encode',
                  ),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => _open(stream),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
