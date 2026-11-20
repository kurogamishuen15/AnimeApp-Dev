/// Immutable specification for a playback provider.
///
/// Defines what a provider is, how it is categorized, and under what
/// conditions it appears in the "Fuentes encontradas" dialog.
///
/// Instances are created once at module initialization and collected
/// into a [ProviderRegistry] which is the single source of truth for
/// what providers exist and which are visible.
class ProviderSpec {
  const ProviderSpec({
    required this.key,
    required this.label,
    required this.kind,
    this.extractor,
    required this.priority,
    required this.enabledByDefault,
    this.flag,
    required this.license,
  });

  /// Provider identifier used in the registry and by extractor factories.
  final String key;
  /// Human-readable label shown in the UI.
  final String label;
  /// Type of media this provider handles.
  final ProviderKind kind;
  /// Optional extractor key; when non-null the provider factory must have
  /// an implementation for it, otherwise registration fails at test time.
  final String? extractor;
  /// Priority within the ordered visible list. Higher priority appears first.
  final int priority;
  /// Default enabled state. If true the spec is visible unless its flag
  /// explicitly disables it.
  final bool enabledByDefault;
  /// Feature flag that can disable this spec at runtime. When `flag` is
  /// `null` the spec is always visible. When `flag` is `'0'` the spec is
  /// hidden. Any other value is treated as enabled.
  final String? flag;
  /// License identifier for the provider's content source.
  final String license;
}

/// Kind of playback provider, determining how sources are resolved.
enum ProviderKind { file, hls, drm, iframe }

/// Single source of truth for all playback providers visible in the UI.
///
/// The [PlaybackProviderManager] and the "Fuentes encontradas" dialog both
/// read from this registry. Adding or removing a [ProviderSpec] automatically
/// changes what appears in the source list — no separate hardcoded list exists.
final class ProviderRegistry {
  const ProviderRegistry(this._specs);

  /// Registered specifications, ordered by priority (highest first) and then
  /// by insertion order for ties.
  final List<ProviderSpec> _specs;

  /// Returns only the specs that are enabled (considering [enabledByDefault]
  /// and [flag]).
  Iterable<ProviderSpec> get visible {
    return _specs.where((spec) {
      if (!spec.enabledByDefault) return false;
      if (spec.flag == '0') return false;
      return true;
    });
  }

  /// Look up a spec by its key, or `null` if not found.
  ProviderSpec? byKey(String k) =>
      _specs.firstWhere((spec) => spec.key == k, orElse: () => null);

  /// Returns all visible specs sorted by priority descending, with stable
  /// ordering for equal priorities (insertion order preserved).
  List<ProviderSpec> get ordered =>
      visible.toList()..sort((a, b) => b.priority.compareTo(a.priority));

  /// Whether a given key is currently visible in the UI.
  bool isVisible(String key) => byKey(key)?.isVisible ?? false;

  /// Internal helper: checks visibility considering default + flag.
  bool _isVisibleSpec(ProviderSpec spec) =>
      !spec.enabledByDefault || spec.flag == '0';

}

extension ProviderSpecVisibility on ProviderSpec {
  /// True when this spec should appear in the "Fuentes encontradas" dialog.
  bool get isVisible =>
      !enabledByDefault ? false : flag == '0' ? false : true;
}