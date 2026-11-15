import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../application/player/external_subtitles/external_subtitle_service.dart';
import '../../application/player/playback_spike_contract.dart';
import '../../application/player/spike_player_coordinator.dart';
import '../../domain/player/audio_track_info.dart';
import '../../domain/player/subtitles/subtitle_style.dart';
import 'external_subtitle_search_panel.dart';

const Duration spikeSubtitleDelayStep = Duration(milliseconds: 250);

/// Session preferences survive dismissing the subtitle dialog.
final class PlayerSubtitlePreferences {
  SubtitleStyle style = SubtitleStyle();
  Duration delay = Duration.zero;
}

final class PlayerSubtitlePanel extends StatefulWidget {
  const PlayerSubtitlePanel({
    required this.coordinator,
    required this.preferences,
    this.externalService,
    super.key,
  });

  final SpikePlayerCoordinator coordinator;
  final PlayerSubtitlePreferences preferences;
  final ExternalSubtitleService? externalService;

  @override
  State<PlayerSubtitlePanel> createState() => _PlayerSubtitlePanelState();
}

final class _PlayerSubtitlePanelState extends State<PlayerSubtitlePanel> {
  SubtitleStyle get _subtitleStyle => widget.preferences.style;
  set _subtitleStyle(SubtitleStyle value) => widget.preferences.style = value;
  Duration get _subtitleDelay => widget.preferences.delay;
  set _subtitleDelay(Duration value) => widget.preferences.delay = value;
  String? _error;
  bool _applying = false;

  Future<void> _command(Future<void> Function() operation) async {
    try {
      await operation();
      if (mounted) setState(() => _error = null);
    } on Object {
      if (mounted) setState(() => _error = 'No se pudo aplicar el cambio.');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Subtítulos'),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pista y estilo'),
          const SizedBox(height: 12),
          StreamBuilder<PlaybackSessionSnapshot>(
            stream: widget.coordinator.states,
            initialData: widget.coordinator.state,
            builder: (_, state) =>
                _subtitleControls(state.data ?? widget.coordinator.state),
          ),
          if (_error case final String error) Text(error),
          if (widget.externalService
              case final ExternalSubtitleService service) ...[
            const Divider(height: 30),
            const Text('OpenSubtitles'),
            ExternalSubtitleSearchPanel(service: service),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cerrar'),
      ),
    ],
  );

  Future<void> _applyPreference(
    Future<void> Function() operation,
    VoidCallback commit,
  ) async {
    if (_applying) return;
    setState(() => _applying = true);
    try {
      await operation();
      commit();
      if (mounted) setState(() => _error = null);
    } on Object {
      if (mounted) setState(() => _error = 'No se pudo aplicar el ajuste.');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _applySubtitleStyle(SubtitleStyle style) => unawaited(
    _applyPreference(
      () => widget.coordinator.applySubtitleStyle(style),
      () => _subtitleStyle = style,
    ),
  );

  void _adjustSubtitleDelay(Duration delta) {
    final Duration next = _subtitleDelay + delta;
    if (next.abs() > const Duration(seconds: 30)) return;
    unawaited(
      _applyPreference(
        () => widget.coordinator.setSubtitleDelay(next),
        () => _subtitleDelay = next,
      ),
    );
  }

  Widget _subtitleControls(PlaybackSessionSnapshot snapshot) {
    final double delaySeconds = _subtitleDelay.inMilliseconds / 1000;
    final String delayLabel =
        'Subtitle delay ${delaySeconds >= 0 ? '+' : ''}${delaySeconds.toStringAsFixed(2)}s';
    return AbsorbPointer(
      absorbing: _applying,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          DropdownButton<String>(
            key: const ValueKey<String>('subtitle-track-selector'),
            value:
                snapshot.subtitleTracks.any(
                  (track) => track.id == snapshot.selectedSubtitleId,
                )
                ? snapshot.selectedSubtitleId
                : null,
            hint: const Text('Subtitles'),
            items: [
              for (final track in snapshot.subtitleTracks)
                DropdownMenuItem<String>(
                  value: track.id,
                  child: Text(
                    track.language == null
                        ? track.label
                        : playbackLanguageLabel(track.language),
                  ),
                ),
            ],
            onChanged: (String? id) {
              if (id != null) {
                unawaited(
                  _command(() => widget.coordinator.selectSubtitleTrack(id)),
                );
              }
            },
          ),
          DropdownButton<double>(
            key: const ValueKey<String>('subtitle-size-selector'),
            value: _subtitleStyle.fontSize,
            items: const [32.0, 38.0, 44.0]
                .map(
                  (double size) => DropdownMenuItem<double>(
                    value: size,
                    child: Text('Size ${size.round()}'),
                  ),
                )
                .toList(),
            onChanged: (double? size) {
              if (size != null) {
                _applySubtitleStyle(_subtitleStyle.copyWith(fontSize: size));
              }
            },
          ),
          DropdownButton<String>(
            key: const ValueKey<String>('subtitle-font-selector'),
            value: _subtitleStyle.fontFamily,
            items: const ['sans-serif', 'serif', 'monospace']
                .map(
                  (String font) =>
                      DropdownMenuItem<String>(value: font, child: Text(font)),
                )
                .toList(),
            onChanged: (String? font) {
              if (font != null) {
                _applySubtitleStyle(_subtitleStyle.copyWith(fontFamily: font));
              }
            },
          ),
          DropdownButton<String>(
            key: const ValueKey<String>('subtitle-color-selector'),
            value: _subtitleStyle.color,
            items:
                const {
                      '#FFFFFFFF': 'White',
                      '#FFFFFF00': 'Yellow',
                      '#FFFF8080': 'Pink',
                    }.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
            onChanged: (String? color) {
              if (color != null) {
                _applySubtitleStyle(_subtitleStyle.copyWith(color: color));
              }
            },
          ),
          DropdownButton<double>(
            key: const ValueKey<String>('subtitle-outline-selector'),
            value: _subtitleStyle.outlineSize,
            items: const [0.0, 1.65, 3.0]
                .map(
                  (double size) => DropdownMenuItem<double>(
                    value: size,
                    child: Text(
                      'Outline ${size.toStringAsFixed(size == 1.65 ? 2 : 0)}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (double? size) {
              if (size != null) {
                _applySubtitleStyle(_subtitleStyle.copyWith(outlineSize: size));
              }
            },
          ),
          DropdownButton<String>(
            key: const ValueKey<String>('subtitle-outline-color-selector'),
            value: _subtitleStyle.outlineColor,
            items:
                const {
                      '#FF000000': 'Black outline',
                      '#FFFFFFFF': 'White outline',
                    }.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
            onChanged: (String? color) {
              if (color != null) {
                _applySubtitleStyle(
                  _subtitleStyle.copyWith(outlineColor: color),
                );
              }
            },
          ),
          DropdownButton<int>(
            key: const ValueKey<String>('subtitle-position-selector'),
            value: _subtitleStyle.position,
            items: const [90, 95, 100]
                .map(
                  (int position) => DropdownMenuItem<int>(
                    value: position,
                    child: Text('Position $position%'),
                  ),
                )
                .toList(),
            onChanged: (int? position) {
              if (position != null) {
                _applySubtitleStyle(
                  _subtitleStyle.copyWith(position: position),
                );
              }
            },
          ),
          FilterChip(
            key: const ValueKey<String>('subtitle-bold-toggle'),
            label: const Text('Bold'),
            selected: _subtitleStyle.bold,
            onSelected: (bool bold) =>
                _applySubtitleStyle(_subtitleStyle.copyWith(bold: bold)),
          ),
          FilterChip(
            key: const ValueKey<String>('subtitle-ass-override-toggle'),
            label: const Text('Override ASS'),
            selected: _subtitleStyle.overrideAssStyles,
            onSelected: (bool override) => _applySubtitleStyle(
              _subtitleStyle.copyWith(overrideAssStyles: override),
            ),
          ),
          IconButton(
            key: const ValueKey<String>('subtitle-delay-decrease'),
            tooltip: 'Decrease subtitle delay',
            onPressed: () => _adjustSubtitleDelay(-spikeSubtitleDelayStep),
            icon: const Icon(Icons.remove),
          ),
          Semantics(label: delayLabel, child: Text(delayLabel)),
          IconButton(
            key: const ValueKey<String>('subtitle-delay-increase'),
            tooltip: 'Increase subtitle delay',
            onPressed: () => _adjustSubtitleDelay(spikeSubtitleDelayStep),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
