import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'home_appearance.dart';
import 'home_artwork.dart';
import 'home_data.dart';
import 'home_score_badge.dart';
import 'home_typography.dart';

/// Cinematic featured banner with a lightweight, user-controlled highlight row.
final class HomeHero extends StatefulWidget {
  const HomeHero({
    required this.anime,
    required this.onDetails,
    this.highlights = const [],
    this.visible = true,
    super.key,
  });

  final HomeTitle anime;
  final List<HomeTitle> highlights;
  final bool visible;
  final ValueChanged<HomeTitle> onDetails;

  @override
  State<HomeHero> createState() => _HomeHeroState();
}

final class _HomeHeroState extends State<HomeHero> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _autoSlideTimer;
  bool _pointerInside = false;
  bool _indicatorFocused = false;
  bool _appActive = true;

  List<HomeTitle> get _entries =>
      widget.highlights.isEmpty ? [widget.anime] : widget.highlights;

  HomeTitle get _active =>
      _entries[_selectedIndex.clamp(0, _entries.length - 1)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appActive =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleAutoSlide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _scheduleAutoSlide();
  }

  @override
  void didUpdateWidget(covariant HomeHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= _entries.length) {
      _selectedIndex = 0;
    }
    if (oldWidget.visible != widget.visible ||
        oldWidget.highlights != widget.highlights ||
        oldWidget.anime != widget.anime) {
      _scheduleAutoSlide();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
    if (!mounted ||
        _entries.length < 2 ||
        !widget.visible ||
        !_appActive ||
        MediaQuery.of(context).disableAnimations ||
        !TickerMode.valuesOf(context).enabled ||
        (ModalRoute.of(context)?.isCurrent == false)) {
      return;
    }
    final interval = HomeAppearance.of(context).bannerAutoSlideInterval;
    if (interval.inMicroseconds <= 0) return;
    _autoSlideTimer = Timer(interval, _advanceAutomatically);
  }

  void _advanceAutomatically() {
    if (!mounted || _entries.length < 2) return;
    setState(() => _selectedIndex = (_selectedIndex + 1) % _entries.length);
    _scheduleAutoSlide();
  }

  void _selectManually(int index) {
    if (index < 0 || index >= _entries.length) return;
    setState(() => _selectedIndex = index);
    _scheduleAutoSlide();
  }

  void _setPointerInside(bool value) {
    if (_pointerInside == value) return;
    _pointerInside = value;
    _scheduleAutoSlide();
  }

  void _setIndicatorFocused(bool value) {
    if (_indicatorFocused == value) return;
    _indicatorFocused = value;
    _scheduleAutoSlide();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final colors = HomeAppearance.of(context);
        final reducedMotion = MediaQuery.of(context).disableAnimations;
        final anime = _active;
        final entries = widget.highlights.isEmpty
            ? [widget.anime]
            : widget.highlights;
        return MouseRegion(
          onEnter: (_) => _setPointerInside(true),
          onExit: (_) => _setPointerInside(false),
          child: SizedBox(
            width: constraints.maxWidth,
            height: wide ? 410 : 330,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: wide ? .72 : 1,
                      heightFactor: 1,
                      child: AnimatedSwitcher(
                        duration: reducedMotion
                            ? Duration.zero
                            : colors.lite
                            ? const Duration(milliseconds: 140)
                            : const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInOut,
                        child: HomeArtwork(
                          key: ValueKey(anime.externalId ?? anime.title),
                          asset: null,
                          url: anime.bannerUrl,
                          width: constraints.maxWidth * (wide ? .72 : 1),
                          height: wide ? 410 : 330,
                          alignment: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          HomeAppearance.background,
                          HomeAppearance.background,
                          Color(0x00000000),
                        ],
                        stops: [0, .36, .72],
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x20000000),
                          Color(0x40000000),
                          HomeAppearance.background,
                        ],
                        stops: [0, .43, 1],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          wide
                              ? const Color(0xe6000000)
                              : const Color(0xc9000000),
                          colors.lite
                              ? const Color(0x11000000)
                              : const Color(0x30170c33),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: wide
                      ? const Alignment(-1, .12)
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 610 : 300),
                      child: AnimatedSwitcher(
                        duration: reducedMotion
                            ? Duration.zero
                            : colors.lite
                            ? const Duration(milliseconds: 120)
                            : const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .018),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(anime.externalId ?? anime.title),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (anime.formatLabel case final label?)
                                  _HeroTag(label),
                                if (anime.seasonLabel case final label?)
                                  _HeroTag(label),
                                if (anime.score != null)
                                  HomeScoreBadge(
                                    score: anime.score,
                                    compact: false,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              header: true,
                              child: Text(
                                anime.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: HomeTypography.heroTitle(
                                  wide
                                      ? Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                      : Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                  colors,
                                ),
                              ),
                            ),
                            if (anime.genres.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                anime.genres.take(3).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xffd0cfd3),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: .05,
                                ),
                              ),
                            ],
                            const SizedBox(height: 19),
                            Wrap(
                              spacing: 9,
                              runSpacing: 8,
                              children: [
                                Tooltip(
                                  message: 'Aún no hay una fuente de reproducción disponible',
                                  child: FilledButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.play_arrow_outlined),
                                    label: const Text('Watch now'),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => widget.onDetails(anime),
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text('Details'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (entries.length > 1)
                  Positioned(
                    left: wide ? 0 : 16,
                    bottom: 14,
                    child: Focus(
                      onFocusChange: _setIndicatorFocused,
                      child: Row(
                        children: [
                          for (var index = 0; index < entries.length; index++)
                            Semantics(
                              button: true,
                              selected: index == _selectedIndex,
                              label: 'Mostrar ${entries[index].title}',
                              child: InkWell(
                                onTap: () => _selectManually(index),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 6,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    curve: Curves.easeOut,
                                    width: index == _selectedIndex ? 22 : 8,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: index == _selectedIndex
                                          ? Colors.white
                                          : const Color(0xff77777d),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xd9161619),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0x26ffffff)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: .1,
        ),
      ),
    ),
  );
}
