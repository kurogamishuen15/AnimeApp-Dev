import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../application/player/source_switching/playback_source_switch_service.dart';

/// Minimal provider-neutral source switch UI for the opt-in player spike.
final class SourceSwitchPanel extends StatelessWidget {
  const SourceSwitchPanel({required this.service, super.key});

  final PlaybackSourceSwitchService service;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: service.states,
    initialData: service.state,
    builder: (context, snapshot) {
      final PlaybackSourceSwitchSnapshot state = snapshot.data ?? service.state;
      final String? current = state.current == null
          ? null
          : '${state.current!.sourceLabel ?? state.current!.providerId.value} · '
                '${state.current!.displayName ?? state.current!.serverId}';
      final String status = switch (state.activity) {
        PlaybackSourceSwitchActivity.idle => 'Source selected',
        PlaybackSourceSwitchActivity.resolving => 'Finding alternatives…',
        PlaybackSourceSwitchActivity.switching => 'Switching source…',
        PlaybackSourceSwitchActivity.fallback =>
          'Trying fallback ${state.failedCandidateCount + 1}…',
        PlaybackSourceSwitchActivity.failed => 'Source switch failed',
      };
      final Duration? delta = state.lastPositionDelta;
      final String? deltaLabel = delta == null
          ? null
          : 'Position difference ${delta.inMilliseconds} ms';
      final bool busy =
          state.activity == PlaybackSourceSwitchActivity.resolving ||
          state.activity == PlaybackSourceSwitchActivity.switching ||
          state.activity == PlaybackSourceSwitchActivity.fallback;
      return Card(
        key: const ValueKey<String>('source-switch-panel'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('Source: ${current ?? 'Unavailable'}'),
              Text(status),
              if (state.pending case final pending?)
                Text(
                  'Next: ${pending.sourceLabel ?? pending.providerId.value} · '
                  '${pending.displayName ?? pending.serverId}',
                ),
              if (state.error case final error?)
                Text(error, key: const ValueKey<String>('source-switch-error')),
              if (deltaLabel case final label?) Text(label),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              OutlinedButton.icon(
                key: const ValueKey<String>('switch-source-button'),
                onPressed: state.current == null || busy
                    ? null
                    : () => unawaited(service.switchToNext()),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Try another source'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
