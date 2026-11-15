import 'spike_player_coordinator.dart';

/// Launcher supplied loopback origins and project-local fixtures.
final class PlayerDemoCatalog {
  PlayerDemoCatalog(
    this.directory,
    Iterable<int> ports, {
    this.realMedia = false,
  }) : ports = List.unmodifiable(ports) {
    if (this.ports.length != 3 ||
        this.ports.toSet().length != 3 ||
        this.ports.any((port) => port < 1024 || port > 65535)) {
      throw ArgumentError('Expected three distinct demo server ports.');
    }
  }
  final String directory;
  final bool realMedia;

  String title(int slot) =>
      realMedia ? 'Morevna · Episodio ${slot + 2}' : 'Episodio de prueba $slot';
  final List<int> ports;

  Uri source(int episode, int server) => server == 0
      ? Uri.file('$directory/episode-$episode.mkv')
      : Uri.http('127.0.0.1:${ports[server - 1]}', '/episode-$episode.mkv');

  Set<Uri> get loopbackSources => {
    for (final int episode in [1, 2])
      for (final int server in [1, 2, 3]) source(episode, server),
  };
}

/// Keeps selection and episode checkpoints outside the widget tree.
final class PlayerDemoSession {
  PlayerDemoSession(this.catalog, this.coordinator);

  final PlayerDemoCatalog catalog;
  final SpikePlayerCoordinator coordinator;
  final Map<int, Duration> _positions = {};
  int episode = 1;
  int? server = 0;
  bool busy = false;
  String? message;

  Future<void> select(int slot, int endpoint) async {
    if (busy || (slot == episode && endpoint == server)) return;
    final before = coordinator.state;
    busy = true;
    message = null;
    try {
      final result = await coordinator.switchSource(
        catalog.source(slot, endpoint),
        referencePosition: slot == episode
            ? before.observedPosition
            : _positions[slot] ?? Duration.zero,
        rollbackPosition: before.observedPosition,
        preserveTracks: slot == episode,
      );
      if (result.succeeded) {
        _positions[episode] = before.observedPosition;
        episode = slot;
        server = endpoint;
        message = 'Fuente preparada';
      } else {
        if (result.selectedSource == null) server = null;
        message = result.error;
      }
    } on Object {
      message = 'No se pudo cambiar el medio.';
    } finally {
      busy = false;
    }
  }
}
