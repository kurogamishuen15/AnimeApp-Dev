import 'package:media_kit/media_kit.dart';

Future<void> writeMpvSubtitleProperty(
  Player player,
  String property,
  String value,
) async {
  final PlatformPlayer? platform = player.platform;
  if (platform is! NativePlayer) {
    throw UnsupportedError('The active player is not a native mpv player.');
  }
  await platform.setProperty(property, value);
  final String observed = await platform.getProperty(property);
  if (!_equivalentMpvValue(value, observed)) {
    throw StateError('mpv did not apply the requested subtitle option.');
  }
}

bool _equivalentMpvValue(String expected, String actual) {
  if (expected.startsWith('#')) {
    return expected.toUpperCase() == actual.toUpperCase();
  }
  if (expected == 'yes' || expected == 'no' || expected == 'force') {
    return expected == actual.toLowerCase();
  }
  final double? expectedNumber = double.tryParse(expected);
  final double? actualNumber = double.tryParse(actual);
  if (expectedNumber != null && actualNumber != null) {
    return (expectedNumber - actualNumber).abs() < 0.000001;
  }
  return expected == actual;
}

Future<String> readMpvSubtitleProperty(Player player, String property) async {
  final PlatformPlayer? platform = player.platform;
  if (platform is! NativePlayer) {
    throw UnsupportedError('The active player is not a native mpv player.');
  }
  return platform.getProperty(property);
}
