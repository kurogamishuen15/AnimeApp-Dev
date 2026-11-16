import 'package:anime_app/data/player/providers/animesdigital/animesdigital_html_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AnimesDigitalHtmlParser parser = AnimesDigitalHtmlParser();
  final Uri searchUri = Uri.https('animesdigital.org', '/', {'s': 'One Piece'});

  test('extracts only same-origin anime links and decodes visible titles', () {
    final List<AnimesDigitalSearchResult> results = parser.searchResults('''
      <a href="/anime/a/one-piece/">One Piece</a>
      <a href="https://outside.example/anime/a/fake">One Piece</a>
      <a href="/video/a/123/">One Piece Episódio 1</a>
      <a href="/anime/a/one-piece/">Duplicate</a>
      ''', pageUri: searchUri);

    expect(results, hasLength(1));
    expect(results.single.sourceAnimeId, '/anime/a/one-piece/');
    expect(results.single.title, 'One Piece');
  });

  test('reads numbered episode links and bounded pagination', () {
    final AnimesDigitalEpisodePage page = parser.episodePage('''
      <a href="/anime/a/one-piece/page/4/">Última página</a>
      <a href="/video/a/3/">One Piece Episódio 3</a>
      <a href="/video/a/special/">Especial</a>
      <a href="https://outside.example/video/a/1/">One Piece Episódio 1</a>
      ''', pageUri: Uri.https('animesdigital.org', '/anime/a/one-piece/'));

    expect(page.pageCount, 4);
    expect(page.pageRoot.path, '/anime/a/one-piece');
    expect(page.episodes, hasLength(1));
    expect(page.episodes.single.number, 3);
    expect(
      page.episodes.single.episodeId,
      'https://animesdigital.org/video/a/3/',
    );
  });

  test('extracts only the supported Anivideo direct HLS player', () {
    final Uri episodeUri = Uri.https('animesdigital.org', '/video/a/1/');
    final Uri media = Uri.https(
      'cdn-s01.mywallpaper-4k-image.net',
      '/stream/master.m3u8',
    );
    final String embedded = Uri.https('api.anivideo.net', '/videohls.php', {
      'd': media.toString(),
    }).toString();

    expect(
      parser.playerOneHls(
        '<iframe src="$embedded"></iframe>',
        episodeUri: episodeUri,
      ),
      media,
    );
    expect(
      parser.playerOneHls(
        '<iframe src="https://blogspot.example/watch"></iframe>',
        episodeUri: episodeUri,
      ),
      isNull,
    );
  });

  test('rejects media origins until they are explicitly reviewed', () {
    final Uri episodeUri = Uri.https('animesdigital.org', '/video/a/1/');
    final Uri media = Uri.https('cdn.unreviewed.example', '/master.m3u8');
    final String embedded = Uri.https('api.anivideo.net', '/videohls.php', {
      'd': media.toString(),
    }).toString();

    expect(
      parser.playerOneHls(
        '<iframe src="$embedded"></iframe>',
        episodeUri: episodeUri,
      ),
      isNull,
    );
    expect(
      AnimesDigitalHtmlParser(allowedMediaHosts: ['cdn.unreviewed.example'])
          .playerOneHls(
            '<iframe src="$embedded"></iframe>',
            episodeUri: episodeUri,
          ),
      media,
    );
  });

  test('ignores overlong catalog IDs, titles, episode IDs and labels', () {
    final String longText = 'x' * 257;
    final List<AnimesDigitalSearchResult> search = parser.searchResults('''
      <a href="/anime/a/valid/">One Piece</a>
      <a href="/anime/a/$longText/">One Piece</a>
      <a href="/anime/a/long-title/">$longText</a>
      ''', pageUri: searchUri);
    final AnimesDigitalEpisodePage episodes = parser.episodePage('''
      <a href="/video/a/1/">Episode 1</a>
      <a href="/video/a/$longText/">Episode 2</a>
      <a href="/video/a/3/">Episode 3 $longText</a>
      ''', pageUri: Uri.https('animesdigital.org', '/anime/a/one-piece/'));

    expect(search, hasLength(1));
    expect(search.single.sourceAnimeId, '/anime/a/valid/');
    expect(episodes.episodes, hasLength(1));
    expect(episodes.episodes.single.number, 1);
  });

  test('rejects non-HTTPS, credentialed and non-manifest media URLs', () {
    final Uri episodeUri = Uri.https('animesdigital.org', '/video/a/1/');
    for (final Uri media in [
      Uri.http('cdn.example.org', '/master.m3u8'),
      Uri.https('user:secret@cdn.example.org', '/master.m3u8'),
      Uri.https('cdn.example.org', '/watch'),
      Uri.https('cdn.example.org', '/master.m3u8#fragment'),
    ]) {
      final String embedded = Uri.https('api.anivideo.net', '/videohls.php', {
        'd': media.toString(),
      }).toString();
      expect(
        parser.playerOneHls(
          '<iframe src="$embedded"></iframe>',
          episodeUri: episodeUri,
        ),
        isNull,
      );
    }
  });
}
