/// Small, bounded parser for the public AnimeHeaven catalog and gate pages.
///
/// It intentionally reads only ordinary HTML attributes. It does not execute
/// scripts, follow player redirects, or interpret challenge pages.
final class AnimeHeavenHtmlParser {
  AnimeHeavenHtmlParser._();

  static const Set<String> allowedMirrorHosts = <String>{
    'ax.animeheaven.me',
    'cx.animeheaven.me',
    'cy.animeheaven.me',
    'ct.animeheaven.me',
    'ck.animeheaven.me',
  };

  static final RegExp _comments = RegExp(r'<!--[\s\S]*?-->');
  static final RegExp _cards = RegExp(
    r'''<div\b[^>]*\bclass\s*=\s*["'][^"']*\b(?:similarimg|chart)\b[^"']*["'][^>]*>''',
    caseSensitive: false,
  );
  static final RegExp _animeAnchor = RegExp(
    r'<a\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _nameContainer = RegExp(
    r'''<div\b[^>]*\bclass\s*=\s*["'][^"']*\b(?:similarname|charttitle)\b[^"']*["'][^>]*>\s*<a\b[^>]*>([\s\S]*?)</a>''',
    caseSensitive: false,
  );
  static final RegExp _imageTag = RegExp(r'<img\b[^>]*>', caseSensitive: false);
  static final RegExp _gateCall = RegExp(
    r'''gatea\s*\(\s*(?:"|&quot;|')([0-9a-f]{1,128})(?:"|&quot;|')\s*\)''',
    caseSensitive: false,
  );
  static final RegExp _episodeNumber = RegExp(
    r'''<div\b[^>]*\bwatch2\b[^>]*>\s*(\d+(?:\.\d+)?)\s*</div>''',
    caseSensitive: false,
  );
  static final RegExp _sourceTag = RegExp(
    r'<source\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _attribute = RegExp(
    r'''([:\w-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''',
  );
  static final RegExp _stripTags = RegExp(r'<[^>]+>');

  static List<AnimeHeavenSearchEntry> parseSearch(String html) {
    final String clean = html.replaceAll(_comments, '');
    final List<RegExpMatch> starts = _cards.allMatches(clean).toList();
    final List<AnimeHeavenSearchEntry> entries = <AnimeHeavenSearchEntry>[];
    final Set<String> seenPaths = <String>{};

    for (var index = 0; index < starts.length; index++) {
      final RegExpMatch start = starts[index];
      final String block = clean.substring(
        start.start,
        starts.elementAtOrNull(index + 1)?.start ?? clean.length,
      );
      final RegExpMatch? anchor = _animeAnchor.firstMatch(block);
      if (anchor == null) continue;
      final String? href = _attributeValue(anchor.group(0)!, 'href');
      final Uri? path = href == null ? null : Uri.tryParse(_decode(href));
      if (path == null || !_isAnimePath(path)) continue;

      final RegExpMatch? name = _nameContainer.firstMatch(block);
      String? title = name == null
          ? null
          : _decode(name.group(1)!.replaceAll(_stripTags, ''));
      if (title == null || title.trim().isEmpty) {
        final RegExpMatch? image = _imageTag.firstMatch(block);
        final String? alt = image == null
            ? null
            : _attributeValue(image.group(0)!, 'alt');
        title = alt == null ? null : _decode(alt);
      }
      final String normalizedTitle = title?.trim() ?? '';
      final String normalizedPath = path.toString();
      if (normalizedTitle.isEmpty || !seenPaths.add(normalizedPath)) continue;
      entries.add(
        AnimeHeavenSearchEntry(path: normalizedPath, title: normalizedTitle),
      );
    }
    return List<AnimeHeavenSearchEntry>.unmodifiable(entries);
  }

  static List<AnimeHeavenEpisodeEntry> parseEpisodes(String html) {
    final String clean = html.replaceAll(_comments, '');
    final List<({String key, int start, int end})> gates =
        <({String key, int start, int end})>[];
    for (final RegExpMatch anchor in _animeAnchor.allMatches(clean)) {
      final String? onclick = _attributeValue(anchor.group(0)!, 'onclick');
      if (onclick == null) continue;
      final RegExpMatch? gate = _gateCall.firstMatch(_decode(onclick));
      if (gate == null) continue;
      gates.add((
        key: gate.group(1)!.toLowerCase(),
        start: anchor.start,
        end: anchor.end,
      ));
    }

    final List<AnimeHeavenEpisodeEntry> episodes = <AnimeHeavenEpisodeEntry>[];
    final Set<int> seenNumbers = <int>{};
    for (var index = 0; index < gates.length; index++) {
      final ({String key, int start, int end}) gate = gates[index];
      final int nextStart = index + 1 < gates.length
          ? gates[index + 1].start
          : clean.length;
      final String segment = clean.substring(gate.end, nextStart);
      final RegExpMatch? numberMatch = _episodeNumber.firstMatch(segment);
      final double? parsed = double.tryParse(numberMatch?.group(1) ?? '');
      if (parsed == null || parsed < 1 || parsed > 10000) continue;
      final int number = parsed.toInt();
      if (seenNumbers.add(number)) {
        episodes.add(
          AnimeHeavenEpisodeEntry(number: number, gateKey: gate.key),
        );
      }
    }
    episodes.sort(
      (AnimeHeavenEpisodeEntry a, AnimeHeavenEpisodeEntry b) =>
          a.number.compareTo(b.number),
    );
    return List<AnimeHeavenEpisodeEntry>.unmodifiable(episodes);
  }

  static List<Uri> parseMp4Mirrors(String html, {required String gateKey}) {
    final String clean = html.replaceAll(_comments, '');
    final String normalizedGate = gateKey.toLowerCase();
    final List<Uri> mirrors = <Uri>[];
    final Set<String> seenHosts = <String>{};

    for (final RegExpMatch source in _sourceTag.allMatches(clean)) {
      final String? raw = _attributeValue(source.group(0)!, 'src');
      if (raw == null) continue;
      final Uri? uri = Uri.tryParse(_decode(raw).trim());
      if (uri == null || !_isAllowedMp4(uri)) continue;
      final String query = uri.query.toLowerCase();
      if (!query.startsWith(normalizedGate)) continue;
      if (query.length > normalizedGate.length &&
          !const <String>{'&', '='}.contains(query[normalizedGate.length])) {
        continue;
      }
      if (seenHosts.add(uri.host.toLowerCase())) mirrors.add(uri);
    }
    return List<Uri>.unmodifiable(mirrors);
  }

  static bool isAllowedMp4(Uri uri) => _isAllowedMp4(uri);

  static bool _isAllowedMp4(Uri uri) =>
      uri.scheme == 'https' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      uri.fragment.isEmpty &&
      uri.path.toLowerCase().endsWith('.mp4') &&
      allowedMirrorHosts.contains(uri.host.toLowerCase());

  static bool _isAnimePath(Uri uri) =>
      !uri.isAbsolute &&
      uri.scheme.isEmpty &&
      uri.host.isEmpty &&
      uri.userInfo.isEmpty &&
      uri.fragment.isEmpty &&
      (uri.path == 'anime.php' || uri.path == '/anime.php') &&
      uri.hasQuery;

  static String? _attributeValue(String tag, String name) {
    for (final RegExpMatch match in _attribute.allMatches(tag)) {
      if (match.group(1)!.toLowerCase() != name.toLowerCase()) continue;
      return match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
    }
    return null;
  }

  static String _decode(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#34;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

final class AnimeHeavenSearchEntry {
  const AnimeHeavenSearchEntry({required this.path, required this.title});

  final String path;
  final String title;
}

final class AnimeHeavenEpisodeEntry {
  const AnimeHeavenEpisodeEntry({required this.number, required this.gateKey});

  final int number;
  final String gateKey;
}
