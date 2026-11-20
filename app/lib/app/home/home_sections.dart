import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import 'home_appearance.dart';
import 'home_artwork.dart';
import 'home_card_actions.dart';
import 'home_data.dart';
import 'home_icons.dart';
import 'home_score_badge.dart';
import 'home_typography.dart';

abstract final class HomeSections {
  static List<Widget> buildSections(
    HomeContent content,
    ValueChanged<HomeTitle> onDetails, {
    required Future<void> Function(HomeTitle, HomeCardLibraryCommand)
    onLibraryAction,
    required bool wide,
    ValueChanged<HomeEpisode>? onResume,
  }) => [
    if (content.episodes.isNotEmpty) ...[
      const _SectionTitle('Continue watching'),
      _Shelf(
        id: 'continue',
        height: wide ? 225 : 192,
        width: wide ? 246 : 187,
        count: content.episodes.length,
        buildCard: (index, width) => _EpisodeCard(
          episode: content.episodes[index],
          width: width,
          onResume: onResume,
          onDetails: onDetails,
          onLibraryAction: onLibraryAction,
        ),
      ),
    ],
    if (content.watching.isNotEmpty) ...[
      const _SectionTitle('Currently watching'),
      _posters('watching', content.watching, wide, onDetails, onLibraryAction),
    ],
    for (final shelf in content.shelves.where(
      (item) => item.titles.isNotEmpty,
    )) ...[
      _SectionTitle(shelf.label),
      _posters(shelf.label, shelf.titles, wide, onDetails, onLibraryAction),
    ],
  ];

  static Widget _posters(
    String id,
    List<HomeTitle> titles,
    bool wide,
    ValueChanged<HomeTitle> onDetails,
    Future<void> Function(HomeTitle, HomeCardLibraryCommand) onLibraryAction,
  ) => _Shelf(
    id: id,
    // Poster art (2:3), up to two title lines, card padding and the ListView
    // bottom breathing room. Keep the label fully inside the shelf viewport.
    height: wide ? 310 : 242,
    width: wide ? 164 : 118,
    count: titles.length,
    buildCard: (index, width) => _ArtworkCard(
      anime: titles[index],
      imageUrl: titles[index].coverUrl,
      width: width,
      ratio: 2 / 3,
      onPressed: () => onDetails(titles[index]),
      onDetails: () => onDetails(titles[index]),
      onLibraryAction: onLibraryAction,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: HomeTypography.sectionTitle(
          Theme.of(context).textTheme.titleLarge,
          HomeAppearance.of(context),
        ),
      ),
    ),
  );
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.id,
    required this.height,
    required this.width,
    required this.count,
    required this.buildCard,
  });

  final String id;
  final double height;
  final double width;
  final int count;
  final Widget Function(int index, double width) buildCard;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = width.clamp(0.0, constraints.maxWidth).toDouble();
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      if (count * (cardWidth + 12) - 12 <= constraints.maxWidth) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < count; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              SizedBox(width: cardWidth, child: buildCard(index, cardWidth)),
            ],
          ],
        );
      }
      return SizedBox(
        height: height + (scale - 1).clamp(0, double.infinity) * 134,
        child: _ScrollableShelf(
          id: id,
          width: cardWidth,
          count: count,
          buildCard: buildCard,
        ),
      );
    },
  );
}

class _ScrollableShelf extends StatefulWidget {
  const _ScrollableShelf({
    required this.id,
    required this.width,
    required this.count,
    required this.buildCard,
  });
  final String id;
  final double width;
  final int count;
  final Widget Function(int, double) buildCard;

  @override
  State<_ScrollableShelf> createState() => _ScrollableShelfState();
}

class _ScrollableShelfState extends State<_ScrollableShelf> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int direction) {
    final position = _controller.position;
    _controller.jumpTo(
      (position.pixels + direction * widget.width).clamp(
        0.0,
        position.maxScrollExtent,
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    // Trackpad horizontal deltas stay precise; vertical wheel input maps to
    // this row only while it can move. At an edge, the page keeps the event.
    final delta = event.scrollDelta.dx == 0
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (delta == 0) return;
    final position = _controller.position;
    final target = (position.pixels + delta).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (!_controller.hasClients) return;
      final latest = _controller.position;
      final next = (latest.pixels + delta).clamp(0.0, latest.maxScrollExtent);
      if (next == latest.pixels) return;
      if (event.scrollDelta.dx != 0) {
        _controller.jumpTo(next);
      } else {
        _controller.animateTo(
          next,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Listener(
        onPointerSignal: _handlePointerSignal,
        child: Stack(
          children: [
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: ListView.separated(
                key: PageStorageKey(widget.id),
                restorationId: widget.id,
                controller: _controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: widget.count,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: widget.width,
                  child: widget.buildCard(index, widget.width),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _move(-1),
                    tooltip: 'Anteriores',
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    onPressed: () => _move(1),
                    tooltip: 'Siguientes',
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.episode,
    required this.width,
    required this.onResume,
    required this.onDetails,
    required this.onLibraryAction,
  });

  final HomeEpisode episode;
  final double width;
  final ValueChanged<HomeEpisode>? onResume;
  final ValueChanged<HomeTitle> onDetails;
  final Future<void> Function(HomeTitle, HomeCardLibraryCommand)
  onLibraryAction;

  @override
  Widget build(BuildContext context) {
    final remaining = episode.durationMs == null
        ? null
        : episode.durationMs! - episode.positionMs;
    return _ArtworkCard(
      anime: episode.anime,
      width: width,
      ratio: 16 / 9,
      onPressed: () => onResume?.call(episode),
      episode: episode,
      onDetails: () => onDetails(episode.anime),
      onLibraryAction: onLibraryAction,
      subtitle:
          '${episode.label}\n'
          '${remaining == null ? '${_time(episode.positionMs)} visto' : '${_time(remaining)} restantes'}',
    );
  }
}

String _time(int ms) {
  final seconds = ms ~/ 1000;
  final hours = seconds ~/ 3600;
  final minutes = hours == 0 ? seconds ~/ 60 : seconds ~/ 60 % 60;
  final tail = (seconds % 60).toString().padLeft(2, '0');
  return hours == 0
      ? '$minutes:$tail'
      : '$hours:${minutes.toString().padLeft(2, '0')}:$tail';
}

class _ArtworkCard extends StatefulWidget {
  const _ArtworkCard({
    required this.anime,
    required this.width,
    required this.ratio,
    required this.onPressed,
    required this.onDetails,
    required this.onLibraryAction,
    this.episode,
    this.subtitle,
    this.imageUrl,
  });

  final HomeTitle anime;
  final double width;
  final double ratio;
  final VoidCallback onPressed;
  final VoidCallback onDetails;
  final Future<void> Function(HomeTitle, HomeCardLibraryCommand)
  onLibraryAction;
  final HomeEpisode? episode;
  final String? subtitle;
  final String? imageUrl;

  @override
  State<_ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<_ArtworkCard> {
  bool _hovered = false;
  bool _focused = false;
  final FocusNode _optionsFocusNode = FocusNode(
    debugLabel: 'home-card-options',
  );
  final GlobalKey _optionsKey = GlobalKey(
    debugLabel: 'home-card-options-anchor',
  );

  @override
  void dispose() {
    _optionsFocusNode.dispose();
    super.dispose();
  }

  bool get _tv =>
      Theme.of(context).platform == TargetPlatform.android &&
      MediaQuery.of(context).navigationMode == NavigationMode.directional;

  bool get _androidTouch =>
      Theme.of(context).platform == TargetPlatform.android && !_tv;

  bool get _desktop => !_androidTouch && !_tv;

  Future<void> _showMenuAt(
    Offset globalPosition, {
    required bool touch,
    required bool includeDetails,
  }) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final localPosition = overlay.globalToLocal(globalPosition);
    final position = RelativeRect.fromLTRB(
      localPosition.dx,
      localPosition.dy,
      overlay.size.width - localPosition.dx,
      overlay.size.height - localPosition.dy,
    );
    final command = await showHomeCardLibraryMenu(
      context: context,
      title: widget.anime,
      touch: touch,
      includeDetails: includeDetails,
      position: position,
    );
    if (!mounted) return;
    if (command != null) await widget.onLibraryAction(widget.anime, command);
    if (mounted && _tv) _optionsFocusNode.requestFocus();
  }

  Future<void> _showLibraryOptions() async {
    final button = _optionsKey.currentContext!.findRenderObject()! as RenderBox;
    final globalPosition = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
    );
    await _showMenuAt(
      globalPosition,
      touch: _androidTouch,
      includeDetails: true,
    );
  }

  void _handleSecondaryTap(TapDownDetails details) {
    if (!_desktop) return;
    _showMenuAt(details.globalPosition, touch: false, includeDetails: true);
  }

  void _handleFocusChange(bool value) {
    setState(() => _focused = value);
    if (!value || !_tv || !showLibraryActions) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focused && _optionsFocusNode.canRequestFocus) {
        _optionsFocusNode.requestFocus();
      }
    });
  }

  bool get showLibraryActions => true;

  @override
  Widget build(BuildContext context) {
    final colors = HomeAppearance.of(context);
    final showOverlay =
        _androidTouch || (_tv ? _focused : _hovered || _focused);
    final showDetails = !_androidTouch && !_tv;
    final showLibraryOptions = showLibraryActions;
    return Tooltip(
      message: widget.episode == null
          ? widget.anime.title
          : 'Continuar · ${widget.anime.title}',
      child: Focus(
        onFocusChange: _handleFocusChange,
        child: MouseRegion(
          onEnter: (_) {
            if (!_androidTouch && !_tv) setState(() => _hovered = true);
          },
          onExit: (_) {
            if (!_androidTouch && !_tv) setState(() => _hovered = false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: _handleSecondaryTap,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onPressed,
                focusColor: colors.accent.withValues(alpha: .22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: widget.ratio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(
                              child: ClipRect(
                                child: AnimatedScale(
                                  scale: _desktop && _hovered ? 1.035 : 1,
                                  duration: colors.lite
                                      ? Duration.zero
                                      : const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  child: HomeArtwork(
                                    asset: null,
                                    url:
                                        widget.imageUrl ??
                                        widget.anime.coverUrl,
                                    width: widget.width,
                                    alignment: widget.episode == null
                                        ? Alignment.center
                                        : const Alignment(0, -.42),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.anime.score case final score?)
                              Positioned(
                                top: 7,
                                left: 7,
                                child: HomeScoreBadge(score: score),
                              ),
                            if (widget.episode != null) ...[
                              if (widget.episode!.fraction case final fraction?)
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    color: colors.accent,
                                    backgroundColor: const Color(0xb3000000),
                                  ),
                                ),
                            ],
                            if (_tv && _focused)
                              IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: colors.accent,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: AnimatedOpacity(
                                key: ValueKey(
                                  'home-card-overlay-${widget.anime.title}',
                                ),
                                opacity: showOverlay ? 1 : 0,
                                duration: colors.lite
                                    ? Duration.zero
                                    : const Duration(milliseconds: 130),
                                curve: Curves.easeOut,
                                child: IgnorePointer(
                                  ignoring: !showOverlay,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showDetails)
                                        _CardActionButton(
                                          tooltip: 'Details',
                                          icon: HomeIcons.resolve(
                                            HomeAction.details,
                                          ),
                                          surface: colors.cardActionOverlay,
                                          radius: colors.cardActionRadius,
                                          touchSized: false,
                                          onPressed: widget.onDetails,
                                        ),
                                      if (showDetails && showLibraryOptions)
                                        const SizedBox(width: 6),
                                      if (showLibraryOptions)
                                        _CardActionButton(
                                          anchorKey: _optionsKey,
                                          focusNode: _optionsFocusNode,
                                          tooltip: _androidTouch || _tv
                                              ? 'More actions'
                                              : 'Card actions',
                                          icon: HomeIcons.resolve(
                                            HomeAction.more,
                                          ),
                                          surface: colors.cardActionOverlay,
                                          radius: colors.cardActionRadius,
                                          touchSized: _androidTouch || _tv,
                                          onPressed: _showLibraryOptions,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(3, 7, 3, 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.anime.title,
                            maxLines: widget.episode == null ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeTypography.cardTitle(colors),
                          ),
                          if (widget.subtitle case final label?)
                            Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xffbebbc9)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.tooltip,
    required this.icon,
    required this.surface,
    required this.radius,
    required this.touchSized,
    required this.onPressed,
    this.focusNode,
    this.anchorKey,
  });

  final String tooltip;
  final IconData icon;
  final Color surface;
  final double radius;
  final bool touchSized;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final GlobalKey? anchorKey;

  @override
  Widget build(BuildContext context) => IconButton(
    key: anchorKey,
    focusNode: focusNode,
    tooltip: tooltip,
    visualDensity: VisualDensity.standard,
    constraints: touchSized
        ? const BoxConstraints(minWidth: 48, minHeight: 48)
        : const BoxConstraints.tightFor(width: 36, height: 36),
    style: IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: surface,
      hoverColor: Colors.white.withValues(alpha: .1),
      focusColor: const Color(0xffb7adff).withValues(alpha: .22),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: Colors.white.withValues(alpha: .22)),
      ),
    ),
    onPressed: onPressed,
    icon: Icon(icon, size: 17),
  );
}
