/// HTML and JS-string parsing helpers shared by the scraped-site providers,
/// ported from Anilili's `NativeProviderParsers.kt` (project Anilili, MIT-0).
///
/// All helpers are pure string functions: no transport, no host access, and
/// no JavaScript execution. Bounded input sizes are enforced by callers.
abstract final class HtmlPlaybackParsers {
  /// Attribute value of [name] inside a single [tag] string, quoted (possibly
  /// multiline) or unquoted, with entities decoded. Empty when absent.
  static String attr(String tag, String name) {
    final String escaped = RegExp.escape(name);
    final String? quoted = RegExp(
      '\\b$escaped\\s*=\\s*(["\'])(.*?)\\1',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(tag)?.group(2);
    // Some providers (e.g. AniZone) emit unquoted attribute values.
    final String? raw =
        quoted ??
        RegExp(
          '\\b$escaped\\s*=\\s*([^"\'\\s>]+)',
          caseSensitive: false,
        ).firstMatch(tag)?.group(1);
    return raw == null ? '' : decodeEntities(raw);
  }

  /// Visible text of an HTML fragment, tags stripped and entities decoded.
  static String stripTags(String html) => decodeEntities(
        html
            .replaceAll(RegExp('<[^>]*>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
      );

  /// Named and numeric entity decoding plus JS backslash-slash normalization.
  static String decodeEntities(String value) {
    String decoded = value
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
    decoded = decoded.replaceAllMapped(RegExp('&#(\\d+);'), (match) {
      final int? code = int.tryParse(match.group(1)!);
      return code == null
          ? match.group(0)!
          : String.fromCharCode(code);
    });
    decoded = decoded.replaceAllMapped(
      RegExp('&#x([0-9a-f]+);', caseSensitive: false),
      (match) {
        final int? code = int.tryParse(match.group(1)!, radix: 16);
        return code == null ? match.group(0)! : String.fromCharCode(code);
      },
    );
    return decoded.replaceAll('\\/', '/');
  }

  /// Anilili's normalization: lowercase and strip everything but `[a-z0-9]`.
  /// Used only to rank candidates; conservative selection stays elsewhere.
  static String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  /// Bigram Dice similarity with containment bonus, as in Anilili's
  /// `titleScore`. Pure ranking aid — never used to approve a match alone.
  static double titleScore(String query, String candidate) {
    final String a = normalize(query);
    final String b = normalize(candidate);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (b.contains(a) || a.contains(b)) return 0.86;
    if (a.length < 2 || b.length < 2) return 0;
    final Map<String, int> counts = <String, int>{};
    for (int i = 0; i < a.length - 1; i++) {
      final String pair = a.substring(i, i + 2);
      counts[pair] = (counts[pair] ?? 0) + 1;
    }
    int hits = 0;
    for (int i = 0; i < b.length - 1; i++) {
      final String pair = b.substring(i, i + 2);
      final int remaining = counts[pair] ?? 0;
      if (remaining > 0) {
        hits++;
        counts[pair] = remaining - 1;
      }
    }
    return (2.0 * hits) / ((a.length - 1) + (b.length - 1));
  }

  /// Resolves [value] against [base]; absolute values pass through unchanged.
  static String absoluteUrl(String base, String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final Uri? uri = Uri.tryParse(base)?.resolve(value);
    return uri == null ? value : uri.toString();
  }

  /// Every HLS-looking URL in an HTML fragment, entities and JS slashes
  /// decoded, protocol-relative forms upgraded to https.
  static List<String> hlsUrls(String html) => RegExp(
        '(?:https?:)?(?:\\\\/|/)[^"\'\\s<>]+?\\.m3u8[^"\'\\s<>]*',
        caseSensitive: false,
      )
      .allMatches(html)
      .map((RegExpMatch match) => match.group(0)!)
      .map(decodeEntities)
      .map(
        (String value) =>
            value.startsWith('//') ? 'https:$value' : value,
      )
      .toSet()
      .toList();

  /// Decodes the escaped JSON that AniZone-style servers embed inside
  /// `wire:snapshot` attributes and `JSON.parse('...')` strings:
  /// `\u0022` (with one to three leading backslashes) becomes a quote,
  /// `\/` variants become plain slashes, and `\uXXXX` becomes its character.
  static String decodeJsonEscapes(String raw) {
    String decoded = raw.replaceAll(RegExp(r'\\{1,3}u0022'), '"');
    decoded = decoded.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (Match match) {
        final int? code = int.tryParse(match.group(1)!, radix: 16);
        return code == null || code < 0 || code > 0x10ffff
            ? match.group(0)!
            : String.fromCharCode(code);
      },
    );
    return decoded.replaceAll(RegExp(r'\\{1,3}/'), '/');
  }
}
