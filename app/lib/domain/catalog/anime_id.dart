/// Stable AnimeApp identity, independent from any metadata provider.
///
/// IDs are opaque ASCII values. Creation belongs to an injected ID generator;
/// titles and provider IDs must never be used as the local primary key.
final class AnimeId {
  factory AnimeId(String value) {
    final String normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9._:-]{0,127}$').hasMatch(normalized)) {
      throw ArgumentError.value(value, 'value', 'Invalid anime identity.');
    }
    return AnimeId._(normalized);
  }

  const AnimeId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is AnimeId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Supplies opaque IDs at the persistence boundary.
abstract interface class AnimeIdGenerator {
  AnimeId generate();
}
