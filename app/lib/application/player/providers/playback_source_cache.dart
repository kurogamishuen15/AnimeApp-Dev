import 'dart:collection';

import '../../../domain/player/providers/playback_source.dart';

/// Bounded in-memory LRU for provider source metadata. Expiration is supplied
/// by the registry and shortened to the earliest candidate expiry.
final class PlaybackSourceCache {
  PlaybackSourceCache({required this.capacity}) {
    if (capacity < 1 || capacity > 4096) {
      throw ArgumentError.value(capacity, 'capacity');
    }
  }

  final int capacity;
  final LinkedHashMap<String, _PlaybackSourceCacheEntry> _entries =
      LinkedHashMap<String, _PlaybackSourceCacheEntry>();

  int get length => _entries.length;

  List<PlaybackSource>? read(String key, DateTime now) {
    final _PlaybackSourceCacheEntry? entry = _entries.remove(key);
    if (entry == null) return null;
    if (!entry.expiresAt.isAfter(now)) return null;
    _entries[key] = entry;
    return entry.sources;
  }

  void write(
    String key,
    Iterable<PlaybackSource> sources, {
    required DateTime now,
    required Duration ttl,
    DateTime? validUntil,
  }) {
    if (key.trim().isEmpty || ttl <= Duration.zero) return;
    final List<PlaybackSource> value = List.unmodifiable(sources);
    if (value.isEmpty) return;
    DateTime expiresAt = now.add(ttl);
    if (validUntil case final DateTime expiry when expiry.isBefore(expiresAt)) {
      expiresAt = expiry;
    }
    if (!expiresAt.isAfter(now)) return;

    _entries.remove(key);
    _entries[key] = _PlaybackSourceCacheEntry(value, expiresAt);
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void invalidate(String key) => _entries.remove(key);

  void clear() => _entries.clear();
}

final class _PlaybackSourceCacheEntry {
  const _PlaybackSourceCacheEntry(this.sources, this.expiresAt);

  final List<PlaybackSource> sources;
  final DateTime expiresAt;
}
