import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:material_ui/material_ui.dart';

final class AnimeDetailHeader extends StatelessWidget {
  const AnimeDetailHeader({
    required this.title,
    required this.metadata,
    required this.entry,
    required this.saving,
    required this.onBack,
    required this.onAdd,
    required this.onStatus,
    super.key,
  });

  final String title;
  final ProviderAnimeMetadata? metadata;
  final LibraryEntry? entry;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<LibraryStatus> onStatus;

  static const Color _foreground = Color(0xfff5f3f8);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool compact = constraints.maxWidth < 620;
      return SizedBox(
        key: const ValueKey('detail-cinematic-header'),
        height: compact ? 350 : 400,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (metadata?.bannerImageUrl case final String bannerUrl)
              Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                alignment: compact ? Alignment.topCenter : Alignment.center,
                cacheWidth:
                    (constraints.maxWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(320, 1800),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x14000000),
                    Color(0x3d000000),
                    Color(0xc9000000),
                    Color(0xff000000),
                  ],
                  stops: [0, .5, .83, 1],
                ),
              ),
            ),
            if (!compact)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xf7000000),
                      Color(0xd9000000),
                      Color(0x73000000),
                      Colors.transparent,
                    ],
                    stops: [0, .18, .5, .82],
                  ),
                ),
              ),
            Positioned(
              left: compact ? 12 : 26,
              top: 8,
              child: IconButton(
                key: const ValueKey('detail-back'),
                tooltip: 'Volver',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: _foreground,
              ),
            ),
            if (compact)
              _CompactHeaderComposition(
                title: title,
                metadata: metadata,
                entry: entry,
                saving: saving,
                onAdd: onAdd,
                onStatus: onStatus,
              )
            else
              _WideHeaderComposition(
                title: title,
                metadata: metadata,
                entry: entry,
                saving: saving,
                onAdd: onAdd,
                onStatus: onStatus,
              ),
          ],
        ),
      );
    },
  );
}

final class _WideHeaderComposition extends StatelessWidget {
  const _WideHeaderComposition({
    required this.title,
    required this.metadata,
    required this.entry,
    required this.saving,
    required this.onAdd,
    required this.onStatus,
  });

  final String title;
  final ProviderAnimeMetadata? metadata;
  final LibraryEntry? entry;
  final bool saving;
  final VoidCallback onAdd;
  final ValueChanged<LibraryStatus> onStatus;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 40,
    right: 38,
    top: 62,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Poster(
          key: const ValueKey('detail-poster'),
          url: metadata?.coverImageUrl,
          width: 188,
          height: 300,
        ),
        const SizedBox(width: 26),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _HeaderInfo(
              key: const ValueKey('detail-header-info'),
              title: title,
              metadata: metadata,
              entry: entry,
              compact: false,
              showSynopsis: true,
              showMoreAction: true,
              saving: saving,
              onAdd: onAdd,
              onStatus: onStatus,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _CompactHeaderComposition extends StatelessWidget {
  const _CompactHeaderComposition({
    required this.title,
    required this.metadata,
    required this.entry,
    required this.saving,
    required this.onAdd,
    required this.onStatus,
  });

  final String title;
  final ProviderAnimeMetadata? metadata;
  final LibraryEntry? entry;
  final bool saving;
  final VoidCallback onAdd;
  final ValueChanged<LibraryStatus> onStatus;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned(
        right: 14,
        top: 10,
        child: _ActionButton(
          key: const ValueKey('detail-more-actions'),
          label: 'Más',
          icon: Icons.more_horiz_rounded,
          enabled: false,
          onPressed: () {},
          circular: true,
          minimumExtent: 48,
        ),
      ),
      Positioned(
        left: 18,
        top: 94,
        child: _Poster(
          key: const ValueKey('detail-poster'),
          url: metadata?.coverImageUrl,
          width: 96,
          height: 154,
        ),
      ),
      Positioned(
        left: 128,
        right: 16,
        top: 96,
        bottom: 70,
        child: FittedBox(
          alignment: Alignment.topLeft,
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 246,
            child: _HeaderInfo(
              key: const ValueKey('detail-header-info'),
              title: title,
              metadata: metadata,
              entry: entry,
              compact: true,
              showSynopsis: false,
              showMoreAction: false,
              saving: saving,
              onAdd: onAdd,
              onStatus: onStatus,
            ),
          ),
        ),
      ),
      if (metadata?.synopsis case final String synopsis)
        Positioned(
          left: 18,
          right: 18,
          top: 286,
          child: Text(
            synopsis,
            key: const ValueKey('detail-header-synopsis'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xffdfdbe3),
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
    ],
  );
}

final class _Poster extends StatelessWidget {
  const _Poster({
    required this.url,
    required this.width,
    required this.height,
    super.key,
  });
  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: width,
      height: height,
      child: url == null
          ? const ColoredBox(color: Color(0xff101014))
          : Image.network(
              url!,
              fit: BoxFit.cover,
              cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(96, 600),
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xff101014),
                child: Icon(Icons.image_not_supported_outlined),
              ),
            ),
    ),
  );
}

final class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({
    required this.title,
    required this.metadata,
    required this.entry,
    required this.compact,
    required this.showSynopsis,
    required this.showMoreAction,
    required this.saving,
    required this.onAdd,
    required this.onStatus,
    super.key,
  });

  final String title;
  final ProviderAnimeMetadata? metadata;
  final LibraryEntry? entry;
  final bool compact;
  final bool showSynopsis;
  final bool showMoreAction;
  final bool saving;
  final VoidCallback onAdd;
  final ValueChanged<LibraryStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double titleSize = compact ? 23 : 37;
    final String? subtitle = metadata?.romajiTitle;
    final List<Widget> details = [
      _Pill(_formatLabel(metadata?.format)),
      if (metadata?.releaseYear != null) _Pill(_yearRange(metadata!)),
      if (metadata?.averageScore case final int score)
        _Pill('★  $score%', accent: const Color(0xffffc83d)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 7, runSpacing: 6, children: details),
        const SizedBox(height: 9),
        Text(
          title,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: const Color(0xfff5f3f8),
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            height: 1.05,
            letterSpacing: -.55,
          ),
        ),
        if (subtitle != null && subtitle != title) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xffd2ced7),
            ),
          ),
        ],
        if (metadata?.genres.isNotEmpty ?? false) ...[
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: metadata!.genres
                .take(compact ? 2 : 4)
                .map((String genre) => _GenrePill(genre))
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ActionButton(
              key: const ValueKey('detail-play-disabled'),
              label: 'Reproducir',
              icon: Icons.play_arrow_rounded,
              enabled: false,
              filled: true,
              onPressed: () {},
              minimumExtent: compact ? 48 : 42,
            ),
            if (entry == null && metadata != null)
              _ActionButton(
                key: const ValueKey('add-to-library'),
                label: saving
                    ? 'Guardando'
                    : compact
                    ? 'Añadir'
                    : 'Añadir a mi biblioteca',
                icon: Icons.add_rounded,
                enabled: !saving,
                onPressed: onAdd,
                minimumExtent: compact ? 48 : 42,
              )
            else if (entry != null)
              _LibraryStatusButton(status: entry!.status, onSelected: onStatus),
            Tooltip(
              message: 'Las descargas todavía no están disponibles',
              child: _ActionButton(
                label: 'Descargar',
                icon: Icons.download_outlined,
                enabled: false,
                onPressed: () {},
                circular: true,
                minimumExtent: compact ? 48 : 42,
              ),
            ),
            if (showMoreAction)
              _ActionButton(
                key: const ValueKey('detail-more-actions'),
                label: 'Más',
                icon: Icons.more_horiz_rounded,
                enabled: false,
                onPressed: () {},
                circular: true,
              ),
          ],
        ),
        if (showSynopsis && metadata?.synopsis != null) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Text(
              metadata!.synopsis!,
              key: const ValueKey('detail-header-synopsis'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xffdfdbe3),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

final class _GenrePill extends StatelessWidget {
  const _GenrePill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xb51a191e),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xffeeebf0),
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}

final class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.accent});
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xb517171c),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x3fffffff)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: accent ?? const Color(0xfff1eff4),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

final class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.filled = false,
    this.circular = false,
    this.minimumExtent = 42,
    super.key,
  });
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final bool filled;
  final bool circular;
  final double minimumExtent;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xffb829ff);
    final Color foreground = enabled ? Colors.white : const Color(0xff77737c);
    return Tooltip(
      message: label,
      child: Material(
        color: filled
            ? accent.withValues(alpha: enabled ? 1 : .16)
            : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const StadiumBorder(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: minimumExtent,
              minWidth: circular ? minimumExtent : 0,
            ),
            padding: EdgeInsets.symmetric(horizontal: circular ? 10 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: filled
                  ? null
                  : Border.all(color: const Color(0x80ffffff)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: foreground),
                if (!circular) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(color: foreground, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _LibraryStatusButton extends StatelessWidget {
  const _LibraryStatusButton({required this.status, required this.onSelected});
  final LibraryStatus status;
  final ValueChanged<LibraryStatus> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<LibraryStatus>(
    key: const ValueKey('detail-library-status'),
    tooltip: 'Estado de biblioteca',
    initialValue: status,
    color: const Color(0xff101013),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xff39363f)),
    ),
    onSelected: onSelected,
    itemBuilder: (BuildContext context) => LibraryStatus.values
        .map(
          (LibraryStatus value) => PopupMenuItem<LibraryStatus>(
            value: value,
            child: Row(
              children: [
                if (value == status)
                  const Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: Color(0xffcd8cff),
                  )
                else
                  const SizedBox(width: 17),
                const SizedBox(width: 9),
                Text(_libraryStatusLabel(value)),
              ],
            ),
          ),
        )
        .toList(growable: false),
    child: Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x80ffffff)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 18, color: Color(0xffe8d3ff)),
          const SizedBox(width: 6),
          Text(
            _libraryStatusLabel(status),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded, size: 18, color: Colors.white),
        ],
      ),
    ),
  );
}

String _libraryStatusLabel(LibraryStatus status) => switch (status) {
  LibraryStatus.planned => 'Por ver',
  LibraryStatus.watching => 'Viendo',
  LibraryStatus.rewatching => 'Reviendo',
  LibraryStatus.paused => 'Pausados',
  LibraryStatus.completed => 'Completados',
  LibraryStatus.abandoned => 'Abandonados',
};

String _formatLabel(AnimeFormat? format) => switch (format) {
  AnimeFormat.tv => 'TV',
  AnimeFormat.movie => 'Película',
  AnimeFormat.ova => 'OVA',
  AnimeFormat.ona => 'ONA',
  AnimeFormat.special => 'Especial',
  AnimeFormat.manga => 'Manga',
  AnimeFormat.unknown || null => 'Anime',
};

String _yearRange(ProviderAnimeMetadata metadata) {
  final int start = metadata.releaseYear!;
  final int? end = metadata.endYear;
  return end == null || end == start ? '$start' : '$start – $end';
}
