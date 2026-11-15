import 'dart:async';

import 'package:anime_app/app/player/player_window_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('test/kongroo-player-window');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'GTK request is not treated as effective until state event arrives',
    () async {
      final List<bool> requests = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getFullscreenState') return false;
            if (call.method == 'setFullscreen') {
              requests.add(call.arguments! as bool);
              return null;
            }
            return null;
          });
      final GtkPlayerWindowController controller = GtkPlayerWindowController(
        channel: channel,
      );
      try {
        await controller.initialize();
        expect(controller.state.observed, isTrue);
        expect(controller.state.fullscreen, isFalse);

        await controller.requestFullscreen(true);
        expect(requests, [true]);
        expect(controller.state.fullscreen, isFalse);
        expect(controller.state.requestPending, isTrue);

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channel.name,
              channel.codec.encodeMethodCall(
                const MethodCall('fullscreenChanged', true),
              ),
              null,
            );
        expect(controller.state.fullscreen, isTrue);
        expect(controller.state.observed, isTrue);
        expect(controller.state.requestPending, isFalse);
      } finally {
        await controller.dispose();
      }
    },
  );

  test(
    'late immediate method reply cannot overwrite GTK transition event',
    () async {
      final Completer<void> firstRequestReply = Completer<void>();
      final Completer<void> firstRequestStarted = Completer<void>();
      final Completer<void> secondRequestStarted = Completer<void>();
      final List<bool> requests = <bool>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getFullscreenState') return false;
            if (call.method == 'setFullscreen') {
              requests.add(call.arguments! as bool);
              if (requests.length == 1) {
                firstRequestStarted.complete();
                await firstRequestReply.future;
              } else if (requests.length == 2) {
                secondRequestStarted.complete();
              }
              return null;
            }
            return null;
          });
      final GtkPlayerWindowController controller = GtkPlayerWindowController(
        channel: channel,
      );
      try {
        await controller.initialize();
        final Future<void> request = controller.requestFullscreen(true);
        await firstRequestStarted.future;
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channel.name,
              channel.codec.encodeMethodCall(
                const MethodCall('fullscreenChanged', true),
              ),
              null,
            );
        expect(controller.state.fullscreen, isTrue);
        expect(controller.state.requestPending, isFalse);

        final Future<void> exitRequest = controller.requestFullscreen(false);
        await secondRequestStarted.future;
        expect(requests, <bool>[true, false]);
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channel.name,
              channel.codec.encodeMethodCall(
                const MethodCall('fullscreenChanged', false),
              ),
              null,
            );
        expect(controller.state.fullscreen, isFalse);
        expect(controller.state.requestPending, isFalse);

        firstRequestReply.complete();
        await request;
        await exitRequest;
        expect(controller.state.fullscreen, isFalse);
        expect(controller.state.requestPending, isFalse);
        expect(controller.state.error, isNull);
      } finally {
        if (!firstRequestReply.isCompleted) firstRequestReply.complete();
        await controller.dispose();
      }
    },
  );

  test('missing GTK transition expires without claiming fullscreen', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          if (call.method == 'getFullscreenState') return false;
          if (call.method == 'setFullscreen') return null;
          return null;
        });
    final GtkPlayerWindowController controller = GtkPlayerWindowController(
      channel: channel,
      transitionTimeout: const Duration(milliseconds: 5),
    );
    try {
      await controller.initialize();
      await controller.requestFullscreen(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.fullscreen, isFalse);
      expect(controller.state.requestPending, isFalse);
      expect(controller.state.error, contains('did not confirm'));
    } finally {
      await controller.dispose();
    }
  });

  test(
    'late GTK state cannot settle an opposite request after timeout',
    () async {
      final List<bool> requests = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getFullscreenState') return false;
            if (call.method == 'setFullscreen') {
              requests.add(call.arguments! as bool);
              return null;
            }
            return null;
          });
      final GtkPlayerWindowController controller = GtkPlayerWindowController(
        channel: channel,
        transitionTimeout: const Duration(milliseconds: 5),
      );
      try {
        await controller.initialize();
        await controller.requestFullscreen(true);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(controller.state.fullscreen, isFalse);
        expect(controller.state.requestPending, isFalse);

        // The original GTK request may still complete after its watchdog.
        // An opposite request stays blocked until the actual state settles.
        await controller.requestFullscreen(false);
        expect(requests, [true]);

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channel.name,
              channel.codec.encodeMethodCall(
                const MethodCall('fullscreenChanged', true),
              ),
              null,
            );
        expect(controller.state.fullscreen, isTrue);
        expect(controller.state.requestPending, isFalse);

        await controller.requestFullscreen(false);
        expect(requests, [true, false]);
      } finally {
        await controller.dispose();
      }
    },
  );

  test('GTK channel failure is observable and rethrown', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          if (call.method == 'getFullscreenState') return false;
          throw PlatformException(code: 'gtk_failed');
        });
    final GtkPlayerWindowController controller = GtkPlayerWindowController(
      channel: channel,
    );
    try {
      await controller.initialize();
      await expectLater(
        controller.requestFullscreen(true),
        throwsA(isA<PlatformException>()),
      );
      expect(controller.state.requestPending, isFalse);
      expect(controller.state.error, contains('rejected'));
    } finally {
      await controller.dispose();
    }
  });
}
