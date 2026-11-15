import 'dart:math';

import '../../domain/catalog/anime_id.dart';

/// RFC 4122 version 4 IDs generated locally with the platform secure RNG.
final class UuidAnimeIdGenerator implements AnimeIdGenerator {
  UuidAnimeIdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  @override
  AnimeId generate() {
    final List<int> bytes = List<int>.generate(
      16,
      (_) => _random.nextInt(256),
      growable: false,
    );
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final String hex = bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final String uuid =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
    return AnimeId('anime:$uuid');
  }
}
