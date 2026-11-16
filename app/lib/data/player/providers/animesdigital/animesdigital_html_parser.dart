/// Minimal parser for the stable, public WordPress markup used by AnimesDigital.
/// It extracts only title links, episode links, pagination and player-one HLS;
/// it never evaluates page scripts or follows embed pages.
final class AnimesDigitalHtmlParser {
  static const int maxPageCount = 200;
  static const Set<String> defaultAllowedMediaHosts = <String>{
    'cdn-s01.mywallpaper-4k-image.net',
  };

  AnimesDigitalHtmlParser({
    Iterable<String> allowedMediaHosts = defaultAllowedMediaHosts,
  }) : allowedMediaHosts = Set<String>.unmodifiable(
         allowedMediaHosts.map((String host) => host.trim().toLowerCase()),
       );

  /// Media origins reviewed from ordinary playback responses. A new origin
  /// must be verified and added explicitly before it can reach libmpv.
  final Set<String> allowedMediaHosts;

  static final RegExp _anchorPattern = RegExp(
    r'<a\b([^>]*)>(.*?)</a\s*>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _iframePattern = RegExp(
    r'<iframe\b([^>]*)>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _doubleQuotedAttribute = RegExp(
    r'''\b([a-z_:][-a-z0-9_:.]*)\s*=\s*"([^"]*)"''',
    caseSensitive: false,
  );
  static final RegExp _singleQuotedAttribute = RegExp(
    r"""\b([a-z_:][-a-z0-9_:.]*)\s*=\s*'([^']*)'""",
    caseSensitive: false,
  );
  static final RegExp _episodeNumber = RegExp(
    r'(?:epis[oó]dio|episode|ep\.?)\s*#?\s*(\d+(?:[.,]\d+)?)',
    caseSensitive: false,
  );
  static final RegExp _pageNumber = RegExp(
    r'/page/(\d+)/?$',
    caseSensitive: false,
  );
  static final RegExp _scriptOrStyle = RegExp(
    r'<(?:script|style)\b[^>]*>.*?</(?:script|style)\s*>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _tag = RegExp(r'<[^>]*>', dotAll: true);
  static final RegExp _numericEntity = RegExp(
    r'&#(?:x([0-9a-f]+)|(\d+));?',
    caseSensitive: false,
  );

  List<AnimesDigitalSearchResult> searchResults(
    String html, {
    required Uri pageUri,
  }) {
    final List<AnimesDigitalSearchResult> results = [];
    final Set<String> seen = {};
    for (final RegExpMatch match in _anchorPattern.allMatches(html)) {
      final Map<String, String> attributes = _attributes(match.group(1)!);
      final Uri? uri = _sameOriginUri(pageUri, attributes['href']);
      if (uri == null ||
          !uri.path.startsWith('/anime/a/') ||
          uri.query.isNotEmpty) {
        continue;
      }
      final String title = _text(match.group(2)!).isEmpty
          ? _decode(attributes['title'] ?? attributes['aria-label'] ?? '')
          : _text(match.group(2)!);
      final String sourceId = _sourceAnimeId(uri);
      if (title.isEmpty ||
          title.length > 256 ||
          sourceId.length > 256 ||
          !seen.add(sourceId)) {
        continue;
      }
      results.add(
        AnimesDigitalSearchResult(sourceAnimeId: sourceId, title: title),
      );
      if (results.length >= 50) break;
    }
    return List.unmodifiable(results);
  }

  AnimesDigitalEpisodePage episodePage(String html, {required Uri pageUri}) {
    final Map<String, AnimesDigitalEpisodeLink> episodes = {};
    Uri pageRoot = _withoutQueryAndFragment(pageUri);
    int pageCount = 1;

    for (final RegExpMatch match in _anchorPattern.allMatches(html)) {
      final Map<String, String> attributes = _attributes(match.group(1)!);
      final Uri? uri = _sameOriginUri(pageUri, attributes['href']);
      if (uri == null) continue;
      final RegExpMatch? pageMatch = _pageNumber.firstMatch(uri.path);
      if (pageMatch != null) {
        final int? page = int.tryParse(pageMatch.group(1)!);
        if (page != null) {
          if (page > pageCount) pageCount = page;
          pageRoot = _withoutQueryAndFragment(uri)
              .replace(path: uri.path.replaceFirst(_pageNumber, ''));
        }
        continue;
      }
      if (!uri.path.startsWith('/video/')) continue;
      final String label = _text(match.group(2)!);
      if (label.length > 256) continue;
      final RegExpMatch? numberMatch = _episodeNumber.firstMatch(label);
      if (numberMatch == null) continue;
      final double? value = double.tryParse(
        numberMatch.group(1)!.replaceAll(',', '.'),
      );
      if (value == null ||
          !value.isFinite ||
          value < 1 ||
          value != value.roundToDouble()) {
        continue;
      }
      final String episodeId = _withoutQueryAndFragment(uri).toString();
      if (episodeId.length > 256) continue;
      episodes.putIfAbsent(
        episodeId,
        () => AnimesDigitalEpisodeLink(
          episodeId: episodeId,
          number: value.toInt(),
          label: label,
        ),
      );
    }

    final List<AnimesDigitalEpisodeLink> ordered = episodes.values.toList()
      ..sort((AnimesDigitalEpisodeLink a, AnimesDigitalEpisodeLink b) {
        final int byNumber = a.number.compareTo(b.number);
        return byNumber != 0 ? byNumber : a.episodeId.compareTo(b.episodeId);
      });
    return AnimesDigitalEpisodePage(
      episodes: List.unmodifiable(ordered),
      pageRoot: pageRoot,
      pageCount: pageCount,
    );
  }

  Uri? playerOneHls(String html, {required Uri episodeUri}) {
    for (final RegExpMatch match in _iframePattern.allMatches(html)) {
      final Map<String, String> attributes = _attributes(match.group(1)!);
      final Uri? iframe = _sameOriginOrPublicUri(episodeUri, attributes['src']);
      if (iframe == null ||
          iframe.scheme != 'https' ||
          iframe.host.toLowerCase() != 'api.anivideo.net' ||
          iframe.path != '/videohls.php') {
        continue;
      }
      final String? direct = iframe.queryParameters['d'];
      if (direct == null || direct.isEmpty) continue;
      final Uri? media = Uri.tryParse(direct);
      if (media == null ||
          media.scheme != 'https' ||
          media.host.isEmpty ||
          media.userInfo.isNotEmpty ||
          media.hasFragment ||
          media.port != 443 ||
          !allowedMediaHosts.contains(media.host.toLowerCase()) ||
          !media.path.toLowerCase().endsWith('.m3u8')) {
        continue;
      }
      return media;
    }
    return null;
  }

  static Uri? _sameOriginUri(Uri base, String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final Uri? uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final Uri resolved = base.resolveUri(uri);
    if (resolved.scheme != base.scheme ||
        resolved.host.toLowerCase() != base.host.toLowerCase() ||
        resolved.port != base.port ||
        resolved.userInfo.isNotEmpty) {
      return null;
    }
    return resolved;
  }

  static Uri? _sameOriginOrPublicUri(Uri base, String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final Uri? uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final Uri resolved = base.resolveUri(uri);
    if (resolved.scheme != 'https' ||
        resolved.host.isEmpty ||
        resolved.userInfo.isNotEmpty ||
        resolved.port != 443 ||
        resolved.hasFragment) {
      return null;
    }
    return resolved;
  }

  static Uri _withoutQueryAndFragment(Uri uri) =>
      Uri(scheme: uri.scheme, host: uri.host, port: uri.port, path: uri.path);

  static String _sourceAnimeId(Uri uri) =>
      '${uri.path}${uri.hasFragment ? '#${uri.fragment}' : ''}';

  static Map<String, String> _attributes(String source) {
    final Map<String, String> values = {};
    for (final RegExpMatch match in _doubleQuotedAttribute.allMatches(source)) {
      values[match.group(1)!.toLowerCase()] = _decode(match.group(2)!);
    }
    for (final RegExpMatch match in _singleQuotedAttribute.allMatches(source)) {
      values.putIfAbsent(
        match.group(1)!.toLowerCase(),
        () => _decode(match.group(2)!),
      );
    }
    return values;
  }

  static String _text(String html) => _decode(
    html
        .replaceAll(_scriptOrStyle, ' ')
        .replaceAll(_tag, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim(),
  );

  static String _decode(String value) {
    const Map<String, String> named = {
      '&amp;': '&',
      '&quot;': '"',
      '&apos;': "'",
      '&#39;': "'",
      '&lt;': '<',
      '&gt;': '>',
      '&nbsp;': ' ',
      '&oacute;': 'ó',
      '&Oacute;': 'Ó',
      '&eacute;': 'é',
      '&Eacute;': 'É',
      '&aacute;': 'á',
      '&Aacute;': 'Á',
      '&iacute;': 'í',
      '&Iacute;': 'Í',
      '&uacute;': 'ú',
      '&Uacute;': 'Ú',
      '&atilde;': 'ã',
      '&otilde;': 'õ',
      '&ccedil;': 'ç',
      '&Ccedil;': 'Ç',
    };
    String decoded = value;
    for (final MapEntry<String, String> entry in named.entries) {
      decoded = decoded.replaceAll(entry.key, entry.value);
    }
    return decoded.replaceAllMapped(_numericEntity, (Match match) {
      final String? hex = match.group(1);
      final int? codePoint = int.tryParse(
        hex ?? match.group(2)!,
        radix: hex == null ? 10 : 16,
      );
      if (codePoint == null || codePoint < 0 || codePoint > 0x10ffff) {
        return match.group(0)!;
      }
      return String.fromCharCode(codePoint);
    });
  }
}

final class AnimesDigitalSearchResult {
  const AnimesDigitalSearchResult({
    required this.sourceAnimeId,
    required this.title,
  });

  final String sourceAnimeId;
  final String title;
}

final class AnimesDigitalEpisodeLink {
  const AnimesDigitalEpisodeLink({
    required this.episodeId,
    required this.number,
    required this.label,
  });

  final String episodeId;
  final int number;
  final String label;
}

final class AnimesDigitalEpisodePage {
  const AnimesDigitalEpisodePage({
    required this.episodes,
    required this.pageRoot,
    required this.pageCount,
  });

  final List<AnimesDigitalEpisodeLink> episodes;
  final Uri pageRoot;
  final int pageCount;
}
