import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../application/player/player_demo_session.dart';
import '../../application/player/spike_player_coordinator.dart';

final class PlayerDemoPanel extends StatefulWidget {
  const PlayerDemoPanel({
    required this.catalog,
    required this.coordinator,
    super.key,
  });

  final PlayerDemoCatalog catalog;
  final SpikePlayerCoordinator coordinator;

  @override
  State<PlayerDemoPanel> createState() => _PlayerDemoPanelState();
}

final class _PlayerDemoPanelState extends State<PlayerDemoPanel> {
  late final PlayerDemoSession _session = PlayerDemoSession(
    widget.catalog,
    widget.coordinator,
  );
  static const _servers = ['Archivo local', 'Demo A', 'Demo B', 'Demo C'];

  Future<void> _select(int episode, int server) async {
    final operation = _session.select(episode, server);
    setState(() {});
    await operation;
    if (mounted) setState(() {});
  }

  Future<void> _openPicker({required bool servers}) async {
    final selection = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          servers
              ? 'Servidores · ${widget.catalog.title(_session.episode)}'
              : 'Episodios',
        ),
        scrollable: true,
        content: SizedBox(
          width: 410,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (servers)
                for (int index = 0; index < _servers.length; index++)
                  ListTile(
                    key: ValueKey('demo-server-$index'),
                    leading: Icon(
                      index == 0 ? Icons.folder_open : Icons.dns_outlined,
                    ),
                    title: Text(_servers[index]),
                    subtitle: Text(
                      index == 3
                          ? 'HTTP · Simula error 503'
                          : index == 0
                          ? 'Copia local'
                          : 'HTTP · Espejo del mismo archivo',
                    ),
                    selected: index == _session.server,
                    trailing: index == _session.server
                        ? const Icon(Icons.check_circle_outline)
                        : null,
                    onTap: () => Navigator.pop(dialog, index),
                  )
              else
                for (int slot = 1; slot <= 2; slot++)
                  ListTile(
                    key: ValueKey('demo-episode-$slot'),
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(widget.catalog.title(slot)),
                    selected: slot == _session.episode,
                    trailing: slot == _session.episode
                        ? const Icon(Icons.check_circle_outline)
                        : null,
                    onTap: () => Navigator.pop(dialog, slot),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (!mounted || selection == null) return;
    await (servers
        ? _select(_session.episode, selection)
        : _select(selection, 0));
  }

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(widget.catalog.title(_session.episode)),
      IconButton(
        key: const ValueKey('episode-previous'),
        tooltip: 'Episodio anterior',
        onPressed: _session.busy || _session.episode == 1
            ? null
            : () => unawaited(_select(1, 0)),
        icon: const Icon(Icons.skip_previous),
      ),
      IconButton(
        key: const ValueKey('episode-next'),
        tooltip: 'Episodio siguiente',
        onPressed: _session.busy || _session.episode == 2
            ? null
            : () => unawaited(_select(2, 0)),
        icon: const Icon(Icons.skip_next),
      ),
      OutlinedButton.icon(
        key: const ValueKey('player-episodes'),
        onPressed: _session.busy
            ? null
            : () => unawaited(_openPicker(servers: false)),
        icon: const Icon(Icons.video_library_outlined),
        label: const Text('Episodios'),
      ),
      OutlinedButton.icon(
        key: const ValueKey('player-servers'),
        onPressed: _session.busy
            ? null
            : () => unawaited(_openPicker(servers: true)),
        icon: const Icon(Icons.dns_outlined),
        label: const Text('Servidores'),
      ),
      Text(
        _session.server == null
            ? 'Sin fuente activa'
            : _servers[_session.server!],
      ),
      if (_session.busy) const Text('Cambiando fuente…'),
      if (_session.message case final String message)
        Text(message, key: const ValueKey('demo-result')),
    ],
  );
}
