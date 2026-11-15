import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../application/player/skips/skip_segment_service.dart';
import '../../domain/player/skips/skip_segment.dart';

final class SkipSegmentPanel extends StatelessWidget {
  const SkipSegmentPanel({required this.service, super.key});

  final SkipSegmentService service;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<SkipSegmentServiceSnapshot>(
        stream: service.states,
        initialData: service.state,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<SkipSegmentServiceSnapshot> snapshot,
            ) {
              final SkipSegmentServiceSnapshot state =
                  snapshot.data ?? service.state;
              final SkipSegment? active = state.activeSegment;
              if (active == null &&
                  !state.loading &&
                  !state.unavailable &&
                  state.error == null) {
                return const SizedBox.shrink();
              }
              final String label = active == null
                  ? state.loading
                        ? 'Loading skip times…'
                        : state.error ?? 'Skip times unavailable'
                  : switch (active.kind) {
                      SkipSegmentKind.opening => 'Skip opening',
                      SkipSegmentKind.ending => 'Skip ending',
                      SkipSegmentKind.recap => 'Skip recap',
                      SkipSegmentKind.filler => 'Skip filler',
                    };
              return Card(
                key: const ValueKey<String>('skip-segment-panel'),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      if (state.loading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (active != null)
                        OutlinedButton.icon(
                          key: const ValueKey<String>('skip-current-segment'),
                          onPressed: state.skipping
                              ? null
                              : () => unawaited(service.skipCurrent()),
                          icon: const Icon(Icons.skip_next),
                          label: Text(state.skipping ? 'Seeking…' : label),
                        )
                      else
                        Text(
                          label,
                          key: const ValueKey<String>('skip-segment-status'),
                        ),
                      if (state.lastSkipConfirmed)
                        const Text(
                          'Seek confirmed',
                          key: ValueKey<String>('skip-confirmed'),
                        ),
                    ],
                  ),
                ),
              );
            },
      );
}
