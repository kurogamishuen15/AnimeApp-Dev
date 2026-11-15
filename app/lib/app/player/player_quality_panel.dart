import 'package:material_ui/material_ui.dart';

import '../../domain/player/video_track_info.dart';

/// Presents only video tracks reported for the current source by the engine.
/// A single track describes a fixed source; it is not an adaptive ladder.
final class PlayerQualityPanel extends StatelessWidget {
  const PlayerQualityPanel({
    required this.tracks,
    required this.selectedId,
    required this.generation,
    required this.mediaContextRevision,
    required this.onSelected,
    super.key,
  });

  final List<VideoTrackInfo> tracks;
  final String selectedId;
  final int generation;
  final int mediaContextRevision;
  final void Function(String id, int generation, int mediaContextRevision)
  onSelected;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const IconButton(
        key: ValueKey('player-quality'),
        tooltip: 'Calidad no informada por la fuente',
        onPressed: null,
        icon: Icon(Icons.high_quality),
      );
    }
    final bool fixed = tracks.length == 1;
    final VideoTrackInfo? selected = tracks.cast<VideoTrackInfo?>().firstWhere(
      (track) => track?.id == selectedId,
      orElse: () => null,
    );
    return PopupMenuButton<(String, int, int)>(
      key: const ValueKey('player-quality'),
      tooltip: fixed
          ? 'Calidad fija · ${tracks.first.label}'
          : 'Calidad · ${selected?.label ?? "Automático"}',
      onSelected: (selection) =>
          onSelected(selection.$1, selection.$2, selection.$3),
      itemBuilder: (_) => [
        if (fixed)
          PopupMenuItem<(String, int, int)>(
            enabled: false,
            child: Text('Calidad fija · ${tracks.first.label}'),
          ),
        if (!fixed)
          CheckedPopupMenuItem<(String, int, int)>(
            key: const ValueKey('video-track-auto'),
            checked: selectedId == 'auto',
            value: ('auto', generation, mediaContextRevision),
            child: const Text('Automático · selección del motor'),
          ),
        for (final VideoTrackInfo track in tracks)
          CheckedPopupMenuItem<(String, int, int)>(
            key: ValueKey('video-track-${track.id}'),
            enabled: !fixed,
            checked: track.id == selectedId,
            value: (track.id, generation, mediaContextRevision),
            child: Text(track.label),
          ),
      ],
      icon: const Icon(Icons.high_quality),
    );
  }
}
