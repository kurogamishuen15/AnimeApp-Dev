import '../../core/result/result.dart';
import 'anime_id.dart';
import 'library_entry.dart';

abstract interface class LocalLibraryRepository {
  Future<Result<List<LibraryEntry>>> list();

  Future<Result<LibraryEntry?>> get(AnimeId animeId);

  Future<Result<LibraryEntry>> add(AnimeId animeId);

  Future<Result<LibraryEntry>> setStatus(AnimeId animeId, LibraryStatus status);

  /// Removes membership only; identity and playback progress are preserved.
  Future<Result<void>> remove(AnimeId animeId);
}
