import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/catalog/library_entry.dart';
import 'home_data.dart';
import 'home_icons.dart';

/// Commands shared by pointer, keyboard, remote and touch presentations.
final class HomeCardLibraryCommand {
  const HomeCardLibraryCommand.details()
    : details = true,
      add = false,
      remove = false,
      copyLink = false,
      status = null;
  const HomeCardLibraryCommand.add()
    : details = false,
      add = true,
      remove = false,
      copyLink = false,
      status = null;
  const HomeCardLibraryCommand.set(this.status)
    : details = false,
      add = false,
      remove = false,
      copyLink = false;
  const HomeCardLibraryCommand.remove()
    : details = false,
      add = false,
      remove = true,
      copyLink = false,
      status = null;
  const HomeCardLibraryCommand.copyLink()
    : details = false,
      add = false,
      remove = false,
      copyLink = true,
      status = null;

  final bool details;
  final bool add;
  final bool remove;
  final bool copyLink;
  final LibraryStatus? status;
}

/// Shared permissions and labels for card actions. Playback is offered only
/// when Home receives an actual playable source from a provider.
abstract final class HomeCardActionPolicy {
  static const _orderedStatuses = [
    LibraryStatus.watching,
    LibraryStatus.planned,
    LibraryStatus.rewatching,
    LibraryStatus.paused,
    LibraryStatus.completed,
    LibraryStatus.abandoned,
  ];

  static List<HomeCardLibraryCommand> libraryCommands(HomeTitle title) =>
      title.animeId != null
      ? _orderedStatuses.map(HomeCardLibraryCommand.set).toList(growable: false)
      : title.externalId != null
      ? const [HomeCardLibraryCommand.add()]
      : const [];

  static List<HomeCardLibraryCommand> menuCommands(
    HomeTitle title, {
    required bool includeDetails,
  }) => [
    if (includeDetails) const HomeCardLibraryCommand.details(),
    ...libraryCommands(title),
    if (title.animeId != null) const HomeCardLibraryCommand.remove(),
    if (linkFor(title) != null) const HomeCardLibraryCommand.copyLink(),
  ];

  static Uri? linkFor(HomeTitle title) {
    final id = title.externalId;
    if (id == null || id.providerId.value != 'anilist') return null;
    if (!RegExp(r'^\d+$').hasMatch(id.value)) return null;
    return Uri.https('anilist.co', '/anime/${id.value}');
  }

  static bool isSelected(HomeTitle title, HomeCardLibraryCommand command) =>
      command.status != null && command.status == title.libraryStatus;

  static String statusLabel(LibraryStatus status) => switch (status) {
    LibraryStatus.planned => 'Plan to watch',
    LibraryStatus.watching => 'Watching',
    LibraryStatus.rewatching => 'Rewatching',
    LibraryStatus.paused => 'Paused',
    LibraryStatus.completed => 'Completed',
    LibraryStatus.abandoned => 'Dropped',
  };

  static String commandLabel(HomeCardLibraryCommand command) => command.details
      ? 'Details'
      : command.add
      ? 'Plan to watch'
      : command.remove
      ? 'Remove from list'
      : command.copyLink
      ? 'Copy link'
      : statusLabel(command.status!);
}

/// One menu contract rendered as a refined desktop/TV menu or mobile sheet.
Future<HomeCardLibraryCommand?> showHomeCardLibraryMenu({
  required BuildContext context,
  required HomeTitle title,
  required bool touch,
  required bool includeDetails,
  required RelativeRect position,
}) {
  final commands = HomeCardActionPolicy.menuCommands(
    title,
    includeDetails: includeDetails,
  );
  if (touch) {
    return showModalBottomSheet<HomeCardLibraryCommand>(
      context: context,
      backgroundColor: const Color(0xff151515),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (includeDetails)
                _TouchMenuItem(
                  command: const HomeCardLibraryCommand.details(),
                  title: title,
                ),
              if (commands.any((command) => command.status != null)) ...[
                const _TouchMenuDivider(),
                const _TouchMenuHeading('Move in Kongroo'),
              ],
              for (final command in commands.where(
                (command) =>
                    !command.details && !command.remove && !command.copyLink,
              ))
                _TouchMenuItem(command: command, title: title),
              if (commands.any((command) => command.remove)) ...[
                const _TouchMenuDivider(),
                _TouchMenuItem(
                  command: const HomeCardLibraryCommand.remove(),
                  title: title,
                  destructive: true,
                ),
              ],
              if (commands.any((command) => command.copyLink)) ...[
                const _TouchMenuDivider(),
                _TouchMenuItem(
                  command: const HomeCardLibraryCommand.copyLink(),
                  title: title,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  final states = commands.where(
    (command) => (!command.details && command.status != null) || command.add,
  );
  final hasRemove = commands.any((command) => command.remove);
  final hasCopy = commands.any((command) => command.copyLink);
  final scale =
      38.0 +
      (includeDetails ? 42 : 0) +
      (states.isNotEmpty ? 30 + states.length * 36 + 8 : 0) +
      (hasRemove ? 44 : 0) +
      (hasCopy ? 44 : 0);
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final width = math.min(272.0, overlay.size.width - 16).toDouble();
  final height = math.min(scale, overlay.size.height - 16).toDouble();
  final left = position.left
      .clamp(8.0, math.max(8.0, overlay.size.width - width - 8))
      .toDouble();
  final top = position.top
      .clamp(8.0, math.max(8.0, overlay.size.height - height - 8))
      .toDouble();

  return showGeneralDialog<HomeCardLibraryCommand>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close card actions',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 145),
    pageBuilder: (dialogContext, _, _) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(dialogContext).pop(),
      },
      child: FocusTraversalGroup(
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: _DesktopActionMenu(
                width: width,
                maxHeight: height,
                title: title,
                includeDetails: includeDetails,
                states: states.toList(growable: false),
                hasRemove: hasRemove,
                hasCopy: hasCopy,
              ),
            ),
          ],
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        alignment: Alignment.topLeft,
        scale: Tween<double>(begin: .97, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

class _DesktopActionMenu extends StatelessWidget {
  const _DesktopActionMenu({
    required this.width,
    required this.maxHeight,
    required this.title,
    required this.includeDetails,
    required this.states,
    required this.hasRemove,
    required this.hasCopy,
  });

  final double width;
  final double maxHeight;
  final HomeTitle title;
  final bool includeDetails;
  final List<HomeCardLibraryCommand> states;
  final bool hasRemove;
  final bool hasCopy;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xf20d0d0f),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x30ffffff)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                  child: Text(
                    title.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .05,
                      color: Color(0xffbcbcc2),
                    ),
                  ),
                ),
                if (includeDetails)
                  _DesktopActionRow(
                    command: const HomeCardLibraryCommand.details(),
                    title: title,
                    autofocus: true,
                  ),
                if (states.isNotEmpty) ...[
                  if (includeDetails) const _DesktopMenuDivider(),
                  const _DesktopMenuHeading('Move in Kongroo'),
                  for (final command in states)
                    _DesktopActionRow(command: command, title: title),
                ],
                if (hasRemove) ...[
                  const _DesktopMenuDivider(),
                  _DesktopActionRow(
                    command: const HomeCardLibraryCommand.remove(),
                    title: title,
                    destructive: true,
                    autofocus: !includeDetails && states.isEmpty,
                  ),
                ],
                if (hasCopy) ...[
                  const _DesktopMenuDivider(),
                  _DesktopActionRow(
                    command: const HomeCardLibraryCommand.copyLink(),
                    title: title,
                    autofocus: !includeDetails && states.isEmpty && !hasRemove,
                  ),
                ],
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DesktopActionRow extends StatelessWidget {
  const _DesktopActionRow({
    required this.command,
    required this.title,
    this.destructive = false,
    this.autofocus = false,
  });

  final HomeCardLibraryCommand command;
  final HomeTitle title;
  final bool destructive;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final selected = HomeCardActionPolicy.isSelected(title, command);
    final color = destructive
        ? const Color(0xffff7479)
        : const Color(0xffeeedf1);
    return Focus(
      autofocus: autofocus,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(command),
        hoverColor: const Color(0x16ffffff),
        focusColor: const Color(0x1effffff),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(_commandIcon(command), size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    HomeCardActionPolicy.commandLabel(command),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -.08,
                      color: color,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, size: 15, color: Color(0xfff3f2f5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopMenuHeading extends StatelessWidget {
  const _DesktopMenuHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 7, 12, 3),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: .1,
        color: Color(0xff929299),
      ),
    ),
  );
}

class _DesktopMenuDivider extends StatelessWidget {
  const _DesktopMenuDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 10),
    child: Divider(height: 4, thickness: 1, color: Color(0x20ffffff)),
  );
}

class _TouchMenuItem extends StatelessWidget {
  const _TouchMenuItem({
    required this.command,
    required this.title,
    this.destructive = false,
  });
  final HomeCardLibraryCommand command;
  final HomeTitle title;
  final bool destructive;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      _commandIcon(command),
      color: destructive ? const Color(0xffff5d62) : null,
    ),
    title: Text(
      HomeCardActionPolicy.commandLabel(command),
      style: TextStyle(color: destructive ? const Color(0xffff5d62) : null),
    ),
    trailing: HomeCardActionPolicy.isSelected(title, command)
        ? const Icon(Icons.check, size: 18)
        : null,
    onTap: () => Navigator.pop(context, command),
  );
}

class _TouchMenuHeading extends StatelessWidget {
  const _TouchMenuHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: const Color(0xffa8a8aa), letterSpacing: .25),
      ),
    ),
  );
}

class _TouchMenuDivider extends StatelessWidget {
  const _TouchMenuDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: Color(0xff2c2c2e)),
  );
}

IconData _commandIcon(HomeCardLibraryCommand command) {
  if (command.details) return HomeIcons.resolve(HomeAction.details);
  if (command.add) return HomeIcons.resolve(HomeAction.planned);
  if (command.remove) return Icons.delete_outline;
  if (command.copyLink) return Icons.link;
  return _statusIcon(command.status!);
}

IconData _statusIcon(LibraryStatus status) =>
    HomeIcons.resolve(switch (status) {
      LibraryStatus.planned => HomeAction.planned,
      LibraryStatus.watching => HomeAction.watching,
      LibraryStatus.rewatching => HomeAction.rewatching,
      LibraryStatus.paused => HomeAction.paused,
      LibraryStatus.completed => HomeAction.completed,
      LibraryStatus.abandoned => HomeAction.abandoned,
    });
