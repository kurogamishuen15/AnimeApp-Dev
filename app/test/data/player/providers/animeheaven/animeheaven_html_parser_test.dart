import 'package:anime_app/data/player/providers/animeheaven/animeheaven_html_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search parser accepts catalog routes and decodes titles', () {
    final List<AnimeHeavenSearchEntry> entries =
        AnimeHeavenHtmlParser.parseSearch('''
<!-- <div class="similarimg"><a href="anime.php?id=wrong">fake</a></div> -->
<div class='similarimg'>
  <a href='/anime.php?id=42&amp;type=tv'>open</a>
  <div class='similarname'><a>One &amp; Only Piece</a></div>
</div>
<div class='similarimg'><a href='https://evil.example/anime.php?id=9'>bad</a>
  <div class='similarname'><a>Wrong Host</a></div></div>
''');

    expect(entries, hasLength(1));
    expect(entries.single.path, '/anime.php?id=42&type=tv');
    expect(entries.single.title, 'One & Only Piece');
  });

  test('episode parser keeps each public gate key with its own number', () {
    final List<AnimeHeavenEpisodeEntry> episodes =
        AnimeHeavenHtmlParser.parseEpisodes('''
<a onclick='gatea("a1b2")'><div class='watch2'>1</div></a>
<div><a href='/extra'>unrelated</a></div>
<a onclick='gatea("c3d4")'><div class='watch2'>2.0</div></a>
''');

    expect(episodes.map((AnimeHeavenEpisodeEntry item) => item.number), [1, 2]);
    expect(episodes.map((AnimeHeavenEpisodeEntry item) => item.gateKey), [
      'a1b2',
      'c3d4',
    ]);
  });

  test('MP4 parser removes comment decoys, wrong keys, and unknown hosts', () {
    final List<Uri> mirrors = AnimeHeavenHtmlParser.parseMp4Mirrors('''
<!-- <source src="https://ax.animeheaven.me/decoy.mp4?a1b2"> -->
<source src="https://cx.animeheaven.me/video.mp4?a1b2&amp;expires=999">
<source src="https://cx.animeheaven.me/duplicate.mp4?a1b2&amp;expires=999">
<source src="https://ct.animeheaven.me/video.mp4?a1b2&amp;expires=999">
<source src="https://ck.animeheaven.me/video.mp4?other&amp;expires=999">
<source src="https://untrusted.example/video.mp4?a1b2&amp;expires=999">
''', gateKey: 'a1b2');

    expect(mirrors.map((Uri item) => item.host), [
      'cx.animeheaven.me',
      'ct.animeheaven.me',
    ]);
  });

  test('host validation rejects alternate schemes and path suffix tricks', () {
    expect(
      AnimeHeavenHtmlParser.isAllowedMp4(
        Uri.parse('https://cx.animeheaven.me/video.mp4'),
      ),
      isTrue,
    );
    expect(
      AnimeHeavenHtmlParser.isAllowedMp4(
        Uri.parse('http://cx.animeheaven.me/video.mp4'),
      ),
      isFalse,
    );
    expect(
      AnimeHeavenHtmlParser.isAllowedMp4(
        Uri.parse('https://cx.animeheaven.me/video.mp4.evil'),
      ),
      isFalse,
    );
    expect(
      AnimeHeavenHtmlParser.isAllowedMp4(
        Uri.parse('https://cx.animeheaven.me.evil/video.mp4'),
      ),
      isFalse,
    );
  });
}
