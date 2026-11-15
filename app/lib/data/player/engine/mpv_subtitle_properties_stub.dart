import 'package:media_kit/media_kit.dart';

Future<void> writeMpvSubtitleProperty(
  Player player,
  String property,
  String value,
) => throw UnsupportedError(
  'Runtime subtitle styling requires the native media_kit backend.',
);

Future<String> readMpvSubtitleProperty(Player player, String property) =>
    throw UnsupportedError(
      'Runtime subtitle styling requires the native media_kit backend.',
    );
