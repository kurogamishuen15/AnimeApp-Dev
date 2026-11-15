import 'package:material_ui/material_ui.dart';

import '../../domain/player/audio_track_info.dart';

final class AudioTrackSelector extends StatelessWidget {
  const AudioTrackSelector({
    required this.tracks,
    required this.selectedId,
    required this.generation,
    required this.mediaContextRevision,
    required this.onSelected,
    super.key,
  });

  final List<AudioTrackInfo> tracks;
  final String selectedId;
  final int generation;
  final int mediaContextRevision;
  final void Function(String id, int generation, int mediaContextRevision)
  onSelected;

  @override
  Widget build(BuildContext context) {
    if (!tracks.any((track) => track.id != 'auto' && track.id != 'no')) {
      return const IconButton(
        tooltip: 'Audio sin pistas disponibles',
        onPressed: null,
        icon: Icon(Icons.headphones),
      );
    }
    final Map<String, AudioTrackInfo> entries = {
      'auto': const AudioTrackInfo(id: 'auto'),
      'no': const AudioTrackInfo(id: 'no'),
      for (final AudioTrackInfo track in tracks) track.id: track,
    };
    return PopupMenuButton<(String, int, int)>(
      key: const ValueKey('player-audio'),
      tooltip: 'Audio · ${entries[selectedId]?.label ?? "Automático"}',
      onSelected: (selection) =>
          onSelected(selection.$1, selection.$2, selection.$3),
      itemBuilder: (_) => [
        for (final AudioTrackInfo track in entries.values)
          CheckedPopupMenuItem<(String, int, int)>(
            key: ValueKey('audio-track-${track.id}'),
            checked: track.id == selectedId,
            value: (track.id, generation, mediaContextRevision),
            child: Text(track.label),
          ),
      ],
      icon: const Icon(Icons.headphones),
    );
  }
}
