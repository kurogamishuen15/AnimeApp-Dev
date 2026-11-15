import 'anime_id.dart';

/// User-selected local library states; no automatic transition is implied.
enum LibraryStatus {
  planned,
  watching,
  rewatching,
  paused,
  completed,
  abandoned,
}

/// User-owned local membership. It contains no provider-owned metadata and is
/// retained when accounts/providers are disconnected or unavailable.
final class LibraryEntry {
  LibraryEntry({
    required this.animeId,
    required DateTime addedAtUtc,
    this.status = LibraryStatus.planned,
  }) : addedAtUtc = _requireUtc(addedAtUtc);

  final AnimeId animeId;
  final DateTime addedAtUtc;
  final LibraryStatus status;
}

DateTime _requireUtc(DateTime value) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, 'addedAtUtc', 'Timestamp must be UTC.');
  }
  return value;
}
