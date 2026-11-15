import 'dart:async';

import 'package:anime_app/app/player/spike_player_module.dart';
import 'package:anime_app/main_player_spike.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _windowChannel = MethodChannel('kongroo/f2.2/window');

void main() {
  testWidgets('cleanup failure remains visible when module opening fails', (
    tester,
  ) async {
    final Completer<SpikePlayerModule> opening = Completer<SpikePlayerModule>();
    await tester.pumpWidget(
      SpikePlayerApp(
        moduleFuture: opening.future,
        retryPendingCleanup: () async {
          throw StateError('native cleanup remains quarantined');
        },
      ),
    );
    opening.completeError(StateError('player open failed'));
    await tester.pump();
    await tester.pump();

    expect(find.text('The F2.2 player could not be opened.'), findsOneWidget);
    final Future<bool?> closeRequest = _requestPlatformClose(tester);
    await tester.pump();
    expect(await closeRequest, isFalse);
    await tester.pump();

    expect(
      find.text(
        'Playback cleanup failed. The window will stay open; retry closing after checking the player.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'cleanup timeout remains visible while module opening is pending',
    (tester) async {
      final Completer<SpikePlayerModule> opening =
          Completer<SpikePlayerModule>();
      await tester.pumpWidget(
        SpikePlayerApp(
          moduleFuture: opening.future,
          retryPendingCleanup: () async {},
          closeWatchdog: const Duration(milliseconds: 1),
        ),
      );

      final Future<bool?> closeResult = _requestPlatformClose(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2));
      expect(await closeResult, isFalse);
      await tester.pump();

      expect(find.text('Opening the F2.2 player…'), findsOneWidget);
      expect(
        find.text(
          'Playback cleanup is still running. No native operation was cancelled; the window will stay open. Retry closing after cleanup finishes.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Future<bool?> _requestPlatformClose(WidgetTester tester) async {
  final response = await tester.binding.defaultBinaryMessenger
      .handlePlatformMessage(
        _windowChannel.name,
        _windowChannel.codec.encodeMethodCall(const MethodCall('requestClose')),
        null,
      );
  if (response == null) return null;
  return _windowChannel.codec.decodeEnvelope(response) as bool?;
}
