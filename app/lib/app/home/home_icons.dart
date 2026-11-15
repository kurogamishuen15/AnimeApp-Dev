import 'package:material_ui/material_ui.dart';

enum HomeAction {
  home,
  search,
  calendar,
  discover,
  library,
  settings,
  profile,
  details,
  more,
  bookmarkAdd,
  planned,
  watching,
  rewatching,
  paused,
  completed,
  abandoned,
  selected,
}

/// Stable semantic icon identities. A user selected pack can replace the map.
abstract final class HomeIcons {
  static const Map<HomeAction, IconData> minimal = {
    HomeAction.home: Icons.home_outlined,
    HomeAction.search: Icons.search_outlined,
    HomeAction.calendar: Icons.calendar_today_outlined,
    HomeAction.discover: Icons.explore_outlined,
    HomeAction.library: Icons.auto_stories_outlined,
    HomeAction.settings: Icons.settings_outlined,
    HomeAction.profile: Icons.account_circle_outlined,
    HomeAction.details: Icons.info_outline,
    HomeAction.more: Icons.more_vert,
    HomeAction.bookmarkAdd: Icons.bookmark_add_outlined,
    HomeAction.planned: Icons.bookmark_outline,
    HomeAction.watching: Icons.play_circle_outline,
    HomeAction.rewatching: Icons.replay_outlined,
    HomeAction.paused: Icons.pause_circle_outline,
    HomeAction.completed: Icons.check_circle_outline,
    HomeAction.abandoned: Icons.remove_circle_outline,
    HomeAction.selected: Icons.check,
  };

  static IconData resolve(HomeAction action) => minimal[action]!;
}
