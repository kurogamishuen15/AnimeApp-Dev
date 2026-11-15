import 'package:anime_app/domain/player/subtitles/external_subtitle_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts bounded text and validated subtitle identifiers', () {
    final ExternalSubtitleQuery query = ExternalSubtitleQuery(
      query: ' Episode 1 ',
      languages: const ['en', 'ja-JP'],
      imdbId: 'tt00123',
      tmdbId: '456',
      season: 1,
      episode: 2,
      movieHash: '0123456789abcdef',
      fileName: 'Show.S01E02.mkv',
    );
    expect(query.query, ' Episode 1 ');
    expect(query.languages, ['en', 'ja-JP']);
    expect(query.imdbId, 'tt00123');
    expect(query.season, 1);
    final ExternalSubtitleQuery parentQuery = ExternalSubtitleQuery(
      parentImdbId: 'tt00999',
      season: 1,
      episode: 2,
    );
    expect(parentQuery.parentImdbId, 'tt00999');
  });

  test(
    'rejects missing identity, malformed IDs, hash, language and episode',
    () {
      expect(() => ExternalSubtitleQuery(), throwsArgumentError);
      expect(
        () => ExternalSubtitleQuery(query: 'show', tmdbId: 'x'),
        throwsArgumentError,
      );
      expect(
        () => ExternalSubtitleQuery(query: 'show', imdbId: 'tt-anime'),
        throwsArgumentError,
      );
      expect(
        () => ExternalSubtitleQuery(imdbId: 'tt123', parentImdbId: 'tt456'),
        throwsArgumentError,
      );
      expect(
        () => ExternalSubtitleQuery(query: 'show', movieHash: '1234'),
        throwsArgumentError,
      );
      expect(
        () =>
            ExternalSubtitleQuery(query: 'show', languages: const ['english']),
        throwsArgumentError,
      );
      expect(
        () => ExternalSubtitleQuery(query: 'show', season: 1),
        throwsArgumentError,
      );
    },
  );

  test('rejects overlong search strings', () {
    expect(
      () => ExternalSubtitleQuery(query: List.filled(201, 'x').join()),
      throwsArgumentError,
    );
    expect(
      () => ExternalSubtitleQuery(
        query: 'show',
        fileName: List.filled(513, 'x').join(),
      ),
      throwsArgumentError,
    );
  });
}
