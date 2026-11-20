# Registro de contratos

IDs estables en esta captura; los fragmentos multilínea se interpretan con el archivo fuente completo.

| ID | Tipo | Archivo:línea | Declaración / expresión |
| --- | --- | --- | --- |
| S0001 | símbolo | app/lib/app/anime_app.dart:9 | class AnimeApp extends StatefulWidget |
| S0002 | símbolo | app/lib/app/anime_app.dart:10 | const AnimeApp({ required this.catalogService, this.playbackModule, super.key, }) |
| S0003 | símbolo | app/lib/app/anime_app.dart:16 | catalogService |
| S0004 | símbolo | app/lib/app/anime_app.dart:17 | playbackModule |
| S0005 | símbolo | app/lib/app/anime_app.dart:19 | @override State<AnimeApp> createState() |
| S0006 | símbolo | app/lib/app/catalog/anime_detail_page.dart:18 | final class AnimeDetailPage extends StatefulWidget |
| S0007 | símbolo | app/lib/app/catalog/anime_detail_page.dart:19 | const AnimeDetailPage({ required this.service, required this.fallbackTitle, required this.onBack, this.onPlaybackRequested, this.externalId, this.existingAnimeId, this.initialMetadata, super.key, }) |
| S0008 | símbolo | app/lib/app/catalog/anime_detail_page.dart:30 | service |
| S0009 | símbolo | app/lib/app/catalog/anime_detail_page.dart:31 | fallbackTitle |
| S0010 | símbolo | app/lib/app/catalog/anime_detail_page.dart:32 | onBack |
| S0011 | símbolo | app/lib/app/catalog/anime_detail_page.dart:33 | onPlaybackRequested |
| S0012 | símbolo | app/lib/app/catalog/anime_detail_page.dart:34 | externalId |
| S0013 | símbolo | app/lib/app/catalog/anime_detail_page.dart:35 | existingAnimeId |
| S0014 | símbolo | app/lib/app/catalog/anime_detail_page.dart:36 | initialMetadata |
| S0015 | símbolo | app/lib/app/catalog/anime_detail_page.dart:38 | @override State<AnimeDetailPage> createState() |
| S0016 | símbolo | app/lib/app/catalog/catalog_home_page.dart:34 | final class CatalogHomePage extends StatefulWidget |
| S0017 | símbolo | app/lib/app/catalog/catalog_home_page.dart:35 | const CatalogHomePage({ required this.service, this.playbackProviders, super.key, }) |
| S0018 | símbolo | app/lib/app/catalog/catalog_home_page.dart:41 | service |
| S0019 | símbolo | app/lib/app/catalog/catalog_home_page.dart:42 | playbackProviders |
| S0020 | símbolo | app/lib/app/catalog/catalog_home_page.dart:44 | @override State<CatalogHomePage> createState() |
| S0021 | símbolo | app/lib/app/catalog/catalog_module.dart:17 | /// Linux-first composition for the offline catalog walkthrough. final class CatalogModule |
| S0022 | símbolo | app/lib/app/catalog/catalog_module.dart:26 | database |
| S0023 | símbolo | app/lib/app/catalog/catalog_module.dart:27 | service |
| S0024 | símbolo | app/lib/app/catalog/catalog_module.dart:28 | anilistClient |
| S0025 | símbolo | app/lib/app/catalog/catalog_module.dart:29 | demoProvider |
| S0026 | símbolo | app/lib/app/catalog/catalog_module.dart:31 | static Future<CatalogModule> open({ File? databaseFile, DateTime Function()? clock, bool useDemoProvider = false, EpisodeIndexProvider? episodeIndex, }) |
| S0027 | símbolo | app/lib/app/catalog/catalog_module.dart:75 | Future<void> close() |
| S0028 | símbolo | app/lib/app/catalog/catalog_search_page.dart:6 | final class CatalogSearchPage extends StatefulWidget |
| S0029 | símbolo | app/lib/app/catalog/catalog_search_page.dart:7 | const CatalogSearchPage({ required this.service, required this.onOpenDetails, super.key, }) |
| S0030 | símbolo | app/lib/app/catalog/catalog_search_page.dart:13 | service |
| S0031 | símbolo | app/lib/app/catalog/catalog_search_page.dart:14 | onOpenDetails |
| S0032 | símbolo | app/lib/app/catalog/catalog_search_page.dart:16 | @override State<CatalogSearchPage> createState() |
| S0033 | símbolo | app/lib/app/catalog/confirm_completed_status.dart:3 | /// Completion remains a user-confirmed choice because the app does not yet /// track every episode watched for a title. Future<bool> confirmCompletedStatus(BuildContext context) |
| S0034 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:5 | final class AnimeDetailHeader extends StatelessWidget |
| S0035 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:6 | const AnimeDetailHeader({ required this.title, required this.metadata, required this.entry, required this.saving, required this.onBack, required this.onAdd, required this.onStatus, super.key, }) |
| S0036 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:17 | title |
| S0037 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:18 | metadata |
| S0038 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:19 | entry |
| S0039 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:20 | saving |
| S0040 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:21 | onBack |
| S0041 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:22 | onAdd |
| S0042 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:23 | onStatus |
| S0043 | símbolo | app/lib/app/catalog/detail/anime_detail_header.dart:27 | @override Widget build(BuildContext context) |
| S0044 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:9 | final class AnimeDetailTabContent extends StatelessWidget |
| S0045 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:10 | const AnimeDetailTabContent({ required this.tab, required this.metadata, required this.progress, required this.canSaveProgress, required this.positionController, required this.saving, required this.error, required this.onSaveProgress, this.onCopyExternalEpisodeLink, this.onPlayEpisode, this.episodeIndex, this.episodeIndexLoading = false, this.episodeIndexError, this.onLoadMoreEpisodes, super.key, }) |
| S0046 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:28 | tab |
| S0047 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:29 | metadata |
| S0048 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:30 | progress |
| S0049 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:31 | canSaveProgress |
| S0050 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:32 | positionController |
| S0051 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:33 | saving |
| S0052 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:34 | error |
| S0053 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:35 | onSaveProgress |
| S0054 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:36 | onCopyExternalEpisodeLink |
| S0055 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:37 | onPlayEpisode |
| S0056 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:38 | episodeIndex |
| S0057 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:39 | episodeIndexLoading |
| S0058 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:40 | episodeIndexError |
| S0059 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:41 | onLoadMoreEpisodes |
| S0060 | símbolo | app/lib/app/catalog/detail/anime_detail_tab_content.dart:43 | @override Widget build(BuildContext context) |
| S0061 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:3 | enum AnimeDetailTab |
| S0062 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:4 | episodes('Episodios') |
| S0063 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:5 | information('Información') |
| S0064 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:6 | cast('Reparto') |
| S0065 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:7 | gallery('Galería') |
| S0066 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:8 | titles('Títulos alternativos') |
| S0067 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:9 | links('Enlaces') |
| S0068 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:11 | const AnimeDetailTab(this.label) |
| S0069 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:12 | label |
| S0070 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:15 | final class AnimeDetailTabs extends StatelessWidget |
| S0071 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:16 | const AnimeDetailTabs({ required this.selected, required this.onSelected, super.key, }) |
| S0072 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:22 | selected |
| S0073 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:23 | onSelected |
| S0074 | símbolo | app/lib/app/catalog/detail/anime_detail_tabs.dart:25 | @override Widget build(BuildContext context) |
| S0075 | símbolo | app/lib/app/catalog/local_library_page.dart:8 | final class LocalLibraryPage extends StatefulWidget |
| S0076 | símbolo | app/lib/app/catalog/local_library_page.dart:9 | const LocalLibraryPage({ required this.service, required this.onOpenDetails, this.refreshRevision = 0, super.key, }) |
| S0077 | símbolo | app/lib/app/catalog/local_library_page.dart:16 | service |
| S0078 | símbolo | app/lib/app/catalog/local_library_page.dart:17 | onOpenDetails |
| S0079 | símbolo | app/lib/app/catalog/local_library_page.dart:18 | refreshRevision |
| S0080 | símbolo | app/lib/app/catalog/local_library_page.dart:20 | @override State<LocalLibraryPage> createState() |
| S0081 | símbolo | app/lib/app/catalog/playback_resolution_message.dart:4 | /// User-safe explanation for a playback lookup that produced no candidates. /// /// Provider URLs, response bodies and transport exceptions stay in the data /// boundary and are never copied into UI messages. String? playbackResolutionMessage( PlaybackProviderResult<List<ResolvedPlaybackStream>> result, ) |
| S0082 | símbolo | app/lib/app/home/home_appearance.dart:3 | final class HomeAppearance extends ThemeExtension<HomeAppearance> |
| S0083 | símbolo | app/lib/app/home/home_appearance.dart:4 | const HomeAppearance({ this.lite = false, this.surface = const Color(0xff15151b), this.accent = const Color(0xffb7adff), this.cardActionOverlay = const Color(0xb822222a), this.cardActionRadius = 18, this.fontFamily, this.typeScale = 1, this.bannerAutoSlideInterval = const Duration(seconds: 6), }) |
| S0084 | símbolo | app/lib/app/home/home_appearance.dart:15 | background = Color(0xff000000) |
| S0085 | símbolo | app/lib/app/home/home_appearance.dart:16 | lite |
| S0086 | símbolo | app/lib/app/home/home_appearance.dart:17 | surface |
| S0087 | símbolo | app/lib/app/home/home_appearance.dart:18 | accent |
| S0088 | símbolo | app/lib/app/home/home_appearance.dart:19 | cardActionOverlay |
| S0089 | símbolo | app/lib/app/home/home_appearance.dart:20 | cardActionRadius |
| S0090 | símbolo | app/lib/app/home/home_appearance.dart:23 | fontFamily |
| S0091 | símbolo | app/lib/app/home/home_appearance.dart:24 | typeScale |
| S0092 | símbolo | app/lib/app/home/home_appearance.dart:25 | bannerAutoSlideInterval |
| S0093 | símbolo | app/lib/app/home/home_appearance.dart:27 | static HomeAppearance of(BuildContext context) |
| S0094 | símbolo | app/lib/app/home/home_appearance.dart:30 | @override HomeAppearance copyWith({ bool? lite, Color? surface, Color? accent, Color? cardActionOverlay, double? cardActionRadius, String? fontFamily, double? typeScale, Duration? bannerAutoSlideInterval, }) |
| S0095 | símbolo | app/lib/app/home/home_appearance.dart:52 | @override HomeAppearance lerp(HomeAppearance? other, double t) |
| S0096 | símbolo | app/lib/app/home/home_artwork.dart:6 | final class HomeArtwork extends StatelessWidget |
| S0097 | símbolo | app/lib/app/home/home_artwork.dart:7 | const HomeArtwork({ required this.asset, required this.width, this.url, this.height, this.alignment = Alignment.center, super.key, }) |
| S0098 | símbolo | app/lib/app/home/home_artwork.dart:16 | asset |
| S0099 | símbolo | app/lib/app/home/home_artwork.dart:17 | width |
| S0100 | símbolo | app/lib/app/home/home_artwork.dart:18 | height |
| S0101 | símbolo | app/lib/app/home/home_artwork.dart:19 | url |
| S0102 | símbolo | app/lib/app/home/home_artwork.dart:20 | alignment |
| S0103 | símbolo | app/lib/app/home/home_artwork.dart:22 | @override Widget build(BuildContext context) |
| S0104 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:7 | /// Counts artwork failures by kind and host. Never stores or prints the full /// URL, query string, cookies or signatures. final class HomeArtworkDiagnostics |
| S0105 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:12 | instance = HomeArtworkDiagnostics._() |
| S0106 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:17 | sink = _defaultSink |
| S0107 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:19 | Map<String, int> get counts |
| S0108 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:21 | void reportFailure(String? url, Object error) |
| S0109 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:29 | @visibleForTesting static String classify(Object error) |
| S0110 | símbolo | app/lib/app/home/home_artwork_diagnostics.dart:43 | @visibleForTesting static String safeHost(String? url) |
| S0111 | símbolo | app/lib/app/home/home_card_actions.dart:10 | /// Commands shared by pointer, keyboard, remote and touch presentations. final class HomeCardLibraryCommand |
| S0112 | símbolo | app/lib/app/home/home_card_actions.dart:12 | const HomeCardLibraryCommand.details() : details = true, add = false, remove = false, copyLink = false, status = null |
| S0113 | símbolo | app/lib/app/home/home_card_actions.dart:18 | const HomeCardLibraryCommand.add() : details = false, add = true, remove = false, copyLink = false, status = null |
| S0114 | símbolo | app/lib/app/home/home_card_actions.dart:24 | const HomeCardLibraryCommand.set(this.status) : details = false, add = false, remove = false, copyLink = false |
| S0115 | símbolo | app/lib/app/home/home_card_actions.dart:29 | const HomeCardLibraryCommand.remove() : details = false, add = false, remove = true, copyLink = false, status = null |
| S0116 | símbolo | app/lib/app/home/home_card_actions.dart:35 | const HomeCardLibraryCommand.copyLink() : details = false, add = false, remove = false, copyLink = true, status = null |
| S0117 | símbolo | app/lib/app/home/home_card_actions.dart:42 | details |
| S0118 | símbolo | app/lib/app/home/home_card_actions.dart:43 | add |
| S0119 | símbolo | app/lib/app/home/home_card_actions.dart:44 | remove |
| S0120 | símbolo | app/lib/app/home/home_card_actions.dart:45 | copyLink |
| S0121 | símbolo | app/lib/app/home/home_card_actions.dart:46 | status |
| S0122 | símbolo | app/lib/app/home/home_card_actions.dart:49 | /// Shared permissions and labels for card actions. Playback is offered only /// when Home receives an actual playable source from a provider. abstract final class HomeCardActionPolicy |
| S0123 | símbolo | app/lib/app/home/home_card_actions.dart:61 | static List<HomeCardLibraryCommand> libraryCommands(HomeTitle title) |
| S0124 | símbolo | app/lib/app/home/home_card_actions.dart:68 | static List<HomeCardLibraryCommand> menuCommands( HomeTitle title, { required bool includeDetails, }) |
| S0125 | símbolo | app/lib/app/home/home_card_actions.dart:78 | static Uri? linkFor(HomeTitle title) |
| S0126 | símbolo | app/lib/app/home/home_card_actions.dart:85 | static bool isSelected(HomeTitle title, HomeCardLibraryCommand command) |
| S0127 | símbolo | app/lib/app/home/home_card_actions.dart:88 | static String statusLabel(LibraryStatus status) |
| S0128 | símbolo | app/lib/app/home/home_card_actions.dart:97 | static String commandLabel(HomeCardLibraryCommand command) |
| S0129 | símbolo | app/lib/app/home/home_card_actions.dart:108 | /// One menu contract rendered as a refined desktop/TV menu or mobile sheet. Future<HomeCardLibraryCommand?> showHomeCardLibraryMenu({ required BuildContext context, required HomeTitle title, required bool touch, required bool includeDetails, required RelativeRect position, }) |
| S0130 | símbolo | app/lib/app/home/home_data.dart:11 | typedef HomeLoader = Future<Result<HomeContent>> Function(); |
| S0131 | símbolo | app/lib/app/home/home_data.dart:13 | final class HomeTitle |
| S0132 | símbolo | app/lib/app/home/home_data.dart:14 | const HomeTitle({ required this.title, this.externalId, this.animeId, this.libraryStatus, this.synopsis, this.coverUrl, this.bannerUrl, this.formatLabel, this.seasonLabel, this.score, this.genres = const [], this.airing = false, this.metadata, }) |
| S0133 | símbolo | app/lib/app/home/home_data.dart:30 | title |
| S0134 | símbolo | app/lib/app/home/home_data.dart:31 | externalId |
| S0135 | símbolo | app/lib/app/home/home_data.dart:32 | animeId |
| S0136 | símbolo | app/lib/app/home/home_data.dart:33 | synopsis |
| S0137 | símbolo | app/lib/app/home/home_data.dart:34 | coverUrl |
| S0138 | símbolo | app/lib/app/home/home_data.dart:35 | bannerUrl |
| S0139 | símbolo | app/lib/app/home/home_data.dart:36 | formatLabel |
| S0140 | símbolo | app/lib/app/home/home_data.dart:37 | seasonLabel |
| S0141 | símbolo | app/lib/app/home/home_data.dart:38 | score |
| S0142 | símbolo | app/lib/app/home/home_data.dart:39 | genres |
| S0143 | símbolo | app/lib/app/home/home_data.dart:40 | airing |
| S0144 | símbolo | app/lib/app/home/home_data.dart:41 | libraryStatus |
| S0145 | símbolo | app/lib/app/home/home_data.dart:42 | metadata |
| S0146 | símbolo | app/lib/app/home/home_data.dart:45 | final class HomeEpisode |
| S0147 | símbolo | app/lib/app/home/home_data.dart:46 | const HomeEpisode( this.anime, this.label, this.positionMs, this.durationMs, { this.playback, }) |
| S0148 | símbolo | app/lib/app/home/home_data.dart:54 | anime |
| S0149 | símbolo | app/lib/app/home/home_data.dart:55 | label |
| S0150 | símbolo | app/lib/app/home/home_data.dart:56 | positionMs |
| S0151 | símbolo | app/lib/app/home/home_data.dart:57 | playback |
| S0152 | símbolo | app/lib/app/home/home_data.dart:58 | durationMs |
| S0153 | símbolo | app/lib/app/home/home_data.dart:60 | double? get fraction |
| S0154 | símbolo | app/lib/app/home/home_data.dart:63 | typedef HomeShelf = ( |
| S0155 | símbolo | app/lib/app/home/home_data.dart:65 | final class HomeContent |
| S0156 | símbolo | app/lib/app/home/home_data.dart:66 | const HomeContent({ this.featured, this.highlights = const [], this.episodes = const [], this.watching = const [], this.shelves = const [], this.offline = false, }) |
| S0157 | símbolo | app/lib/app/home/home_data.dart:75 | featured |
| S0158 | símbolo | app/lib/app/home/home_data.dart:76 | highlights |
| S0159 | símbolo | app/lib/app/home/home_data.dart:77 | episodes |
| S0160 | símbolo | app/lib/app/home/home_data.dart:78 | watching |
| S0161 | símbolo | app/lib/app/home/home_data.dart:79 | shelves |
| S0162 | símbolo | app/lib/app/home/home_data.dart:80 | offline |
| S0163 | símbolo | app/lib/app/home/home_data.dart:82 | bool get isEmpty |
| S0164 | símbolo | app/lib/app/home/home_data.dart:89 | /// Joins the existing local catalog and episode-one progress contract for Home. final class CatalogHomeSource |
| S0165 | símbolo | app/lib/app/home/home_data.dart:91 | const CatalogHomeSource(this.service, {this.sectionBudget = defaultBudget}) |
| S0166 | símbolo | app/lib/app/home/home_data.dart:92 | service |
| S0167 | símbolo | app/lib/app/home/home_data.dart:93 | sectionBudget |
| S0168 | símbolo | app/lib/app/home/home_data.dart:96 | defaultBudget = Duration(seconds: 10) |
| S0169 | símbolo | app/lib/app/home/home_data.dart:98 | Future<Result<HomeContent>> load() |
| S0170 | símbolo | app/lib/app/home/home_hero.dart:11 | /// Cinematic featured banner with a lightweight, user-controlled highlight row. final class HomeHero extends StatefulWidget |
| S0171 | símbolo | app/lib/app/home/home_hero.dart:13 | const HomeHero({ required this.anime, required this.onDetails, this.highlights = const [], this.visible = true, super.key, }) |
| S0172 | símbolo | app/lib/app/home/home_hero.dart:21 | anime |
| S0173 | símbolo | app/lib/app/home/home_hero.dart:22 | highlights |
| S0174 | símbolo | app/lib/app/home/home_hero.dart:23 | visible |
| S0175 | símbolo | app/lib/app/home/home_hero.dart:24 | onDetails |
| S0176 | símbolo | app/lib/app/home/home_hero.dart:26 | @override State<HomeHero> createState() |
| S0177 | símbolo | app/lib/app/home/home_icons.dart:3 | enum HomeAction |
| S0178 | símbolo | app/lib/app/home/home_icons.dart:4 | home |
| S0179 | símbolo | app/lib/app/home/home_icons.dart:5 | search |
| S0180 | símbolo | app/lib/app/home/home_icons.dart:6 | calendar |
| S0181 | símbolo | app/lib/app/home/home_icons.dart:7 | discover |
| S0182 | símbolo | app/lib/app/home/home_icons.dart:8 | library |
| S0183 | símbolo | app/lib/app/home/home_icons.dart:9 | settings |
| S0184 | símbolo | app/lib/app/home/home_icons.dart:10 | profile |
| S0185 | símbolo | app/lib/app/home/home_icons.dart:11 | details |
| S0186 | símbolo | app/lib/app/home/home_icons.dart:12 | more |
| S0187 | símbolo | app/lib/app/home/home_icons.dart:13 | bookmarkAdd |
| S0188 | símbolo | app/lib/app/home/home_icons.dart:14 | planned |
| S0189 | símbolo | app/lib/app/home/home_icons.dart:15 | watching |
| S0190 | símbolo | app/lib/app/home/home_icons.dart:16 | rewatching |
| S0191 | símbolo | app/lib/app/home/home_icons.dart:17 | paused |
| S0192 | símbolo | app/lib/app/home/home_icons.dart:18 | completed |
| S0193 | símbolo | app/lib/app/home/home_icons.dart:19 | abandoned |
| S0194 | símbolo | app/lib/app/home/home_icons.dart:20 | selected |
| S0195 | símbolo | app/lib/app/home/home_icons.dart:23 | /// Stable semantic icon identities. A user selected pack can replace the map. abstract final class HomeIcons |
| S0196 | símbolo | app/lib/app/home/home_icons.dart:25 | minimal = { HomeAction.home: Icons.home_outlined, HomeAction.search: Icons.search_outlined, HomeAction.calendar: Icons.calendar_today_outlined, HomeAction.discover: Icons.explore_outlined, HomeAction.library: Icons.auto_stories_outlined, HomeAction.settings: Icons.settings_outlined, HomeAction.profile: Icons.account_circle_outlined, HomeAction.details: Icons.info_outline, HomeAction.more: Icons.more_vert, HomeAction.bookmarkAdd: Icons.bookmark_add_outlined, HomeAction.planned: Icons.bookmark_outline, HomeAction.watching: Icons.play_circle_outline, HomeAction.rewatching: Icons.replay_outlined, HomeAction.paused: Icons.pause_circle_outline, HomeAction.completed: Icons.check_circle_outline, HomeAction.abandoned: Icons.remove_circle_outline, HomeAction.selected: Icons.check, } |
| S0197 | símbolo | app/lib/app/home/home_icons.dart:45 | static IconData resolve(HomeAction action) |
| S0198 | símbolo | app/lib/app/home/home_score_badge.dart:5 | /// Displays provider score data without deriving or filling missing ratings. final class HomeScoreBadge extends StatelessWidget |
| S0199 | símbolo | app/lib/app/home/home_score_badge.dart:7 | const HomeScoreBadge({required this.score, this.compact = true, super.key}) |
| S0200 | símbolo | app/lib/app/home/home_score_badge.dart:9 | score |
| S0201 | símbolo | app/lib/app/home/home_score_badge.dart:10 | compact |
| S0202 | símbolo | app/lib/app/home/home_score_badge.dart:12 | starColor = Color(0xffffcf62) |
| S0203 | símbolo | app/lib/app/home/home_score_badge.dart:14 | @override Widget build(BuildContext context) |
| S0204 | símbolo | app/lib/app/home/home_screen.dart:11 | final class HomeScreen extends StatefulWidget |
| S0205 | símbolo | app/lib/app/home/home_screen.dart:12 | const HomeScreen({ required this.load, required this.onDetails, required this.onLibraryAction, this.onResume, this.refreshRevision = 0, super.key, }) |
| S0206 | símbolo | app/lib/app/home/home_screen.dart:21 | load |
| S0207 | símbolo | app/lib/app/home/home_screen.dart:22 | onDetails |
| S0208 | símbolo | app/lib/app/home/home_screen.dart:24 | onLibraryAction |
| S0209 | símbolo | app/lib/app/home/home_screen.dart:25 | onResume |
| S0210 | símbolo | app/lib/app/home/home_screen.dart:26 | refreshRevision |
| S0211 | símbolo | app/lib/app/home/home_screen.dart:28 | @override State<HomeScreen> createState() |
| S0212 | símbolo | app/lib/app/home/home_sections.dart:12 | abstract final class HomeSections |
| S0213 | símbolo | app/lib/app/home/home_sections.dart:13 | static List<Widget> buildSections( HomeContent content, ValueChanged<HomeTitle> onDetails, { required Future<void> Function(HomeTitle, HomeCardLibraryCommand) onLibraryAction, required bool wide, ValueChanged<HomeEpisode>? onResume, }) |
| S0214 | símbolo | app/lib/app/home/home_typography.dart:5 | /// Platform-system typography with restrained weights and tracking. /// Supplying a licensed family through HomeAppearance remains an extension. abstract final class HomeTypography |
| S0215 | símbolo | app/lib/app/home/home_typography.dart:8 | static TextStyle heroTitle(TextStyle? base, HomeAppearance appearance) |
| S0216 | símbolo | app/lib/app/home/home_typography.dart:16 | static TextStyle sectionTitle(TextStyle? base, HomeAppearance appearance) |
| S0217 | símbolo | app/lib/app/home/home_typography.dart:23 | static TextStyle cardTitle(HomeAppearance appearance) |
| S0218 | símbolo | app/lib/app/player/audio_track_selector.dart:5 | final class AudioTrackSelector extends StatelessWidget |
| S0219 | símbolo | app/lib/app/player/audio_track_selector.dart:6 | const AudioTrackSelector({ required this.tracks, required this.selectedId, required this.generation, required this.mediaContextRevision, required this.onSelected, super.key, }) |
| S0220 | símbolo | app/lib/app/player/audio_track_selector.dart:15 | tracks |
| S0221 | símbolo | app/lib/app/player/audio_track_selector.dart:16 | selectedId |
| S0222 | símbolo | app/lib/app/player/audio_track_selector.dart:17 | generation |
| S0223 | símbolo | app/lib/app/player/audio_track_selector.dart:18 | mediaContextRevision |
| S0224 | símbolo | app/lib/app/player/audio_track_selector.dart:20 | onSelected |
| S0225 | símbolo | app/lib/app/player/audio_track_selector.dart:22 | @override Widget build(BuildContext context) |
| S0226 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:7 | /// Small spike-only search/selection flow. Remote JSON and temporary URLs /// never enter the widget; it only sees normalized domain values. final class ExternalSubtitleSearchPanel extends StatefulWidget |
| S0227 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:10 | const ExternalSubtitleSearchPanel({ required this.service, this.hardsubStatus = HardsubStatus.unknown, super.key, }) |
| S0228 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:16 | service |
| S0229 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:17 | hardsubStatus |
| S0230 | símbolo | app/lib/app/player/external_subtitle_search_panel.dart:19 | @override State<ExternalSubtitleSearchPanel> createState() |
| S0231 | símbolo | app/lib/app/player/media_kit_video_surface.dart:6 | /// Draws the engine-owned texture without a second set of controls. final class MediaKitVideoSurface extends StatelessWidget |
| S0232 | símbolo | app/lib/app/player/media_kit_video_surface.dart:8 | const MediaKitVideoSurface({ required this.controller, required this.display, super.key, }) |
| S0233 | símbolo | app/lib/app/player/media_kit_video_surface.dart:14 | controller |
| S0234 | símbolo | app/lib/app/player/media_kit_video_surface.dart:15 | display |
| S0235 | símbolo | app/lib/app/player/media_kit_video_surface.dart:17 | @override Widget build(BuildContext context) |
| S0236 | símbolo | app/lib/app/player/media_kit_video_surface.dart:29 | /// Builds the texture-only media_kit surface used by the F2.2 spike. /// /// The package defaults to AdaptiveVideoControls. Kongroo owns the only /// playback controls in this spike, so this must remain null. @visibleForTesting Video mediaKitVideoWidgetWithoutControls( VideoController controller, { BoxFit fit = BoxFit.contain, double? aspectRatio, }) |
| S0237 | símbolo | app/lib/app/player/media_kit_video_surface.dart:45 | @visibleForTesting String mediaKitVideoSurfaceStatusLabel({ required bool controllerInitialized, required bool controllerFailed, required int? textureId, required bool firstFrameRendered, required bool firstFrameFailed, }) |
| S0238 | símbolo | app/lib/app/player/playback_route_session.dart:7 | /// The closeable player session owned by the playback navigation route. /// /// Keeping the route contract small lets tests control close completion without /// constructing a second native player. abstract interface class PlaybackRouteSession |
| S0239 | símbolo | app/lib/app/player/playback_route_session.dart:12 | Widget build() |
| S0240 | símbolo | app/lib/app/player/playback_route_session.dart:14 | Future<void> close() |
| S0241 | símbolo | app/lib/app/player/playback_route_session.dart:17 | /// Cooperative cancellation request for a player startup operation. /// /// Requesting cancellation never interrupts a native Future or releases its /// lease. The startup owner must observe the request at safe points, finish /// cleanup, and only then complete its loader Future. final class PlaybackRouteOpenCancellation |
| S0242 | símbolo | app/lib/app/player/playback_route_session.dart:23 | token = PlaybackCancellationToken() |
| S0243 | símbolo | app/lib/app/player/playback_route_session.dart:25 | bool get isRequested |
| S0244 | símbolo | app/lib/app/player/playback_route_session.dart:27 | void request() |
| S0245 | símbolo | app/lib/app/player/playback_route_session.dart:29 | void throwIfRequested() |
| S0246 | símbolo | app/lib/app/player/playback_route_session.dart:34 | final class PlaybackRouteOpenCancelled implements Exception |
| S0247 | símbolo | app/lib/app/player/playback_route_session.dart:35 | const PlaybackRouteOpenCancelled() |
| S0248 | símbolo | app/lib/app/player/playback_route_session.dart:38 | /// Startup could not begin because another native player still owns the slot. /// /// This UI-facing error keeps the route independent from the data-layer lease /// implementation while allowing the caller to return safely to the catalog. final class PlaybackRoutePlayerBusy extends StateError |
| S0249 | símbolo | app/lib/app/player/playback_route_session.dart:43 | PlaybackRoutePlayerBusy() : super('Another native player still owns the playback slot.') |
| S0250 | símbolo | app/lib/app/player/playback_route_session.dart:47 | /// A close attempt failed and reports whether the native player is retained. final class PlaybackRouteCleanupFailure implements Exception |
| S0251 | símbolo | app/lib/app/player/playback_route_session.dart:49 | const PlaybackRouteCleanupFailure({ required this.cause, required this.nativePlayerStillOwned, required this.nonNativeCleanupFailed, }) |
| S0252 | símbolo | app/lib/app/player/playback_route_session.dart:55 | cause |
| S0253 | símbolo | app/lib/app/player/playback_route_session.dart:56 | nativePlayerStillOwned |
| S0254 | símbolo | app/lib/app/player/playback_route_session.dart:57 | nonNativeCleanupFailed |
| S0255 | símbolo | app/lib/app/player/player_demo_panel.dart:8 | final class PlayerDemoPanel extends StatefulWidget |
| S0256 | símbolo | app/lib/app/player/player_demo_panel.dart:9 | const PlayerDemoPanel({ required this.catalog, required this.coordinator, super.key, }) |
| S0257 | símbolo | app/lib/app/player/player_demo_panel.dart:15 | catalog |
| S0258 | símbolo | app/lib/app/player/player_demo_panel.dart:16 | coordinator |
| S0259 | símbolo | app/lib/app/player/player_demo_panel.dart:18 | @override State<PlayerDemoPanel> createState() |
| S0260 | símbolo | app/lib/app/player/player_frame_timing_probe.dart:6 | /// Opt-in Flutter frame timings. These are UI/raster timings, not video FPS. final class PlayerFrameTimingProbe |
| S0261 | símbolo | app/lib/app/player/player_frame_timing_probe.dart:8 | PlayerFrameTimingProbe({this.interval = const Duration(seconds: 10)}) |
| S0262 | símbolo | app/lib/app/player/player_frame_timing_probe.dart:13 | interval |
| S0263 | símbolo | app/lib/app/player/player_frame_timing_probe.dart:43 | void dispose() |
| S0264 | símbolo | app/lib/app/player/player_nerd_panel.dart:6 | /// Top-of-video diagnostics. Sampling belongs to PlaybackPerformanceCollector. final class PlayerNerdPanel extends StatelessWidget |
| S0265 | símbolo | app/lib/app/player/player_nerd_panel.dart:8 | const PlayerNerdPanel({ required this.coordinator, required this.onClose, this.samples, super.key, }) |
| S0266 | símbolo | app/lib/app/player/player_nerd_panel.dart:15 | coordinator |
| S0267 | símbolo | app/lib/app/player/player_nerd_panel.dart:16 | samples |
| S0268 | símbolo | app/lib/app/player/player_nerd_panel.dart:17 | onClose |
| S0269 | símbolo | app/lib/app/player/player_nerd_panel.dart:19 | @override Widget build(BuildContext context) |
| S0270 | símbolo | app/lib/app/player/player_quality_panel.dart:5 | /// Presents only video tracks reported for the current source by the engine. /// A single track describes a fixed source; it is not an adaptive ladder. final class PlayerQualityPanel extends StatelessWidget |
| S0271 | símbolo | app/lib/app/player/player_quality_panel.dart:8 | const PlayerQualityPanel({ required this.tracks, required this.selectedId, required this.generation, required this.mediaContextRevision, required this.onSelected, super.key, }) |
| S0272 | símbolo | app/lib/app/player/player_quality_panel.dart:17 | tracks |
| S0273 | símbolo | app/lib/app/player/player_quality_panel.dart:18 | selectedId |
| S0274 | símbolo | app/lib/app/player/player_quality_panel.dart:19 | generation |
| S0275 | símbolo | app/lib/app/player/player_quality_panel.dart:20 | mediaContextRevision |
| S0276 | símbolo | app/lib/app/player/player_quality_panel.dart:22 | onSelected |
| S0277 | símbolo | app/lib/app/player/player_quality_panel.dart:24 | @override Widget build(BuildContext context) |
| S0278 | símbolo | app/lib/app/player/player_subtitle_panel.dart:12 | spikeSubtitleDelayStep = Duration(milliseconds: 250) |
| S0279 | símbolo | app/lib/app/player/player_subtitle_panel.dart:14 | /// Session preferences survive dismissing the subtitle dialog. final class PlayerSubtitlePreferences |
| S0280 | símbolo | app/lib/app/player/player_subtitle_panel.dart:16 | style = SubtitleStyle() |
| S0281 | símbolo | app/lib/app/player/player_subtitle_panel.dart:17 | delay = Duration.zero |
| S0282 | símbolo | app/lib/app/player/player_subtitle_panel.dart:20 | final class PlayerSubtitlePanel extends StatefulWidget |
| S0283 | símbolo | app/lib/app/player/player_subtitle_panel.dart:21 | const PlayerSubtitlePanel({ required this.coordinator, required this.preferences, this.externalService, super.key, }) |
| S0284 | símbolo | app/lib/app/player/player_subtitle_panel.dart:28 | coordinator |
| S0285 | símbolo | app/lib/app/player/player_subtitle_panel.dart:29 | preferences |
| S0286 | símbolo | app/lib/app/player/player_subtitle_panel.dart:30 | externalService |
| S0287 | símbolo | app/lib/app/player/player_subtitle_panel.dart:32 | @override State<PlayerSubtitlePanel> createState() |
| S0288 | símbolo | app/lib/app/player/player_video_display.dart:3 | /// Presentation-only scaling. It does not alter the decoded stream or Player. enum PlayerVideoFit |
| S0289 | símbolo | app/lib/app/player/player_video_display.dart:4 | contain |
| S0290 | símbolo | app/lib/app/player/player_video_display.dart:4 | cover |
| S0291 | símbolo | app/lib/app/player/player_video_display.dart:4 | fill |
| S0292 | símbolo | app/lib/app/player/player_video_display.dart:4 | originalSize |
| S0293 | símbolo | app/lib/app/player/player_video_display.dart:6 | enum PlayerVideoAspect |
| S0294 | símbolo | app/lib/app/player/player_video_display.dart:6 | automatic |
| S0295 | símbolo | app/lib/app/player/player_video_display.dart:6 | widescreen |
| S0296 | símbolo | app/lib/app/player/player_video_display.dart:6 | classic |
| S0297 | símbolo | app/lib/app/player/player_video_display.dart:6 | cinema |
| S0298 | símbolo | app/lib/app/player/player_video_display.dart:8 | @immutable final class PlayerVideoDisplaySettings |
| S0299 | símbolo | app/lib/app/player/player_video_display.dart:10 | const PlayerVideoDisplaySettings({ this.fit = PlayerVideoFit.contain, this.aspect = PlayerVideoAspect.automatic, }) |
| S0300 | símbolo | app/lib/app/player/player_video_display.dart:15 | fit |
| S0301 | símbolo | app/lib/app/player/player_video_display.dart:16 | aspect |
| S0302 | símbolo | app/lib/app/player/player_video_display.dart:18 | BoxFit get boxFit |
| S0303 | símbolo | app/lib/app/player/player_video_display.dart:26 | double? get aspectRatio |
| S0304 | símbolo | app/lib/app/player/player_video_display.dart:34 | /// Shared by the menu and the one existing Video widget. final class PlayerVideoDisplayController extends ValueNotifier<PlayerVideoDisplaySettings> |
| S0305 | símbolo | app/lib/app/player/player_video_display.dart:37 | PlayerVideoDisplayController() : super(const PlayerVideoDisplaySettings()) |
| S0306 | símbolo | app/lib/app/player/player_video_display.dart:39 | void setFit(PlayerVideoFit fit) |
| S0307 | símbolo | app/lib/app/player/player_video_display.dart:42 | void setAspect(PlayerVideoAspect aspect) |
| S0308 | símbolo | app/lib/app/player/player_video_display.dart:45 | void reset() |
| S0309 | símbolo | app/lib/app/player/player_video_display_panel.dart:7 | /// Changes only presentation scaling on the existing video texture. final class PlayerVideoDisplayButton extends StatelessWidget |
| S0310 | símbolo | app/lib/app/player/player_video_display_panel.dart:9 | const PlayerVideoDisplayButton({required this.display, super.key}) |
| S0311 | símbolo | app/lib/app/player/player_video_display_panel.dart:11 | display |
| S0312 | símbolo | app/lib/app/player/player_video_display_panel.dart:13 | @override Widget build(BuildContext context) |
| S0313 | símbolo | app/lib/app/player/player_video_layout.dart:3 | /// Keeps the texture mounted while the toolbar moves between dock and overlay. final class PlayerVideoLayout extends StatelessWidget |
| S0314 | símbolo | app/lib/app/player/player_video_layout.dart:5 | const PlayerVideoLayout({ required this.video, required this.controls, required this.fullscreen, super.key, }) |
| S0315 | símbolo | app/lib/app/player/player_video_layout.dart:12 | video |
| S0316 | símbolo | app/lib/app/player/player_video_layout.dart:13 | controls |
| S0317 | símbolo | app/lib/app/player/player_video_layout.dart:14 | fullscreen |
| S0318 | símbolo | app/lib/app/player/player_video_layout.dart:16 | @override Widget build(BuildContext context) |
| S0319 | símbolo | app/lib/app/player/player_window_controller.dart:5 | /// Platform boundary for the real application window, separate from media /// playback. A successful request is not a claim that the window transitioned. abstract interface class PlayerWindowController |
| S0320 | símbolo | app/lib/app/player/player_window_controller.dart:8 | Stream<PlayerWindowSnapshot> get states |
| S0321 | símbolo | app/lib/app/player/player_window_controller.dart:9 | PlayerWindowSnapshot get state |
| S0322 | símbolo | app/lib/app/player/player_window_controller.dart:11 | Future<void> initialize() |
| S0323 | símbolo | app/lib/app/player/player_window_controller.dart:12 | Future<void> requestFullscreen(bool fullscreen) |
| S0324 | símbolo | app/lib/app/player/player_window_controller.dart:13 | Future<void> dispose() |
| S0325 | símbolo | app/lib/app/player/player_window_controller.dart:16 | final class PlayerWindowSnapshot |
| S0326 | símbolo | app/lib/app/player/player_window_controller.dart:17 | const PlayerWindowSnapshot({ this.fullscreen = false, this.observed = false, this.requestPending = false, this.error, }) |
| S0327 | símbolo | app/lib/app/player/player_window_controller.dart:24 | fullscreen |
| S0328 | símbolo | app/lib/app/player/player_window_controller.dart:25 | observed |
| S0329 | símbolo | app/lib/app/player/player_window_controller.dart:26 | requestPending |
| S0330 | símbolo | app/lib/app/player/player_window_controller.dart:27 | error |
| S0331 | símbolo | app/lib/app/player/player_window_controller.dart:29 | PlayerWindowSnapshot copyWith({ bool? fullscreen, bool? observed, bool? requestPending, String? error, bool clearError = false, }) |
| S0332 | símbolo | app/lib/app/player/player_window_controller.dart:43 | /// GTK implementation of [PlayerWindowController] for the Linux spike. /// GTK's window-state event, not the request Future, confirms fullscreen. final class GtkPlayerWindowController implements PlayerWindowController |
| S0333 | símbolo | app/lib/app/player/player_window_controller.dart:46 | GtkPlayerWindowController({ MethodChannel? channel, this.transitionTimeout = const Duration(seconds: 3), }) : _channel = channel ?? const MethodChannel('kongroo/f2.3/window') |
| S0334 | símbolo | app/lib/app/player/player_window_controller.dart:52 | transitionTimeout |
| S0335 | símbolo | app/lib/app/player/player_window_controller.dart:63 | @override Stream<PlayerWindowSnapshot> get states |
| S0336 | símbolo | app/lib/app/player/player_window_controller.dart:66 | @override PlayerWindowSnapshot get state |
| S0337 | símbolo | app/lib/app/player/player_window_controller.dart:69 | @override Future<void> initialize() |
| S0338 | símbolo | app/lib/app/player/player_window_controller.dart:94 | @override Future<void> requestFullscreen(bool fullscreen) |
| S0339 | símbolo | app/lib/app/player/player_window_controller.dart:193 | @override Future<void> dispose() |
| S0340 | símbolo | app/lib/app/player/provider_playback_route.dart:14 | typedef PlaybackRouteSessionLoader = Future<PlaybackRouteSession> Function( PlaybackRouteOpenCancellation cancellation, ); |
| S0341 | símbolo | app/lib/app/player/provider_playback_route.dart:18 | /// Plays a previously resolved public stream through the existing F2 player. /// The exact resolved URI list is passed as an allowlist to the existing /// engine/coordinator; this route does not construct a second Player system. final class ProviderPlaybackRoute extends StatefulWidget |
| S0342 | símbolo | app/lib/app/player/provider_playback_route.dart:22 | const ProviderPlaybackRoute({ required this.manager, required this.episode, required this.streams, required this.initialStream, this.startPosition = Duration.zero, this.trackProgress, this.externalSubtitleCatalog, this.disposeExternalSubtitleCatalog, @visibleForTesting this.moduleLoader, super.key, }) |
| S0343 | símbolo | app/lib/app/player/provider_playback_route.dart:35 | manager |
| S0344 | símbolo | app/lib/app/player/provider_playback_route.dart:36 | episode |
| S0345 | símbolo | app/lib/app/player/provider_playback_route.dart:37 | streams |
| S0346 | símbolo | app/lib/app/player/provider_playback_route.dart:38 | initialStream |
| S0347 | símbolo | app/lib/app/player/provider_playback_route.dart:39 | startPosition |
| S0348 | símbolo | app/lib/app/player/provider_playback_route.dart:40 | trackProgress |
| S0349 | símbolo | app/lib/app/player/provider_playback_route.dart:46 | externalSubtitleCatalog |
| S0350 | símbolo | app/lib/app/player/provider_playback_route.dart:47 | disposeExternalSubtitleCatalog |
| S0351 | símbolo | app/lib/app/player/provider_playback_route.dart:48 | moduleLoader |
| S0352 | símbolo | app/lib/app/player/provider_playback_route.dart:50 | @override State<ProviderPlaybackRoute> createState() |
| S0353 | símbolo | app/lib/app/player/skip_segment_panel.dart:8 | final class SkipSegmentPanel extends StatelessWidget |
| S0354 | símbolo | app/lib/app/player/skip_segment_panel.dart:9 | const SkipSegmentPanel({required this.service, super.key}) |
| S0355 | símbolo | app/lib/app/player/skip_segment_panel.dart:11 | service |
| S0356 | símbolo | app/lib/app/player/skip_segment_panel.dart:13 | @override Widget build(BuildContext context) |
| S0357 | símbolo | app/lib/app/player/source_switch_panel.dart:7 | /// Minimal provider-neutral source switch UI for the opt-in player spike. final class SourceSwitchPanel extends StatelessWidget |
| S0358 | símbolo | app/lib/app/player/source_switch_panel.dart:9 | const SourceSwitchPanel({required this.service, super.key}) |
| S0359 | símbolo | app/lib/app/player/source_switch_panel.dart:11 | service |
| S0360 | símbolo | app/lib/app/player/source_switch_panel.dart:13 | @override Widget build(BuildContext context) |
| S0361 | símbolo | app/lib/app/player/spike_player_module.dart:29 | /// Composition root for the opt-in F2.2 desktop spike. final class SpikePlayerModule implements PlaybackRouteSession |
| S0362 | símbolo | app/lib/app/player/spike_player_module.dart:47 | engine |
| S0363 | símbolo | app/lib/app/player/spike_player_module.dart:48 | coordinator |
| S0364 | símbolo | app/lib/app/player/spike_player_module.dart:49 | performance |
| S0365 | símbolo | app/lib/app/player/spike_player_module.dart:50 | display |
| S0366 | símbolo | app/lib/app/player/spike_player_module.dart:51 | windowController |
| S0367 | símbolo | app/lib/app/player/spike_player_module.dart:52 | externalSubtitleService |
| S0368 | símbolo | app/lib/app/player/spike_player_module.dart:53 | sourceSwitchService |
| S0369 | símbolo | app/lib/app/player/spike_player_module.dart:54 | skipSegmentService |
| S0370 | símbolo | app/lib/app/player/spike_player_module.dart:55 | automaticSkipController |
| S0371 | símbolo | app/lib/app/player/spike_player_module.dart:58 | pageOptions |
| S0372 | símbolo | app/lib/app/player/spike_player_module.dart:63 | static Future<SpikePlayerModule> open( File? fixture, { PlayerWindowController? windowController, Set<Uri> demoSources = const {}, Set<Uri> trustedExternalSources = const {}, ExternalSubtitleCatalog? externalSubtitleCatalog, FutureOr<void> Function()? disposeExternalSubtitleCatalog, PlaybackProviderManager? sourceProviderManager, PlaybackEpisode? sourceEpisode, ResolvedPlaybackStream? initialResolvedSource, List<ResolvedPlaybackStream>? authorizedAlternatives, SkipSegmentCatalog? skipSegmentCatalog, PlaybackEpisode? skipEpisode, MyAnimeListAnimeId? skipMalAnimeId, SkipAutomationSettings skipAutomationSettings = const SkipAutomationSettings(), EpisodeFillerEvidence? fillerEvidence, FutureOr<void> Function()? disposeSkipSegmentCatalog, PlaybackRouteOpenCancellation? startupCancellation, Duration startPosition = Duration.zero, PlaybackProgressSession Function(SpikePlayerCoordinator)? trackProgress, @visibleForTesting MediaKitSpikeEngine Function()? engineFactory, }) |
| S0373 | símbolo | app/lib/app/player/spike_player_module.dart:316 | /// Opens the existing module for the provider route and translates the /// low-level exclusive-player conflict into a presentation-safe error. static Future<PlaybackRouteSession> openForRoute( Future<PlaybackRouteSession> Function() open, ) |
| S0374 | símbolo | app/lib/app/player/spike_player_module.dart:328 | @override Widget build({Widget? demoControls}) |
| S0375 | símbolo | app/lib/app/player/spike_player_module.dart:345 | @override Future<void> close() |
| S0376 | símbolo | app/lib/app/player/spike_player_module.dart:394 | /// Indicates startup failed and at least one owned resource did not close. /// /// The route must keep the user on the failure screen because the native /// player lease may still be quarantined and require an application restart. final class SpikePlayerStartupCleanupFailure implements Exception |
| S0377 | símbolo | app/lib/app/player/spike_player_module.dart:399 | const SpikePlayerStartupCleanupFailure({ required this.startupError, required this.cleanupError, this.nativePlayerStillOwned = true, this.nonNativeCleanupFailed = true, }) |
| S0378 | símbolo | app/lib/app/player/spike_player_module.dart:406 | startupError |
| S0379 | símbolo | app/lib/app/player/spike_player_module.dart:407 | cleanupError |
| S0380 | símbolo | app/lib/app/player/spike_player_module.dart:408 | nativePlayerStillOwned |
| S0381 | símbolo | app/lib/app/player/spike_player_module.dart:409 | nonNativeCleanupFailed |
| S0382 | símbolo | app/lib/app/player/spike_player_page.dart:26 | spikePlayerKeyboardSeekSeconds = 10 |
| S0383 | símbolo | app/lib/app/player/spike_player_page.dart:27 | spikePlayerKeyboardVolumeStep = 5 |
| S0384 | símbolo | app/lib/app/player/spike_player_page.dart:29 | /// Basic playback controls and scoped keyboard shortcuts for the F2.3 spike. final class SpikePlayerPage extends StatefulWidget |
| S0385 | símbolo | app/lib/app/player/spike_player_page.dart:31 | const SpikePlayerPage({ required this.coordinator, required this.videoSurface, required this.windowController, this.externalSubtitleService, this.sourceSwitchService, this.skipSegmentService, this.demoControls, this.performance, this.display, this.options = const SpikePlayerPageOptions(), super.key, }) |
| S0386 | símbolo | app/lib/app/player/spike_player_page.dart:45 | coordinator |
| S0387 | símbolo | app/lib/app/player/spike_player_page.dart:46 | videoSurface |
| S0388 | símbolo | app/lib/app/player/spike_player_page.dart:47 | windowController |
| S0389 | símbolo | app/lib/app/player/spike_player_page.dart:48 | externalSubtitleService |
| S0390 | símbolo | app/lib/app/player/spike_player_page.dart:49 | sourceSwitchService |
| S0391 | símbolo | app/lib/app/player/spike_player_page.dart:50 | skipSegmentService |
| S0392 | símbolo | app/lib/app/player/spike_player_page.dart:51 | demoControls |
| S0393 | símbolo | app/lib/app/player/spike_player_page.dart:52 | performance |
| S0394 | símbolo | app/lib/app/player/spike_player_page.dart:53 | display |
| S0395 | símbolo | app/lib/app/player/spike_player_page.dart:54 | options |
| S0396 | símbolo | app/lib/app/player/spike_player_page.dart:56 | @override State<SpikePlayerPage> createState() |
| S0397 | símbolo | app/lib/app/player/spike_player_page_options.dart:3 | /// Presentation options resolved by the player composition root. /// /// The page receives these values as data and does not read process /// environment or other operating-system APIs. final class SpikePlayerPageOptions |
| S0398 | símbolo | app/lib/app/player/spike_player_page_options.dart:8 | const SpikePlayerPageOptions({ this.showNerdPanel = false, this.performanceDiagnosticsEnabled = false, this.initialFit, this.initialAspect, }) |
| S0399 | símbolo | app/lib/app/player/spike_player_page_options.dart:15 | factory SpikePlayerPageOptions.fromEnvironment( Map<String, String> environment, ) |
| S0400 | símbolo | app/lib/app/player/spike_player_page_options.dart:37 | showNerdPanel |
| S0401 | símbolo | app/lib/app/player/spike_player_page_options.dart:38 | performanceDiagnosticsEnabled |
| S0402 | símbolo | app/lib/app/player/spike_player_page_options.dart:39 | initialFit |
| S0403 | símbolo | app/lib/app/player/spike_player_page_options.dart:40 | initialAspect |
| S0404 | símbolo | app/lib/app/player/spike_player_page_options.dart:42 | @override bool operator ==(Object other) |
| S0405 | símbolo | app/lib/app/player/spike_player_page_options.dart:50 | @override int get hashCode |
| S0406 | símbolo | app/lib/app/player/spike_window_close_gate.dart:3 | /// Coordinates GTK close requests with playback cleanup without cancelling it. final class SpikeWindowCloseGate |
| S0407 | símbolo | app/lib/app/player/spike_window_close_gate.dart:5 | SpikeWindowCloseGate( this._closePlayback, this._retryPendingCleanup, this._onCleanupFailure, { this.closeWatchdog = const Duration(seconds: 15), void Function()? onCleanupPending, }) : _onCleanupPending = onCleanupPending ?? _ignoreCleanupPending |
| S0408 | símbolo | app/lib/app/player/spike_window_close_gate.dart:16 | closeWatchdog |
| S0409 | símbolo | app/lib/app/player/spike_window_close_gate.dart:22 | Future<bool> requestClose() |
| S0410 | símbolo | app/lib/application/catalog/catalog_service.dart:17 | /// A local library row joined with optional, non-persistent provider metadata. final class CatalogLibraryItem |
| S0411 | símbolo | app/lib/application/catalog/catalog_service.dart:19 | const CatalogLibraryItem({ required this.entry, this.metadata, this.externalId, }) |
| S0412 | símbolo | app/lib/application/catalog/catalog_service.dart:25 | entry |
| S0413 | símbolo | app/lib/application/catalog/catalog_service.dart:26 | externalId |
| S0414 | símbolo | app/lib/application/catalog/catalog_service.dart:27 | metadata |
| S0415 | símbolo | app/lib/application/catalog/catalog_service.dart:29 | String get title |
| S0416 | símbolo | app/lib/application/catalog/catalog_service.dart:32 | /// Coordinates catalog, identity, local-library, and existing progress ports. /// It contains no Flutter, SQL, HTTP, or provider-specific DTO dependencies. final class CatalogService |
| S0417 | símbolo | app/lib/application/catalog/catalog_service.dart:35 | CatalogService({ required this.metadataProvider, required this.identities, required this.library, required this.progress, DateTime Function()? clock, this.episodeIndex, }) : _clock = clock ?? DateTime.now |
| S0418 | símbolo | app/lib/application/catalog/catalog_service.dart:44 | metadataProvider |
| S0419 | símbolo | app/lib/application/catalog/catalog_service.dart:45 | episodeIndex |
| S0420 | símbolo | app/lib/application/catalog/catalog_service.dart:46 | identities |
| S0421 | símbolo | app/lib/application/catalog/catalog_service.dart:47 | library |
| S0422 | símbolo | app/lib/application/catalog/catalog_service.dart:48 | progress |
| S0423 | símbolo | app/lib/application/catalog/catalog_service.dart:52 | Future<Result<List<ProviderAnimeMetadata>>> search(String query) |
| S0424 | símbolo | app/lib/application/catalog/catalog_service.dart:72 | Future<Result<List<ProviderAnimeMetadata>>> browsePopular({int limit = 20}) |
| S0425 | símbolo | app/lib/application/catalog/catalog_service.dart:75 | Future<Result<List<ProviderAnimeMetadata>>> browseTrending({ int limit = 20, }) |
| S0426 | símbolo | app/lib/application/catalog/catalog_service.dart:105 | Future<ProviderAnimeMetadata?> readCachedDetails(ExternalAnimeId id) |
| S0427 | símbolo | app/lib/application/catalog/catalog_service.dart:111 | Future<Result<ProviderAnimeMetadata>> details(ExternalAnimeId id) |
| S0428 | símbolo | app/lib/application/catalog/catalog_service.dart:127 | /// Lists which episodes exist for a title. The index never grants playback: /// a listed episode still needs a verified source before it can play. Future<Result<EpisodeIndexPage>> listEpisodes( ExternalAnimeId anime, { int offset = 0, int limit = 20, }) |
| S0429 | símbolo | app/lib/application/catalog/catalog_service.dart:155 | Future<Result<List<CatalogLibraryItem>>> loadLibrary() |
| S0430 | símbolo | app/lib/application/catalog/catalog_service.dart:197 | Future<Result<LibraryEntry?>> getLibraryEntry( ExternalAnimeId externalId, ) |
| S0431 | símbolo | app/lib/application/catalog/catalog_service.dart:211 | Future<Result<LibraryEntry?>> getLibraryEntryByAnimeId(AnimeId animeId) |
| S0432 | símbolo | app/lib/application/catalog/catalog_service.dart:214 | /// A user pressing Add is the explicit confirmation for this local link. /// Concurrent requests for the same external ID share one identity write. Future<Result<LibraryEntry>> addToLibrary( ProviderAnimeMetadata metadata, ) |
| S0433 | símbolo | app/lib/application/catalog/catalog_service.dart:250 | Future<Result<LibraryEntry>> setStatus( AnimeId animeId, LibraryStatus status, ) |
| S0434 | símbolo | app/lib/application/catalog/catalog_service.dart:255 | /// Removes the local library membership while preserving identity/progress. Future<Result<void>> removeFromLibrary(AnimeId animeId) |
| S0435 | símbolo | app/lib/application/catalog/catalog_service.dart:259 | Future<Result<PlaybackProgress?>> getProgress(AnimeId animeId) |
| S0436 | símbolo | app/lib/application/catalog/catalog_service.dart:262 | Future<Result<PlaybackProgress?>> getEpisodeProgress( AnimeId animeId, int episode, ) |
| S0437 | símbolo | app/lib/application/catalog/catalog_service.dart:267 | static ProgressKey episodeProgressKey(AnimeId animeId, int episode) |
| S0438 | símbolo | app/lib/application/catalog/catalog_service.dart:273 | Future<Result<List<PlaybackProgress>>> listProgress() |
| S0439 | símbolo | app/lib/application/catalog/catalog_service.dart:276 | Future<Result<PlaybackProgress>> saveProgress({ required AnimeId animeId, required int positionMs, }) |
| S0440 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:3 | /// A single, low cost observation of the active native player. Null means the /// property was unavailable; zero is a measured value. `decodedFps` is mpv's /// estimated video filter output rate, not compositor/display FPS. final class PlaybackPerformanceSample |
| S0441 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:7 | const PlaybackPerformanceSample({ required this.collectedAt, this.sampleFailed = false, this.nominalFps, this.decodedFps, this.positionEventsPerSecond, this.framesDropped, this.decoderFramesDropped, this.avSyncSeconds, this.totalAvSyncChangeSeconds, this.cacheSeconds, this.hardwareDecoder, this.videoCodec, this.audioCodec, this.videoOutput, this.audioOutput, this.videoWidth, this.videoHeight, this.pixelFormat, this.audioChannels, this.audioSampleRate, this.videoBitrate, this.audioBitrate, this.rssBytes, }) |
| S0442 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:33 | collectedAt |
| S0443 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:34 | sampleFailed |
| S0444 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:35 | nominalFps |
| S0445 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:36 | decodedFps |
| S0446 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:39 | positionEventsPerSecond |
| S0447 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:40 | framesDropped |
| S0448 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:41 | decoderFramesDropped |
| S0449 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:42 | avSyncSeconds |
| S0450 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:43 | totalAvSyncChangeSeconds |
| S0451 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:44 | cacheSeconds |
| S0452 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:45 | hardwareDecoder |
| S0453 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:46 | videoCodec |
| S0454 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:47 | audioCodec |
| S0455 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:48 | videoOutput |
| S0456 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:49 | audioOutput |
| S0457 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:50 | videoWidth |
| S0458 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:51 | videoHeight |
| S0459 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:52 | pixelFormat |
| S0460 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:53 | audioChannels |
| S0461 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:54 | audioSampleRate |
| S0462 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:55 | videoBitrate |
| S0463 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:56 | audioBitrate |
| S0464 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:57 | rssBytes |
| S0465 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:60 | abstract interface class PlaybackPerformanceSource |
| S0466 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:61 | Future<PlaybackPerformanceSample> samplePerformance() |
| S0467 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:64 | /// Starts polling only while explicitly enabled. Samples never overlap and a /// late completion after stop is discarded. stop/dispose wait for an in-flight /// native read; a timer cannot cancel a native call already in progress. final class PlaybackPerformanceCollector |
| S0468 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:68 | PlaybackPerformanceCollector( this.source, { this.interval = const Duration(seconds: 1), this.ticks, }) |
| S0469 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:78 | source |
| S0470 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:79 | interval |
| S0471 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:82 | ticks |
| S0472 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:93 | Stream<PlaybackPerformanceSample> get samples |
| S0473 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:94 | bool get active |
| S0474 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:96 | void start() |
| S0475 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:135 | Future<void> stop() |
| S0476 | símbolo | app/lib/application/player/diagnostics/playback_performance.dart:144 | Future<void> dispose() |
| S0477 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:4 | final class ExternalSubtitleLoadResult |
| S0478 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:5 | const ExternalSubtitleLoadResult({ required this.download, required this.hardsubDecision, }) |
| S0479 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:10 | download |
| S0480 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:11 | hardsubDecision |
| S0481 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:14 | /// Coordinates catalogue access with the existing player contract. It never /// exposes remote URLs to the engine; only a downloaded local file is loaded. final class ExternalSubtitleService |
| S0482 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:17 | const ExternalSubtitleService({ required this.catalog, required this.loader, this.sourceGeneration, }) |
| S0483 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:23 | catalog |
| S0484 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:24 | loader |
| S0485 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:25 | sourceGeneration |
| S0486 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:27 | Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search( ExternalSubtitleQuery query, ) |
| S0487 | símbolo | app/lib/application/player/external_subtitles/external_subtitle_service.dart:37 | Future<ExternalSubtitleResult<ExternalSubtitleLoadResult>> downloadAndLoad( ExternalSubtitleCandidate candidate, { required HardsubStatus hardsubStatus, }) |
| S0488 | símbolo | app/lib/application/player/playback_progress_session.dart:8 | /// Records engine-observed progress for one local episode. final class PlaybackProgressSession |
| S0489 | símbolo | app/lib/application/player/playback_progress_session.dart:10 | PlaybackProgressSession( SpikePlayerCoordinator player, this._checkpoints, this._key, ) |
| S0490 | símbolo | app/lib/application/player/playback_progress_session.dart:58 | Future<void> close() |
| S0491 | símbolo | app/lib/application/player/playback_spike_contract.dart:10 | playbackSpikeMinimumVolume = 0 |
| S0492 | símbolo | app/lib/application/player/playback_spike_contract.dart:11 | playbackSpikeMaximumVolume = 100 |
| S0493 | símbolo | app/lib/application/player/playback_spike_contract.dart:13 | abstract interface class PlaybackSpikeEngine |
| S0494 | símbolo | app/lib/application/player/playback_spike_contract.dart:14 | Stream<PlaybackSpikeSnapshot> get snapshots |
| S0495 | símbolo | app/lib/application/player/playback_spike_contract.dart:16 | Future<void> initialize() |
| S0496 | símbolo | app/lib/application/player/playback_spike_contract.dart:17 | Future<void> open( Uri source, { int sourceGeneration = 0, PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(), }) |
| S0497 | símbolo | app/lib/application/player/playback_spike_contract.dart:22 | Future<void> play() |
| S0498 | símbolo | app/lib/application/player/playback_spike_contract.dart:23 | Future<void> pause() |
| S0499 | símbolo | app/lib/application/player/playback_spike_contract.dart:24 | Future<void> seek(Duration position) |
| S0500 | símbolo | app/lib/application/player/playback_spike_contract.dart:25 | Future<void> setVolume(double volume) |
| S0501 | símbolo | app/lib/application/player/playback_spike_contract.dart:26 | Future<void> selectSubtitleTrack(String id) |
| S0502 | símbolo | app/lib/application/player/playback_spike_contract.dart:27 | Future<ExternalSubtitleDecision> loadExternalSubtitle( Uri source, { required HardsubStatus hardsubStatus, String? title, String? language, }) |
| S0503 | símbolo | app/lib/application/player/playback_spike_contract.dart:33 | Future<void> applySubtitleStyle(SubtitleStyle style) |
| S0504 | símbolo | app/lib/application/player/playback_spike_contract.dart:34 | Future<void> setSubtitleDelay(Duration delay) |
| S0505 | símbolo | app/lib/application/player/playback_spike_contract.dart:35 | Future<void> stop() |
| S0506 | símbolo | app/lib/application/player/playback_spike_contract.dart:36 | Future<void> dispose() |
| S0507 | símbolo | app/lib/application/player/playback_spike_contract.dart:39 | /// Optional capability implemented by adapters that expose native audio tracks. abstract interface class PlaybackAudioSelection |
| S0508 | símbolo | app/lib/application/player/playback_spike_contract.dart:41 | Future<void> selectAudioTrack(String id) |
| S0509 | símbolo | app/lib/application/player/playback_spike_contract.dart:44 | /// Optional native capability for sources containing multiple video tracks. /// This does not imply HLS/DASH adaptive bitrate support. abstract interface class PlaybackVideoSelection |
| S0510 | símbolo | app/lib/application/player/playback_spike_contract.dart:47 | Future<void> selectVideoTrack(String id) |
| S0511 | símbolo | app/lib/application/player/playback_spike_contract.dart:50 | /// Immutable observable state emitted by the engine adapter. final class PlaybackSpikeSnapshot |
| S0512 | símbolo | app/lib/application/player/playback_spike_contract.dart:52 | const PlaybackSpikeSnapshot({ this.playing = false, this.stopped = false, this.buffering = false, this.position = Duration.zero, this.duration = Duration.zero, this.volume = 100, this.error, this.sourceGeneration = 0, this.subtitleTracks = const [], this.selectedSubtitleId = 'auto', this.audioTracks = const [], this.selectedAudioId = 'auto', this.videoTracks = const [], this.selectedVideoId = 'auto', }) |
| S0513 | símbolo | app/lib/application/player/playback_spike_contract.dart:69 | playing |
| S0514 | símbolo | app/lib/application/player/playback_spike_contract.dart:72 | stopped |
| S0515 | símbolo | app/lib/application/player/playback_spike_contract.dart:73 | buffering |
| S0516 | símbolo | app/lib/application/player/playback_spike_contract.dart:74 | position |
| S0517 | símbolo | app/lib/application/player/playback_spike_contract.dart:75 | duration |
| S0518 | símbolo | app/lib/application/player/playback_spike_contract.dart:78 | volume |
| S0519 | símbolo | app/lib/application/player/playback_spike_contract.dart:79 | error |
| S0520 | símbolo | app/lib/application/player/playback_spike_contract.dart:83 | sourceGeneration |
| S0521 | símbolo | app/lib/application/player/playback_spike_contract.dart:84 | subtitleTracks |
| S0522 | símbolo | app/lib/application/player/playback_spike_contract.dart:85 | selectedSubtitleId |
| S0523 | símbolo | app/lib/application/player/playback_spike_contract.dart:86 | audioTracks |
| S0524 | símbolo | app/lib/application/player/playback_spike_contract.dart:87 | selectedAudioId |
| S0525 | símbolo | app/lib/application/player/playback_spike_contract.dart:88 | videoTracks |
| S0526 | símbolo | app/lib/application/player/playback_spike_contract.dart:89 | selectedVideoId |
| S0527 | símbolo | app/lib/application/player/playback_spike_contract.dart:91 | /// Copies state while preserving [error] unless a new error or explicit /// [clearError] is supplied. Successful recovery paths may clear the error. PlaybackSpikeSnapshot copyWith({ bool? playing, bool? stopped, bool? buffering, Duration? position, Duration? duration, double? volume, String? error, int? sourceGeneration, List<SubtitleTrackInfo>? subtitleTracks, String? selectedSubtitleId, List<AudioTrackInfo>? audioTracks, String? selectedAudioId, List<VideoTrackInfo>? videoTracks, String? selectedVideoId, bool clearError = false, }) |
| S0528 | símbolo | app/lib/application/player/playback_spike_contract.dart:127 | /// Coarse state owned by the application session, separate from native /// playback facts. Seeking is orthogonal so it can overlap Playing or Paused. enum PlaybackSessionStatus |
| S0529 | símbolo | app/lib/application/player/playback_spike_contract.dart:130 | idle |
| S0530 | símbolo | app/lib/application/player/playback_spike_contract.dart:131 | opening |
| S0531 | símbolo | app/lib/application/player/playback_spike_contract.dart:132 | ready |
| S0532 | símbolo | app/lib/application/player/playback_spike_contract.dart:133 | buffering |
| S0533 | símbolo | app/lib/application/player/playback_spike_contract.dart:134 | playing |
| S0534 | símbolo | app/lib/application/player/playback_spike_contract.dart:135 | paused |
| S0535 | símbolo | app/lib/application/player/playback_spike_contract.dart:136 | completed |
| S0536 | símbolo | app/lib/application/player/playback_spike_contract.dart:137 | stopped |
| S0537 | símbolo | app/lib/application/player/playback_spike_contract.dart:138 | switchingSource |
| S0538 | símbolo | app/lib/application/player/playback_spike_contract.dart:139 | error |
| S0539 | símbolo | app/lib/application/player/playback_spike_contract.dart:140 | closing |
| S0540 | símbolo | app/lib/application/player/playback_spike_contract.dart:141 | disposed |
| S0541 | símbolo | app/lib/application/player/playback_spike_contract.dart:144 | /// Application-visible session state. Native adapters continue to publish /// [PlaybackSpikeSnapshot]; the coordinator adds operation/lifecycle status. final class PlaybackSessionSnapshot |
| S0542 | símbolo | app/lib/application/player/playback_spike_contract.dart:147 | const PlaybackSessionSnapshot({ this.playback = const PlaybackSpikeSnapshot(), this.observedPosition = Duration.zero, this.status = PlaybackSessionStatus.idle, this.seeking = false, this.sourceGeneration = 0, this.sourceUri, }) |
| S0543 | símbolo | app/lib/application/player/playback_spike_contract.dart:156 | playback |
| S0544 | símbolo | app/lib/application/player/playback_spike_contract.dart:159 | observedPosition |
| S0545 | símbolo | app/lib/application/player/playback_spike_contract.dart:160 | status |
| S0546 | símbolo | app/lib/application/player/playback_spike_contract.dart:161 | seeking |
| S0547 | símbolo | app/lib/application/player/playback_spike_contract.dart:164 | sourceGeneration |
| S0548 | símbolo | app/lib/application/player/playback_spike_contract.dart:165 | sourceUri |
| S0549 | símbolo | app/lib/application/player/playback_spike_contract.dart:167 | bool get playing |
| S0550 | símbolo | app/lib/application/player/playback_spike_contract.dart:168 | bool get stopped |
| S0551 | símbolo | app/lib/application/player/playback_spike_contract.dart:169 | bool get buffering |
| S0552 | símbolo | app/lib/application/player/playback_spike_contract.dart:170 | Duration get position |
| S0553 | símbolo | app/lib/application/player/playback_spike_contract.dart:171 | Duration get duration |
| S0554 | símbolo | app/lib/application/player/playback_spike_contract.dart:172 | double get volume |
| S0555 | símbolo | app/lib/application/player/playback_spike_contract.dart:173 | String? get error |
| S0556 | símbolo | app/lib/application/player/playback_spike_contract.dart:174 | List<SubtitleTrackInfo> get subtitleTracks |
| S0557 | símbolo | app/lib/application/player/playback_spike_contract.dart:175 | String get selectedSubtitleId |
| S0558 | símbolo | app/lib/application/player/playback_spike_contract.dart:176 | List<VideoTrackInfo> get videoTracks |
| S0559 | símbolo | app/lib/application/player/playback_spike_contract.dart:177 | String get selectedVideoId |
| S0560 | símbolo | app/lib/application/player/playback_spike_contract.dart:179 | PlaybackSessionSnapshot copyWith({ PlaybackSpikeSnapshot? playback, Duration? observedPosition, PlaybackSessionStatus? status, bool? seeking, int? sourceGeneration, Uri? sourceUri, bool clearSourceUri = false, }) |
| S0561 | símbolo | app/lib/application/player/playback_spike_contract.dart:197 | enum PlaybackResumeFailureReason |
| S0562 | símbolo | app/lib/application/player/playback_spike_contract.dart:197 | durationUnknown |
| S0563 | símbolo | app/lib/application/player/playback_spike_contract.dart:197 | seekFailed |
| S0564 | símbolo | app/lib/application/player/playback_spike_contract.dart:199 | final class PlaybackResumeFailure implements Exception |
| S0565 | símbolo | app/lib/application/player/playback_spike_contract.dart:200 | const PlaybackResumeFailure(this.reason) |
| S0566 | símbolo | app/lib/application/player/playback_spike_contract.dart:202 | reason |
| S0567 | símbolo | app/lib/application/player/playback_spike_contract.dart:205 | enum PlaybackSourceSwitchDisposition |
| S0568 | símbolo | app/lib/application/player/playback_spike_contract.dart:206 | changed |
| S0569 | símbolo | app/lib/application/player/playback_spike_contract.dart:207 | unchanged |
| S0570 | símbolo | app/lib/application/player/playback_spike_contract.dart:208 | targetFailedPreviousRestored |
| S0571 | símbolo | app/lib/application/player/playback_spike_contract.dart:209 | targetAndPreviousFailed |
| S0572 | símbolo | app/lib/application/player/playback_spike_contract.dart:212 | /// Observable result of one coordinator-owned source-switch transaction. final class PlaybackSourceSwitchResult |
| S0573 | símbolo | app/lib/application/player/playback_spike_contract.dart:214 | const PlaybackSourceSwitchResult({ required this.disposition, required this.previousSource, required this.selectedSource, required this.referencePosition, required this.observedPosition, this.error, }) |
| S0574 | símbolo | app/lib/application/player/playback_spike_contract.dart:223 | disposition |
| S0575 | símbolo | app/lib/application/player/playback_spike_contract.dart:224 | previousSource |
| S0576 | símbolo | app/lib/application/player/playback_spike_contract.dart:225 | selectedSource |
| S0577 | símbolo | app/lib/application/player/playback_spike_contract.dart:226 | referencePosition |
| S0578 | símbolo | app/lib/application/player/playback_spike_contract.dart:227 | observedPosition |
| S0579 | símbolo | app/lib/application/player/playback_spike_contract.dart:228 | error |
| S0580 | símbolo | app/lib/application/player/playback_spike_contract.dart:230 | bool get succeeded |
| S0581 | símbolo | app/lib/application/player/playback_spike_contract.dart:234 | Duration? get positionDelta |
| S0582 | símbolo | app/lib/application/player/player_demo_session.dart:3 | /// Launcher supplied loopback origins and project-local fixtures. final class PlayerDemoCatalog |
| S0583 | símbolo | app/lib/application/player/player_demo_session.dart:5 | PlayerDemoCatalog( this.directory, Iterable<int> ports, { this.realMedia = false, }) : ports = List.unmodifiable(ports) |
| S0584 | símbolo | app/lib/application/player/player_demo_session.dart:16 | directory |
| S0585 | símbolo | app/lib/application/player/player_demo_session.dart:17 | realMedia |
| S0586 | símbolo | app/lib/application/player/player_demo_session.dart:19 | String title(int slot) |
| S0587 | símbolo | app/lib/application/player/player_demo_session.dart:21 | ports |
| S0588 | símbolo | app/lib/application/player/player_demo_session.dart:23 | Uri source(int episode, int server) |
| S0589 | símbolo | app/lib/application/player/player_demo_session.dart:27 | Set<Uri> get loopbackSources |
| S0590 | símbolo | app/lib/application/player/player_demo_session.dart:33 | /// Keeps selection and episode checkpoints outside the widget tree. final class PlayerDemoSession |
| S0591 | símbolo | app/lib/application/player/player_demo_session.dart:35 | PlayerDemoSession(this.catalog, this.coordinator) |
| S0592 | símbolo | app/lib/application/player/player_demo_session.dart:37 | catalog |
| S0593 | símbolo | app/lib/application/player/player_demo_session.dart:38 | coordinator |
| S0594 | símbolo | app/lib/application/player/player_demo_session.dart:40 | episode = 1 |
| S0595 | símbolo | app/lib/application/player/player_demo_session.dart:41 | server = 0 |
| S0596 | símbolo | app/lib/application/player/player_demo_session.dart:42 | busy = false |
| S0597 | símbolo | app/lib/application/player/player_demo_session.dart:43 | message |
| S0598 | símbolo | app/lib/application/player/player_demo_session.dart:45 | Future<void> select(int slot, int endpoint) |
| S0599 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:9 | final class PlaybackProviderRegistration |
| S0600 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:10 | const PlaybackProviderRegistration({ required this.provider, this.priority = 0, this.enabled = true, this.cacheTtl = const Duration(seconds: 30), this.version = '1.0.0', }) |
| S0601 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:18 | provider |
| S0602 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:19 | priority |
| S0603 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:20 | enabled |
| S0604 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:21 | cacheTtl |
| S0605 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:22 | version |
| S0606 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:25 | final class PlaybackVideoHostResolverRegistration |
| S0607 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:26 | const PlaybackVideoHostResolverRegistration({ required this.resolver, this.priority = 0, this.enabled = true, this.version = '1.0.0', }) |
| S0608 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:33 | resolver |
| S0609 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:34 | priority |
| S0610 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:35 | enabled |
| S0611 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:36 | version |
| S0612 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:39 | final class PlaybackProviderDiagnostic |
| S0613 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:40 | const PlaybackProviderDiagnostic({ required this.id, required this.version, required this.circuit, required this.consecutiveFailures, required this.openUntil, required this.lastFailure, required this.probeInFlight, }) |
| S0614 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:50 | id |
| S0615 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:51 | version |
| S0616 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:52 | circuit |
| S0617 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:53 | consecutiveFailures |
| S0618 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:54 | openUntil |
| S0619 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:55 | lastFailure |
| S0620 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:56 | probeInFlight |
| S0621 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:59 | final class PlaybackVideoHostDiagnostic |
| S0622 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:60 | const PlaybackVideoHostDiagnostic({ required this.hostId, required this.circuit, required this.consecutiveFailures, required this.openUntil, required this.lastFailure, required this.probeInFlight, }) |
| S0623 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:69 | hostId |
| S0624 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:70 | circuit |
| S0625 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:71 | consecutiveFailures |
| S0626 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:72 | openUntil |
| S0627 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:73 | lastFailure |
| S0628 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:74 | probeInFlight |
| S0629 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:77 | /// Orchestrates providers, fallback and source/server ordering; it never owns /// or calls the native playback engine. final class PlaybackProviderManager |
| S0630 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:80 | maxHostCircuitBreakers = 128 |
| S0631 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:82 | PlaybackProviderManager({ required Iterable<PlaybackProviderRegistration> providers, Iterable<PlaybackVideoHostResolverRegistration> videoHostResolvers = const [], required DateTime Function() clock, this.circuitFailureThreshold = 3, this.circuitCooldown = const Duration(seconds: 60), }) : _clock = clock |
| S0632 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:151 | circuitFailureThreshold |
| S0633 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:152 | circuitCooldown |
| S0634 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:164 | PlaybackSourceProvider? provider(PlaybackProviderId id) |
| S0635 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:167 | List<PlaybackProviderRegistration> get providerRegistrations |
| S0636 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:169 | List<PlaybackVideoHostResolverRegistration> get resolverRegistrations |
| S0637 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:172 | List<PlaybackProviderDiagnostic> get diagnostics |
| S0638 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:177 | List<PlaybackVideoHostDiagnostic> get hostDiagnostics |
| S0639 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:182 | Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode episode, { required PlaybackCancellationToken cancellation, }) |
| S0640 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:192 | Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolveBestStream( PlaybackEpisode episode, { required PlaybackCancellationToken cancellation, }) |
| S0641 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:222 | /// Resolves every server candidate in provider/source/server priority order. /// The application may try the next URI if the playback engine rejects one. Future<PlaybackProviderResult<List<ResolvedPlaybackStream>>> resolveCandidates( PlaybackEpisode episode, { required PlaybackCancellationToken cancellation, }) |
| S0642 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:291 | result = deduped.values.toList() ..sort((a, b) => b.priority.compareTo(a.priority)) |
| S0643 | símbolo | app/lib/application/player/providers/playback_provider_manager.dart:293 | PlaybackProviderSuccess<List<PlaybackSource>>(result) |
| S0644 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:5 | /// Bounded in-memory LRU for provider source metadata. Expiration is supplied /// by the registry and shortened to the earliest candidate expiry. final class PlaybackSourceCache |
| S0645 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:8 | PlaybackSourceCache({required this.capacity}) |
| S0646 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:14 | capacity |
| S0647 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:18 | int get length |
| S0648 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:20 | List<PlaybackSource>? read(String key, DateTime now) |
| S0649 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:28 | void write( String key, Iterable<PlaybackSource> sources, { required DateTime now, required Duration ttl, DateTime? validUntil, }) |
| S0650 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:51 | void invalidate(String key) |
| S0651 | símbolo | app/lib/application/player/providers/playback_source_cache.dart:53 | void clear() |
| S0652 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:3 | enum ProviderCircuitState |
| S0653 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:3 | closed |
| S0654 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:3 | open |
| S0655 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:3 | halfOpen |
| S0656 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:5 | enum CircuitPermit |
| S0657 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:5 | allow |
| S0658 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:5 | probe |
| S0659 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:5 | deny |
| S0660 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:7 | /// Resource-scoped 3 failures / 60 seconds breaker with one half-open probe. final class ProviderCircuitBreaker |
| S0661 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:9 | ProviderCircuitBreaker({ required this._clock, this.failureThreshold = 3, this.cooldown = const Duration(seconds: 60), }) |
| S0662 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:20 | failureThreshold |
| S0663 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:21 | cooldown |
| S0664 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:27 | int get consecutiveFailures |
| S0665 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:28 | DateTime? get openUntil |
| S0666 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:29 | PlaybackProviderFailureKind? get lastFailure |
| S0667 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:30 | bool get probeInFlight |
| S0668 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:32 | ProviderCircuitState get state |
| S0669 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:39 | CircuitPermit acquirePermit() |
| S0670 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:48 | void recordSuccess() |
| S0671 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:55 | void recordFailure(PlaybackProviderFailure failure) |
| S0672 | símbolo | app/lib/application/player/providers/provider_circuit_breaker.dart:76 | /// A canceled half-open probe does not prove health or failure; allow a /// later caller to perform the probe without consuming another 60 seconds. void releaseProbe() |
| S0673 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:9 | /// Opt-in automatic skip evaluator. It never invents a segment and only seeks /// through the same coordinator used by manual playback controls. final class AutomaticSkipController |
| S0674 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:12 | AutomaticSkipController({ required this.coordinator, required this.segments, required this.settings, this.fillerEvidence, this.policy = const SkipAutomationPolicy(), }) |
| S0675 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:25 | coordinator |
| S0676 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:26 | segments |
| S0677 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:27 | policy |
| S0678 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:28 | fillerEvidence |
| S0679 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:29 | settings |
| S0680 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:39 | void update({ required SkipAutomationSettings settings, EpisodeFillerEvidence? fillerEvidence, }) |
| S0681 | símbolo | app/lib/application/player/skips/automatic_skip_controller.dart:48 | Future<void> dispose() |
| S0682 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:9 | final class SkipSegmentServiceSnapshot |
| S0683 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:10 | const SkipSegmentServiceSnapshot({ this.loading = false, this.unavailable = false, this.skipping = false, this.segments = const [], this.activeSegment, this.error, this.lastSkipConfirmed = false, }) |
| S0684 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:20 | loading |
| S0685 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:21 | unavailable |
| S0686 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:22 | skipping |
| S0687 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:23 | segments |
| S0688 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:24 | activeSegment |
| S0689 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:25 | error |
| S0690 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:26 | lastSkipConfirmed |
| S0691 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:29 | /// Application bridge between AniSkip/domain segments and the serialized /// coordinator. It owns neither network clients nor the media engine. final class SkipSegmentService |
| S0692 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:32 | SkipSegmentService({ required this.episode, required this.coordinator, required this.catalog, this.malAnimeId, }) |
| S0693 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:41 | episode |
| S0694 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:42 | coordinator |
| S0695 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:43 | catalog |
| S0696 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:44 | malAnimeId |
| S0697 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:53 | SkipSegmentServiceSnapshot get state |
| S0698 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:54 | Stream<SkipSegmentServiceSnapshot> get states |
| S0699 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:56 | Future<void> load() |
| S0700 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:104 | Future<bool> skipCurrent() |
| S0701 | símbolo | app/lib/application/player/skips/skip_segment_service.dart:176 | Future<void> dispose() |
| S0702 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:9 | enum PlaybackSourceSwitchActivity |
| S0703 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:10 | idle |
| S0704 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:11 | resolving |
| S0705 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:12 | switching |
| S0706 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:13 | fallback |
| S0707 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:14 | failed |
| S0708 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:17 | final class PlaybackSourceSwitchSnapshot |
| S0709 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:18 | const PlaybackSourceSwitchSnapshot({ this.activity = PlaybackSourceSwitchActivity.idle, this.current, this.pending, this.error, this.lastPositionDelta, this.failedCandidateCount = 0, }) |
| S0710 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:27 | activity |
| S0711 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:28 | current |
| S0712 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:29 | pending |
| S0713 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:30 | error |
| S0714 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:31 | lastPositionDelta |
| S0715 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:32 | failedCandidateCount |
| S0716 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:35 | enum PlaybackSourceSwitchAttemptStatus |
| S0717 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:36 | switched |
| S0718 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:37 | busy |
| S0719 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:38 | noAlternative |
| S0720 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:39 | failed |
| S0721 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:40 | superseded |
| S0722 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:43 | final class PlaybackSourceSwitchAttempt |
| S0723 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:44 | const PlaybackSourceSwitchAttempt({ required this.status, this.selected, this.positionDelta, this.failedCandidateCount = 0, }) |
| S0724 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:51 | status |
| S0725 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:52 | selected |
| S0726 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:53 | positionDelta |
| S0727 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:54 | failedCandidateCount |
| S0728 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:57 | /// Resolves provider alternatives and asks the existing coordinator to switch. /// It never owns or calls a native Player. final class PlaybackSourceSwitchService |
| S0729 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:60 | factory PlaybackSourceSwitchService({ required PlaybackProviderManager manager, required PlaybackEpisode episode, required SpikePlayerCoordinator coordinator, required ResolvedPlaybackStream initialSource, List<ResolvedPlaybackStream>? authorizedAlternatives, }) |
| S0730 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:102 | PlaybackSourceSwitchSnapshot get state |
| S0731 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:103 | Stream<PlaybackSourceSwitchSnapshot> get states |
| S0732 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:105 | Future<PlaybackSourceSwitchAttempt> switchToNext() |
| S0733 | símbolo | app/lib/application/player/source_switching/playback_source_switch_service.dart:318 | Future<void> dispose() |
| S0734 | símbolo | app/lib/application/player/spike_player_coordinator.dart:11 | /// Serializes the basic F2.2 commands and exposes one coherent state stream. /// It owns subscriptions and the engine lifecycle, but never imports media_kit. final class SpikePlayerCoordinator implements ExternalSubtitleLoader |
| S0735 | símbolo | app/lib/application/player/spike_player_coordinator.dart:14 | SpikePlayerCoordinator( this._engine, { Set<Uri> demoSources = const {}, Set<Uri> trustedExternalSources = const {}, }) : _demoSources = Set.unmodifiable(demoSources), _trustedExternalSources = Set.unmodifiable(trustedExternalSources) |
| S0736 | símbolo | app/lib/application/player/spike_player_coordinator.dart:52 | /// Changes synchronously when an open, source switch, or Stop is requested, /// before its serialized engine operation starts. UI actions use it to /// invalidate track choices created for the preceding media context. int get mediaContextRevision |
| S0737 | símbolo | app/lib/application/player/spike_player_coordinator.dart:63 | Stream<PlaybackSessionSnapshot> get states |
| S0738 | símbolo | app/lib/application/player/spike_player_coordinator.dart:64 | PlaybackSessionSnapshot get state |
| S0739 | símbolo | app/lib/application/player/spike_player_coordinator.dart:66 | Future<void> initialize() |
| S0740 | símbolo | app/lib/application/player/spike_player_coordinator.dart:90 | Future<void> open( Uri source, { PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(), }) |
| S0741 | símbolo | app/lib/application/player/spike_player_coordinator.dart:145 | /// Restores a paused opening and confirms the position from the engine. /// The deadline bounds snapshot waits. An in-flight native seek must settle /// before the caller can safely close or replace the engine. Future<void> restoreStartPosition( Duration target, { required PlaybackCancellationToken cancellation, Duration budget = const Duration(seconds: 12), }) |
| S0742 | símbolo | app/lib/application/player/spike_player_coordinator.dart:224 | /// Changes sources through the existing engine while preserving playback /// position and Play/Pause intent. Native error events still lack source IDs /// in media_kit 1.2.6, so asynchronous errors cannot be perfectly attributed. Future<PlaybackSourceSwitchResult> switchSource( Uri target, { PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(), Duration? referencePosition, bool? resumePlayback, Duration? rollbackPosition, bool preserveTracks = false, }) |
| S0743 | símbolo | app/lib/application/player/spike_player_coordinator.dart:394 | Future<void> play() |
| S0744 | símbolo | app/lib/application/player/spike_player_coordinator.dart:400 | Future<void> pause() |
| S0745 | símbolo | app/lib/application/player/spike_player_coordinator.dart:409 | /// Toggles from the latest serialized playback intent, so rapid keyboard /// presses cannot both choose an action from a stale widget snapshot. Future<void> togglePlayback() |
| S0746 | símbolo | app/lib/application/player/spike_player_coordinator.dart:421 | Future<void> seek(Duration position, {int? generation}) |
| S0747 | símbolo | app/lib/application/player/spike_player_coordinator.dart:438 | /// Applies a relative seek at execution time, after earlier queued seeks. Future<void> seekBy(Duration delta) |
| S0748 | símbolo | app/lib/application/player/spike_player_coordinator.dart:454 | /// Sets player-local volume, clamped to Kongroo's 0–100 range. Future<void> setVolume(double volume) |
| S0749 | símbolo | app/lib/application/player/spike_player_coordinator.dart:463 | /// Applies a relative volume change after earlier queued volume changes. Future<void> adjustVolumeBy(double delta) |
| S0750 | símbolo | app/lib/application/player/spike_player_coordinator.dart:475 | Future<void> selectAudioTrack(String id, {required int generation}) |
| S0751 | símbolo | app/lib/application/player/spike_player_coordinator.dart:489 | /// Selects an actual track in the currently loaded media. A menu opened for /// an earlier source cannot apply its native ID to a replacement source. Future<void> selectVideoTrack(String id, {required int generation}) |
| S0752 | símbolo | app/lib/application/player/spike_player_coordinator.dart:511 | Future<void> selectSubtitleTrack(String id) |
| S0753 | símbolo | app/lib/application/player/spike_player_coordinator.dart:517 | @override Future<ExternalSubtitleDecision> loadExternalSubtitle( Uri source, { required HardsubStatus hardsubStatus, String? title, String? language, int? sourceGeneration, }) |
| S0754 | símbolo | app/lib/application/player/spike_player_coordinator.dart:542 | Future<void> applySubtitleStyle(SubtitleStyle style) |
| S0755 | símbolo | app/lib/application/player/spike_player_coordinator.dart:547 | Future<void> setSubtitleDelay(Duration delay) |
| S0756 | símbolo | app/lib/application/player/spike_player_coordinator.dart:602 | Future<void> stop() |
| S0757 | símbolo | app/lib/application/player/spike_player_coordinator.dart:667 | Future<void> dispose() |
| S0758 | símbolo | app/lib/core/errors/app_error.dart:1 | sealed class AppError |
| S0759 | símbolo | app/lib/core/errors/app_error.dart:2 | const AppError(this.code, this.message) |
| S0760 | símbolo | app/lib/core/errors/app_error.dart:4 | code |
| S0761 | símbolo | app/lib/core/errors/app_error.dart:5 | message |
| S0762 | símbolo | app/lib/core/errors/app_error.dart:7 | @override String toString() |
| S0763 | símbolo | app/lib/core/errors/app_error.dart:11 | final class NetworkError extends AppError |
| S0764 | símbolo | app/lib/core/errors/app_error.dart:12 | const NetworkError([String message = 'Network request failed']) : super('network', message) |
| S0765 | símbolo | app/lib/core/errors/app_error.dart:16 | final class TimeoutAppError extends AppError |
| S0766 | símbolo | app/lib/core/errors/app_error.dart:17 | const TimeoutAppError([String message = 'Operation timed out']) : super('timeout', message) |
| S0767 | símbolo | app/lib/core/errors/app_error.dart:21 | final class RateLimitError extends AppError |
| S0768 | símbolo | app/lib/core/errors/app_error.dart:22 | const RateLimitError({this.retryAfter, String message = 'Rate limited'}) : super('rate_limit', message) |
| S0769 | símbolo | app/lib/core/errors/app_error.dart:25 | retryAfter |
| S0770 | símbolo | app/lib/core/errors/app_error.dart:28 | final class AuthAppError extends AppError |
| S0771 | símbolo | app/lib/core/errors/app_error.dart:29 | const AuthAppError([String message = 'Authentication required']) : super('auth', message) |
| S0772 | símbolo | app/lib/core/errors/app_error.dart:33 | final class ValidationAppError extends AppError |
| S0773 | símbolo | app/lib/core/errors/app_error.dart:34 | const ValidationAppError([String message = 'Input is invalid']) : super('validation', message) |
| S0774 | símbolo | app/lib/core/errors/app_error.dart:38 | final class StorageError extends AppError |
| S0775 | símbolo | app/lib/core/errors/app_error.dart:39 | const StorageError([String message = 'Storage operation failed']) : super('storage', message) |
| S0776 | símbolo | app/lib/core/errors/app_error.dart:43 | final class NotFoundAppError extends AppError |
| S0777 | símbolo | app/lib/core/errors/app_error.dart:44 | const NotFoundAppError([String message = 'Resource not found']) : super('not_found', message) |
| S0778 | símbolo | app/lib/core/errors/app_error.dart:48 | final class UnavailableError extends AppError |
| S0779 | símbolo | app/lib/core/errors/app_error.dart:49 | const UnavailableError([String message = 'Service unavailable']) : super('unavailable', message) |
| S0780 | símbolo | app/lib/core/errors/app_error.dart:53 | final class UnknownAppError extends AppError |
| S0781 | símbolo | app/lib/core/errors/app_error.dart:54 | const UnknownAppError([String message = 'Unexpected failure']) : super('unknown', message) |
| S0782 | símbolo | app/lib/core/logger/safe_logger.dart:5 | enum LogLevel |
| S0783 | símbolo | app/lib/core/logger/safe_logger.dart:5 | debug |
| S0784 | símbolo | app/lib/core/logger/safe_logger.dart:5 | info |
| S0785 | símbolo | app/lib/core/logger/safe_logger.dart:5 | warning |
| S0786 | símbolo | app/lib/core/logger/safe_logger.dart:5 | error |
| S0787 | símbolo | app/lib/core/logger/safe_logger.dart:7 | final class LogRecord |
| S0788 | símbolo | app/lib/core/logger/safe_logger.dart:8 | const LogRecord({ required this.level, required this.code, required this.timestamp, required this.correlationId, required this.fields, }) |
| S0789 | símbolo | app/lib/core/logger/safe_logger.dart:16 | level |
| S0790 | símbolo | app/lib/core/logger/safe_logger.dart:17 | code |
| S0791 | símbolo | app/lib/core/logger/safe_logger.dart:18 | timestamp |
| S0792 | símbolo | app/lib/core/logger/safe_logger.dart:19 | correlationId |
| S0793 | símbolo | app/lib/core/logger/safe_logger.dart:20 | fields |
| S0794 | símbolo | app/lib/core/logger/safe_logger.dart:23 | typedef LogSink = void Function(LogRecord record); |
| S0795 | símbolo | app/lib/core/logger/safe_logger.dart:25 | final class SafeLogger |
| S0796 | símbolo | app/lib/core/logger/safe_logger.dart:26 | SafeLogger({required LogSink sink, DateTime Function()? clock}) : _sinks = [sink], _clock = clock ?? DateTime.now |
| S0797 | símbolo | app/lib/core/logger/safe_logger.dart:34 | void addSink(LogSink sink) |
| S0798 | símbolo | app/lib/core/logger/safe_logger.dart:39 | void log( LogLevel level, String code, { Map<String, Object?> fields = const {}, String? correlationId, }) |
| S0799 | símbolo | app/lib/core/logger/safe_logger.dart:58 | void logError(AppError error, {String? correlationId}) |
| S0800 | símbolo | app/lib/core/logger/safe_logger.dart:67 | void dispose() |
| S0801 | símbolo | app/lib/core/logger/safe_logger.dart:77 | final class MemoryLogSink |
| S0802 | símbolo | app/lib/core/logger/safe_logger.dart:81 | List<LogRecord> get records |
| S0803 | símbolo | app/lib/core/logger/safe_logger.dart:83 | void call(LogRecord record) |
| S0804 | símbolo | app/lib/core/logger/safe_logger.dart:87 | void dispose() |
| S0805 | símbolo | app/lib/core/result/result.dart:3 | sealed class Result<T> |
| S0806 | símbolo | app/lib/core/result/result.dart:4 | const Result() |
| S0807 | símbolo | app/lib/core/result/result.dart:6 | bool get isSuccess |
| S0808 | símbolo | app/lib/core/result/result.dart:8 | R fold<R>( R Function(T value) onSuccess, R Function(AppError error) onFailure, ) |
| S0809 | símbolo | app/lib/core/result/result.dart:16 | Result<R> map<R>(R Function(T value) transform) |
| S0810 | símbolo | app/lib/core/result/result.dart:21 | Result<R> flatMap<R>(Result<R> Function(T value) transform) |
| S0811 | símbolo | app/lib/core/result/result.dart:27 | final class Success<T> extends Result<T> |
| S0812 | símbolo | app/lib/core/result/result.dart:28 | const Success(this.value) |
| S0813 | símbolo | app/lib/core/result/result.dart:30 | value |
| S0814 | símbolo | app/lib/core/result/result.dart:33 | final class Failure<T> extends Result<T> |
| S0815 | símbolo | app/lib/core/result/result.dart:34 | const Failure(this.error) |
| S0816 | símbolo | app/lib/core/result/result.dart:36 | error |
| S0817 | símbolo | app/lib/data/anilist/anilist_client.dart:106 | /// Read-only AniList adapter. Mutations and authenticated requests are absent. class AniListClient implements AnimeCatalogRepository |
| S0818 | símbolo | app/lib/data/anilist/anilist_client.dart:110 | AniListClient({ Dio? dio, Duration? requestTimeout, AniListRateLimiter? rateLimiter, }) : _ownsDio = dio == null, _dio = dio ?? _createDio(requestTimeout ?? const Duration(seconds: 10)), _rateLimiter = rateLimiter ?? _sharedRateLimiter |
| S0819 | símbolo | app/lib/data/anilist/anilist_client.dart:122 | void close() |
| S0820 | símbolo | app/lib/data/anilist/anilist_client.dart:128 | @override Future<Result<AnimeSearchResult>> searchAnimeById(int id) |
| S0821 | símbolo | app/lib/data/anilist/anilist_client.dart:161 | @override Future<Result<AnimeSearchResult>> searchAnime( String search, { int page = 1, int perPage = 20, }) |
| S0822 | símbolo | app/lib/data/anilist/anilist_client.dart:206 | @override Future<Result<AnimeSearchResult>> browseAnime({ AnimeBrowseSort sort = AnimeBrowseSort.popular, int page = 1, int perPage = 20, }) |
| S0823 | símbolo | app/lib/data/anilist/anilist_client.dart:506 | /// Shared per-process request gate. Separate adapters should share this gate. class AniListRateLimiter |
| S0824 | símbolo | app/lib/data/anilist/anilist_client.dart:508 | AniListRateLimiter({ DateTime Function()? clock, Future<void> Function(Duration duration)? delay, }) : _clock = clock ?? DateTime.now, _delay = delay ?? _defaultDelay |
| S0825 | símbolo | app/lib/data/anilist/anilist_client.dart:521 | Future<void> waitForRequestSlot() |
| S0826 | símbolo | app/lib/data/anilist/anilist_client.dart:550 | void updateRateLimit(Headers headers) |
| S0827 | símbolo | app/lib/data/anilist/anilist_client.dart:568 | RateLimitError rateLimitError(Headers headers) |
| S0828 | símbolo | app/lib/data/anilist/anilist_detail_fields.dart:4 | AnimeDetailMetadata decodeAniListDetails(Map<Object?, Object?> media) |
| S0829 | símbolo | app/lib/data/anilist/anilist_detail_fields.dart:109 | Map<String, Object?> encodeAniListDetails(AnimeDetailMetadata details) |
| S0830 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:12 | /// Provider-neutral mapping of the existing public AniList read client. final class AniListMetadataProvider implements MetadataProvider, PublicAnimeBrowseProvider, CachedAnimeMetadataProvider |
| S0831 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:18 | AniListMetadataProvider(this.repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now |
| S0832 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:21 | providerId = MetadataProviderId('anilist') |
| S0833 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:22 | repository |
| S0834 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:25 | @override MetadataProviderId get id |
| S0835 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:27 | @override Set<MetadataCapability> get capabilities |
| S0836 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:34 | @override Future<ProviderResult<List<ProviderAnimeMetadata>>> searchAnime( String query, { int limit = 20, }) |
| S0837 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:46 | Future<ProviderResult<List<ProviderAnimeMetadata>>> browse({ AnimeBrowseSort sort = AnimeBrowseSort.popular, int limit = 20, }) |
| S0838 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:53 | @override Future<ProviderResult<List<ProviderAnimeMetadata>>> browsePopular({ int limit = 20, }) |
| S0839 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:58 | @override Future<ProviderResult<List<ProviderAnimeMetadata>>> browseTrending({ int limit = 20, }) |
| S0840 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:63 | @override Future<ProviderAnimeMetadata?> readCachedAnime(ExternalAnimeId id) |
| S0841 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:77 | @override Future<ProviderResult<ProviderAnimeMetadata>> getAnimeByExternalId( ExternalAnimeId id, ) |
| S0842 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:96 | @override Future<ProviderResult<List<ProviderEpisodeMetadata>>> getEpisodes( ExternalAnimeId animeId, ) |
| S0843 | símbolo | app/lib/data/anilist/anilist_metadata_provider.dart:130 | @override Future<ProviderResult<ProviderHealth>> checkHealth() |
| S0844 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:5 | /// Bounded storage for public popular/trending pages. Keeps the newest /// [maxFeeds] keys; payloads are normalized AniList summaries, never URLs with /// signatures or account data. final class DriftAniListBrowseCache |
| S0845 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:9 | const DriftAniListBrowseCache(this.database) |
| S0846 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:11 | database |
| S0847 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:13 | maxFeeds = 16 |
| S0848 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:15 | Future<({String payload, DateTime fetchedAt})?> read(String feedKey) |
| S0849 | símbolo | app/lib/data/anilist/drift_anilist_browse_cache.dart:32 | Future<void> write(String feedKey, String payload, DateTime fetchedAt) |
| S0850 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:12 | /// Keeps the latest search and a bounded cache of requested details. class OfflineFirstAnimeCatalog implements AnimeCatalogRepository, CachedAnimeCatalog |
| S0851 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:15 | OfflineFirstAnimeCatalog({ required this.remote, required this.database, DateTime Function()? clock, }) : _clock = clock ?? DateTime.now, _details = DriftAniListDetailCache(database) |
| S0852 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:24 | remote |
| S0853 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:25 | database |
| S0854 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:54 | @override Future<AnimeSummary?> readCachedAnime(int id) |
| S0855 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:58 | @override Future<Result<AnimeSearchResult>> searchAnimeById(int id) |
| S0856 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:112 | @override Future<Result<AnimeSearchResult>> searchAnime( String search, { int page = 1, int perPage = 20, }) |
| S0857 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:163 | browseTtl = Duration(minutes: 30) |
| S0858 | símbolo | app/lib/data/anilist/offline_first_anime_catalog.dart:165 | @override Future<Result<AnimeSearchResult>> browseAnime({ AnimeBrowseSort sort = AnimeBrowseSort.popular, int page = 1, int perPage = 20, }) |
| S0859 | símbolo | app/lib/data/aniskip/aniskip_client.dart:11 | typedef AniSkipClock = DateTime Function(); |
| S0860 | símbolo | app/lib/data/aniskip/aniskip_client.dart:13 | /// Read-only AniSkip v1 adapter. Unknown API types are ignored; only `op` and /// `ed` are mapped because the official contract documents opening/endings. final class AniSkipClient implements SkipSegmentCatalog |
| S0861 | símbolo | app/lib/data/aniskip/aniskip_client.dart:16 | factory AniSkipClient({ Dio? dio, required AniSkipResponseCache cache, AniSkipClock? clock, }) |
| S0862 | símbolo | app/lib/data/aniskip/aniskip_client.dart:28 | cacheTtl = Duration(days: 7) |
| S0863 | símbolo | app/lib/data/aniskip/aniskip_client.dart:45 | void close() |
| S0864 | símbolo | app/lib/data/aniskip/aniskip_client.dart:49 | String cacheKey(MyAnimeListAnimeId id, PlaybackEpisode episode) |
| S0865 | símbolo | app/lib/data/aniskip/aniskip_client.dart:52 | @override Future<SkipCatalogResult> lookup({ required PlaybackEpisode episode, required MyAnimeListAnimeId malAnimeId, }) |
| S0866 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:6 | final class CachedAniSkipResponse |
| S0867 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:7 | const CachedAniSkipResponse({ required this.body, required this.retrievedAt, required this.expiresAt, }) |
| S0868 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:12 | body |
| S0869 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:13 | retrievedAt |
| S0870 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:14 | expiresAt |
| S0871 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:17 | abstract interface class AniSkipResponseCache |
| S0872 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:18 | Future<CachedAniSkipResponse?> read(String key) |
| S0873 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:19 | Future<void> write(String key, CachedAniSkipResponse response) |
| S0874 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:20 | Future<void> invalidate(String key) |
| S0875 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:23 | typedef AniSkipCacheDirectory = Future<Directory> Function(); |
| S0876 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:25 | /// Small atomic file cache; cache filenames are derived only from numeric IDs. final class FileAniSkipResponseCache implements AniSkipResponseCache |
| S0877 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:27 | factory FileAniSkipResponseCache({ Directory? directory, AniSkipCacheDirectory? directoryProvider, }) |
| S0878 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:37 | maxEntryBytes = 512 * 1024 |
| S0879 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:38 | contractVersion = 1 |
| S0880 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:42 | @override Future<CachedAniSkipResponse?> read(String key) |
| S0881 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:87 | @override Future<void> write(String key, CachedAniSkipResponse response) |
| S0882 | símbolo | app/lib/data/aniskip/aniskip_response_cache.dart:112 | @override Future<void> invalidate(String key) |
| S0883 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:9 | /// Public Kitsu episode index, reached without an account. AniList IDs are /// mapped through Kitsu's public `mappings` endpoint; only episode numbers, /// titles and HTTPS thumbnails are read. No playable URL is requested. final class KitsuEpisodeIndex implements EpisodeIndexProvider |
| S0884 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:13 | KitsuEpisodeIndex({ required this._dio, DateTime Function()? clock, this.cacheTtl = const Duration(hours: 6), }) : _clock = clock ?? DateTime.now |
| S0885 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:19 | factory KitsuEpisodeIndex.public({DateTime Function()? clock}) |
| S0886 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:32 | providerId = MetadataProviderId('kitsu') |
| S0887 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:38 | cacheTtl |
| S0888 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:42 | @override MetadataProviderId get id |
| S0889 | símbolo | app/lib/data/kitsu/kitsu_episode_index.dart:45 | @override Future<ProviderResult<EpisodeIndexPage>> listEpisodes( ExternalAnimeId anime, { int offset = 0, int limit = 20, }) |
| S0890 | símbolo | app/lib/data/local_db/app_database.dart:18 | @DriftDatabase( tables: [ SettingsEntries, ProgressDocuments, LatestAnimeSearch, PlaybackProgressEntries, AnimeIdentityEntries, ExternalAnimeIdentifiers, AnimeIdentityRelationships, LocalLibraryEntries, ], ) class AppDatabase extends _$AppDatabase |
| S0891 | símbolo | app/lib/data/local_db/app_database.dart:31 | AppDatabase(super.executor) |
| S0892 | símbolo | app/lib/data/local_db/app_database.dart:33 | /// Opens the app database in the user's application support directory. factory AppDatabase.open() |
| S0893 | símbolo | app/lib/data/local_db/app_database.dart:36 | /// Opens an explicit file, primarily for isolated integration tests. factory AppDatabase.atFile(File file) |
| S0894 | símbolo | app/lib/data/local_db/app_database.dart:39 | @override int get schemaVersion |
| S0895 | símbolo | app/lib/data/local_db/app_database.dart:58 | @override MigrationStrategy get migration |
| S0896 | símbolo | app/lib/data/local_db/app_database.g.dart:6 | class $SettingsEntriesTable extends SettingsEntries with TableInfo<$SettingsEntriesTable, SettingsEntry> |
| S0897 | símbolo | app/lib/data/local_db/app_database.g.dart:9 | attachedDatabase |
| S0898 | símbolo | app/lib/data/local_db/app_database.g.dart:11 | $SettingsEntriesTable(this.attachedDatabase, [this._alias]) |
| S0899 | símbolo | app/lib/data/local_db/app_database.g.dart:16 | settingKey = GeneratedColumn<String>( 'setting_key', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S0900 | símbolo | app/lib/data/local_db/app_database.g.dart:27 | valueJson = GeneratedColumn<String>( 'value_json', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S0901 | símbolo | app/lib/data/local_db/app_database.g.dart:38 | updatedAt = GeneratedColumn<DateTime>( 'updated_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true, ) |
| S0902 | símbolo | app/lib/data/local_db/app_database.g.dart:45 | @override List<GeneratedColumn> get $columns |
| S0903 | símbolo | app/lib/data/local_db/app_database.g.dart:47 | @override String get aliasedName |
| S0904 | símbolo | app/lib/data/local_db/app_database.g.dart:49 | @override String get actualTableName |
| S0905 | símbolo | app/lib/data/local_db/app_database.g.dart:51 | $name = 'settings_entries' |
| S0906 | símbolo | app/lib/data/local_db/app_database.g.dart:52 | @override VerificationContext validateIntegrity( Insertable<SettingsEntry> instance, { bool isInserting = false, }) |
| S0907 | símbolo | app/lib/data/local_db/app_database.g.dart:86 | @override Set<GeneratedColumn> get $primaryKey |
| S0908 | símbolo | app/lib/data/local_db/app_database.g.dart:88 | @override SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) |
| S0909 | símbolo | app/lib/data/local_db/app_database.g.dart:107 | @override $SettingsEntriesTable createAlias(String alias) |
| S0910 | símbolo | app/lib/data/local_db/app_database.g.dart:113 | class SettingsEntry extends DataClass implements Insertable<SettingsEntry> |
| S0911 | símbolo | app/lib/data/local_db/app_database.g.dart:114 | settingKey |
| S0912 | símbolo | app/lib/data/local_db/app_database.g.dart:115 | valueJson |
| S0913 | símbolo | app/lib/data/local_db/app_database.g.dart:116 | updatedAt |
| S0914 | símbolo | app/lib/data/local_db/app_database.g.dart:117 | const SettingsEntry({ required this.settingKey, required this.valueJson, required this.updatedAt, }) |
| S0915 | símbolo | app/lib/data/local_db/app_database.g.dart:122 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S0916 | símbolo | app/lib/data/local_db/app_database.g.dart:131 | SettingsEntriesCompanion toCompanion(bool nullToAbsent) |
| S0917 | símbolo | app/lib/data/local_db/app_database.g.dart:139 | factory SettingsEntry.fromJson( Map<String, dynamic> json, { ValueSerializer? serializer, }) |
| S0918 | símbolo | app/lib/data/local_db/app_database.g.dart:150 | @override Map<String, dynamic> toJson({ValueSerializer? serializer}) |
| S0919 | símbolo | app/lib/data/local_db/app_database.g.dart:160 | SettingsEntry copyWith({ String? settingKey, String? valueJson, DateTime? updatedAt, }) |
| S0920 | símbolo | app/lib/data/local_db/app_database.g.dart:169 | SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) |
| S0921 | símbolo | app/lib/data/local_db/app_database.g.dart:179 | @override String toString() |
| S0922 | símbolo | app/lib/data/local_db/app_database.g.dart:189 | @override int get hashCode |
| S0923 | símbolo | app/lib/data/local_db/app_database.g.dart:191 | @override bool operator ==(Object other) |
| S0924 | símbolo | app/lib/data/local_db/app_database.g.dart:200 | class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> |
| S0925 | símbolo | app/lib/data/local_db/app_database.g.dart:201 | settingKey |
| S0926 | símbolo | app/lib/data/local_db/app_database.g.dart:202 | valueJson |
| S0927 | símbolo | app/lib/data/local_db/app_database.g.dart:203 | updatedAt |
| S0928 | símbolo | app/lib/data/local_db/app_database.g.dart:204 | rowid |
| S0929 | símbolo | app/lib/data/local_db/app_database.g.dart:205 | const SettingsEntriesCompanion({ this.settingKey = const Value.absent(), this.valueJson = const Value.absent(), this.updatedAt = const Value.absent(), this.rowid = const Value.absent(), }) |
| S0930 | símbolo | app/lib/data/local_db/app_database.g.dart:211 | SettingsEntriesCompanion.insert({ required String settingKey, required String valueJson, required DateTime updatedAt, this.rowid = const Value.absent(), }) : settingKey = Value(settingKey), valueJson = Value(valueJson), updatedAt = Value(updatedAt) |
| S0931 | símbolo | app/lib/data/local_db/app_database.g.dart:219 | static Insertable<SettingsEntry> custom({ Expression<String>? settingKey, Expression<String>? valueJson, Expression<DateTime>? updatedAt, Expression<int>? rowid, }) |
| S0932 | símbolo | app/lib/data/local_db/app_database.g.dart:233 | SettingsEntriesCompanion copyWith({ Value<String>? settingKey, Value<String>? valueJson, Value<DateTime>? updatedAt, Value<int>? rowid, }) |
| S0933 | símbolo | app/lib/data/local_db/app_database.g.dart:247 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S0934 | símbolo | app/lib/data/local_db/app_database.g.dart:265 | @override String toString() |
| S0935 | símbolo | app/lib/data/local_db/app_database.g.dart:277 | class $ProgressDocumentsTable extends ProgressDocuments with TableInfo<$ProgressDocumentsTable, ProgressDocument> |
| S0936 | símbolo | app/lib/data/local_db/app_database.g.dart:280 | attachedDatabase |
| S0937 | símbolo | app/lib/data/local_db/app_database.g.dart:282 | $ProgressDocumentsTable(this.attachedDatabase, [this._alias]) |
| S0938 | símbolo | app/lib/data/local_db/app_database.g.dart:287 | documentKey = GeneratedColumn<String>( 'document_key', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S0939 | símbolo | app/lib/data/local_db/app_database.g.dart:298 | payloadJson = GeneratedColumn<String>( 'payload_json', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S0940 | símbolo | app/lib/data/local_db/app_database.g.dart:309 | updatedAt = GeneratedColumn<DateTime>( 'updated_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true, ) |
| S0941 | símbolo | app/lib/data/local_db/app_database.g.dart:316 | @override List<GeneratedColumn> get $columns |
| S0942 | símbolo | app/lib/data/local_db/app_database.g.dart:318 | @override String get aliasedName |
| S0943 | símbolo | app/lib/data/local_db/app_database.g.dart:320 | @override String get actualTableName |
| S0944 | símbolo | app/lib/data/local_db/app_database.g.dart:322 | $name = 'progress_documents' |
| S0945 | símbolo | app/lib/data/local_db/app_database.g.dart:323 | @override VerificationContext validateIntegrity( Insertable<ProgressDocument> instance, { bool isInserting = false, }) |
| S0946 | símbolo | app/lib/data/local_db/app_database.g.dart:363 | @override Set<GeneratedColumn> get $primaryKey |
| S0947 | símbolo | app/lib/data/local_db/app_database.g.dart:365 | @override ProgressDocument map(Map<String, dynamic> data, {String? tablePrefix}) |
| S0948 | símbolo | app/lib/data/local_db/app_database.g.dart:384 | @override $ProgressDocumentsTable createAlias(String alias) |
| S0949 | símbolo | app/lib/data/local_db/app_database.g.dart:390 | class ProgressDocument extends DataClass implements Insertable<ProgressDocument> |
| S0950 | símbolo | app/lib/data/local_db/app_database.g.dart:392 | documentKey |
| S0951 | símbolo | app/lib/data/local_db/app_database.g.dart:393 | payloadJson |
| S0952 | símbolo | app/lib/data/local_db/app_database.g.dart:394 | updatedAt |
| S0953 | símbolo | app/lib/data/local_db/app_database.g.dart:395 | const ProgressDocument({ required this.documentKey, required this.payloadJson, required this.updatedAt, }) |
| S0954 | símbolo | app/lib/data/local_db/app_database.g.dart:400 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S0955 | símbolo | app/lib/data/local_db/app_database.g.dart:409 | ProgressDocumentsCompanion toCompanion(bool nullToAbsent) |
| S0956 | símbolo | app/lib/data/local_db/app_database.g.dart:417 | factory ProgressDocument.fromJson( Map<String, dynamic> json, { ValueSerializer? serializer, }) |
| S0957 | símbolo | app/lib/data/local_db/app_database.g.dart:428 | @override Map<String, dynamic> toJson({ValueSerializer? serializer}) |
| S0958 | símbolo | app/lib/data/local_db/app_database.g.dart:438 | ProgressDocument copyWith({ String? documentKey, String? payloadJson, DateTime? updatedAt, }) |
| S0959 | símbolo | app/lib/data/local_db/app_database.g.dart:447 | ProgressDocument copyWithCompanion(ProgressDocumentsCompanion data) |
| S0960 | símbolo | app/lib/data/local_db/app_database.g.dart:459 | @override String toString() |
| S0961 | símbolo | app/lib/data/local_db/app_database.g.dart:469 | @override int get hashCode |
| S0962 | símbolo | app/lib/data/local_db/app_database.g.dart:471 | @override bool operator ==(Object other) |
| S0963 | símbolo | app/lib/data/local_db/app_database.g.dart:480 | class ProgressDocumentsCompanion extends UpdateCompanion<ProgressDocument> |
| S0964 | símbolo | app/lib/data/local_db/app_database.g.dart:481 | documentKey |
| S0965 | símbolo | app/lib/data/local_db/app_database.g.dart:482 | payloadJson |
| S0966 | símbolo | app/lib/data/local_db/app_database.g.dart:483 | updatedAt |
| S0967 | símbolo | app/lib/data/local_db/app_database.g.dart:484 | rowid |
| S0968 | símbolo | app/lib/data/local_db/app_database.g.dart:485 | const ProgressDocumentsCompanion({ this.documentKey = const Value.absent(), this.payloadJson = const Value.absent(), this.updatedAt = const Value.absent(), this.rowid = const Value.absent(), }) |
| S0969 | símbolo | app/lib/data/local_db/app_database.g.dart:491 | ProgressDocumentsCompanion.insert({ required String documentKey, required String payloadJson, required DateTime updatedAt, this.rowid = const Value.absent(), }) : documentKey = Value(documentKey), payloadJson = Value(payloadJson), updatedAt = Value(updatedAt) |
| S0970 | símbolo | app/lib/data/local_db/app_database.g.dart:499 | static Insertable<ProgressDocument> custom({ Expression<String>? documentKey, Expression<String>? payloadJson, Expression<DateTime>? updatedAt, Expression<int>? rowid, }) |
| S0971 | símbolo | app/lib/data/local_db/app_database.g.dart:513 | ProgressDocumentsCompanion copyWith({ Value<String>? documentKey, Value<String>? payloadJson, Value<DateTime>? updatedAt, Value<int>? rowid, }) |
| S0972 | símbolo | app/lib/data/local_db/app_database.g.dart:527 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S0973 | símbolo | app/lib/data/local_db/app_database.g.dart:545 | @override String toString() |
| S0974 | símbolo | app/lib/data/local_db/app_database.g.dart:557 | class $LatestAnimeSearchTable extends LatestAnimeSearch with TableInfo<$LatestAnimeSearchTable, LatestAnimeSearchData> |
| S0975 | símbolo | app/lib/data/local_db/app_database.g.dart:560 | attachedDatabase |
| S0976 | símbolo | app/lib/data/local_db/app_database.g.dart:562 | $LatestAnimeSearchTable(this.attachedDatabase, [this._alias]) |
| S0977 | símbolo | app/lib/data/local_db/app_database.g.dart:565 | slot = GeneratedColumn<String>( 'slot', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S0978 | símbolo | app/lib/data/local_db/app_database.g.dart:576 | searchQuery = GeneratedColumn<String>( 'search_query', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S0979 | símbolo | app/lib/data/local_db/app_database.g.dart:585 | page = GeneratedColumn<int>( 'page', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true, ) |
| S0980 | símbolo | app/lib/data/local_db/app_database.g.dart:596 | perPage = GeneratedColumn<int>( 'per_page', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true, ) |
| S0981 | símbolo | app/lib/data/local_db/app_database.g.dart:607 | resultJson = GeneratedColumn<String>( 'result_json', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S0982 | símbolo | app/lib/data/local_db/app_database.g.dart:618 | cachedAt = GeneratedColumn<DateTime>( 'cached_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true, ) |
| S0983 | símbolo | app/lib/data/local_db/app_database.g.dart:625 | @override List<GeneratedColumn> get $columns |
| S0984 | símbolo | app/lib/data/local_db/app_database.g.dart:634 | @override String get aliasedName |
| S0985 | símbolo | app/lib/data/local_db/app_database.g.dart:636 | @override String get actualTableName |
| S0986 | símbolo | app/lib/data/local_db/app_database.g.dart:638 | $name = 'latest_anime_search' |
| S0987 | símbolo | app/lib/data/local_db/app_database.g.dart:639 | @override VerificationContext validateIntegrity( Insertable<LatestAnimeSearchData> instance, { bool isInserting = false, }) |
| S0988 | símbolo | app/lib/data/local_db/app_database.g.dart:700 | @override Set<GeneratedColumn> get $primaryKey |
| S0989 | símbolo | app/lib/data/local_db/app_database.g.dart:702 | @override LatestAnimeSearchData map(Map<String, dynamic> data, {String? tablePrefix}) |
| S0990 | símbolo | app/lib/data/local_db/app_database.g.dart:733 | @override $LatestAnimeSearchTable createAlias(String alias) |
| S0991 | símbolo | app/lib/data/local_db/app_database.g.dart:739 | class LatestAnimeSearchData extends DataClass implements Insertable<LatestAnimeSearchData> |
| S0992 | símbolo | app/lib/data/local_db/app_database.g.dart:741 | slot |
| S0993 | símbolo | app/lib/data/local_db/app_database.g.dart:742 | searchQuery |
| S0994 | símbolo | app/lib/data/local_db/app_database.g.dart:743 | page |
| S0995 | símbolo | app/lib/data/local_db/app_database.g.dart:744 | perPage |
| S0996 | símbolo | app/lib/data/local_db/app_database.g.dart:745 | resultJson |
| S0997 | símbolo | app/lib/data/local_db/app_database.g.dart:746 | cachedAt |
| S0998 | símbolo | app/lib/data/local_db/app_database.g.dart:747 | const LatestAnimeSearchData({ required this.slot, required this.searchQuery, required this.page, required this.perPage, required this.resultJson, required this.cachedAt, }) |
| S0999 | símbolo | app/lib/data/local_db/app_database.g.dart:755 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1000 | símbolo | app/lib/data/local_db/app_database.g.dart:767 | LatestAnimeSearchCompanion toCompanion(bool nullToAbsent) |
| S1001 | símbolo | app/lib/data/local_db/app_database.g.dart:778 | factory LatestAnimeSearchData.fromJson( Map<String, dynamic> json, { ValueSerializer? serializer, }) |
| S1002 | símbolo | app/lib/data/local_db/app_database.g.dart:792 | @override Map<String, dynamic> toJson({ValueSerializer? serializer}) |
| S1003 | símbolo | app/lib/data/local_db/app_database.g.dart:805 | LatestAnimeSearchData copyWith({ String? slot, String? searchQuery, int? page, int? perPage, String? resultJson, DateTime? cachedAt, }) |
| S1004 | símbolo | app/lib/data/local_db/app_database.g.dart:820 | LatestAnimeSearchData copyWithCompanion(LatestAnimeSearchCompanion data) |
| S1005 | símbolo | app/lib/data/local_db/app_database.g.dart:835 | @override String toString() |
| S1006 | símbolo | app/lib/data/local_db/app_database.g.dart:848 | @override int get hashCode |
| S1007 | símbolo | app/lib/data/local_db/app_database.g.dart:851 | @override bool operator ==(Object other) |
| S1008 | símbolo | app/lib/data/local_db/app_database.g.dart:863 | class LatestAnimeSearchCompanion extends UpdateCompanion<LatestAnimeSearchData> |
| S1009 | símbolo | app/lib/data/local_db/app_database.g.dart:865 | slot |
| S1010 | símbolo | app/lib/data/local_db/app_database.g.dart:866 | searchQuery |
| S1011 | símbolo | app/lib/data/local_db/app_database.g.dart:867 | page |
| S1012 | símbolo | app/lib/data/local_db/app_database.g.dart:868 | perPage |
| S1013 | símbolo | app/lib/data/local_db/app_database.g.dart:869 | resultJson |
| S1014 | símbolo | app/lib/data/local_db/app_database.g.dart:870 | cachedAt |
| S1015 | símbolo | app/lib/data/local_db/app_database.g.dart:871 | rowid |
| S1016 | símbolo | app/lib/data/local_db/app_database.g.dart:872 | const LatestAnimeSearchCompanion({ this.slot = const Value.absent(), this.searchQuery = const Value.absent(), this.page = const Value.absent(), this.perPage = const Value.absent(), this.resultJson = const Value.absent(), this.cachedAt = const Value.absent(), this.rowid = const Value.absent(), }) |
| S1017 | símbolo | app/lib/data/local_db/app_database.g.dart:881 | LatestAnimeSearchCompanion.insert({ required String slot, required String searchQuery, required int page, required int perPage, required String resultJson, required DateTime cachedAt, this.rowid = const Value.absent(), }) : slot = Value(slot), searchQuery = Value(searchQuery), page = Value(page), perPage = Value(perPage), resultJson = Value(resultJson), cachedAt = Value(cachedAt) |
| S1018 | símbolo | app/lib/data/local_db/app_database.g.dart:895 | static Insertable<LatestAnimeSearchData> custom({ Expression<String>? slot, Expression<String>? searchQuery, Expression<int>? page, Expression<int>? perPage, Expression<String>? resultJson, Expression<DateTime>? cachedAt, Expression<int>? rowid, }) |
| S1019 | símbolo | app/lib/data/local_db/app_database.g.dart:915 | LatestAnimeSearchCompanion copyWith({ Value<String>? slot, Value<String>? searchQuery, Value<int>? page, Value<int>? perPage, Value<String>? resultJson, Value<DateTime>? cachedAt, Value<int>? rowid, }) |
| S1020 | símbolo | app/lib/data/local_db/app_database.g.dart:935 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1021 | símbolo | app/lib/data/local_db/app_database.g.dart:962 | @override String toString() |
| S1022 | símbolo | app/lib/data/local_db/app_database.g.dart:977 | class $PlaybackProgressEntriesTable extends PlaybackProgressEntries with TableInfo<$PlaybackProgressEntriesTable, PlaybackProgressEntry> |
| S1023 | símbolo | app/lib/data/local_db/app_database.g.dart:980 | attachedDatabase |
| S1024 | símbolo | app/lib/data/local_db/app_database.g.dart:982 | $PlaybackProgressEntriesTable(this.attachedDatabase, [this._alias]) |
| S1025 | símbolo | app/lib/data/local_db/app_database.g.dart:987 | contentId = GeneratedColumn<String>( 'content_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1026 | símbolo | app/lib/data/local_db/app_database.g.dart:998 | episodeId = GeneratedColumn<String>( 'episode_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1027 | símbolo | app/lib/data/local_db/app_database.g.dart:1009 | positionMs = GeneratedColumn<int>( 'position_ms', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true, ) |
| S1028 | símbolo | app/lib/data/local_db/app_database.g.dart:1020 | durationMs = GeneratedColumn<int>( 'duration_ms', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false, ) |
| S1029 | símbolo | app/lib/data/local_db/app_database.g.dart:1031 | updatedAtUtc = GeneratedColumn<DateTime>( 'updated_at_utc', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true, ) |
| S1030 | símbolo | app/lib/data/local_db/app_database.g.dart:1042 | completion = GeneratedColumn<String>( 'completion', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1031 | símbolo | app/lib/data/local_db/app_database.g.dart:1053 | revision = GeneratedColumn<int>( 'revision', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0), ) |
| S1032 | símbolo | app/lib/data/local_db/app_database.g.dart:1061 | @override List<GeneratedColumn> get $columns |
| S1033 | símbolo | app/lib/data/local_db/app_database.g.dart:1071 | @override String get aliasedName |
| S1034 | símbolo | app/lib/data/local_db/app_database.g.dart:1073 | @override String get actualTableName |
| S1035 | símbolo | app/lib/data/local_db/app_database.g.dart:1075 | $name = 'playback_progress_entries' |
| S1036 | símbolo | app/lib/data/local_db/app_database.g.dart:1076 | @override VerificationContext validateIntegrity( Insertable<PlaybackProgressEntry> instance, { bool isInserting = false, }) |
| S1037 | símbolo | app/lib/data/local_db/app_database.g.dart:1141 | @override Set<GeneratedColumn> get $primaryKey |
| S1038 | símbolo | app/lib/data/local_db/app_database.g.dart:1143 | @override PlaybackProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) |
| S1039 | símbolo | app/lib/data/local_db/app_database.g.dart:1178 | @override $PlaybackProgressEntriesTable createAlias(String alias) |
| S1040 | símbolo | app/lib/data/local_db/app_database.g.dart:1184 | class PlaybackProgressEntry extends DataClass implements Insertable<PlaybackProgressEntry> |
| S1041 | símbolo | app/lib/data/local_db/app_database.g.dart:1186 | contentId |
| S1042 | símbolo | app/lib/data/local_db/app_database.g.dart:1187 | episodeId |
| S1043 | símbolo | app/lib/data/local_db/app_database.g.dart:1188 | positionMs |
| S1044 | símbolo | app/lib/data/local_db/app_database.g.dart:1189 | durationMs |
| S1045 | símbolo | app/lib/data/local_db/app_database.g.dart:1190 | updatedAtUtc |
| S1046 | símbolo | app/lib/data/local_db/app_database.g.dart:1191 | completion |
| S1047 | símbolo | app/lib/data/local_db/app_database.g.dart:1192 | revision |
| S1048 | símbolo | app/lib/data/local_db/app_database.g.dart:1193 | const PlaybackProgressEntry({ required this.contentId, required this.episodeId, required this.positionMs, this.durationMs, required this.updatedAtUtc, required this.completion, required this.revision, }) |
| S1049 | símbolo | app/lib/data/local_db/app_database.g.dart:1202 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1050 | símbolo | app/lib/data/local_db/app_database.g.dart:1217 | PlaybackProgressEntriesCompanion toCompanion(bool nullToAbsent) |
| S1051 | símbolo | app/lib/data/local_db/app_database.g.dart:1231 | factory PlaybackProgressEntry.fromJson( Map<String, dynamic> json, { ValueSerializer? serializer, }) |
| S1052 | símbolo | app/lib/data/local_db/app_database.g.dart:1246 | @override Map<String, dynamic> toJson({ValueSerializer? serializer}) |
| S1053 | símbolo | app/lib/data/local_db/app_database.g.dart:1260 | PlaybackProgressEntry copyWith({ String? contentId, String? episodeId, int? positionMs, Value<int?> durationMs = const Value.absent(), DateTime? updatedAtUtc, String? completion, int? revision, }) |
| S1054 | símbolo | app/lib/data/local_db/app_database.g.dart:1277 | PlaybackProgressEntry copyWithCompanion( PlaybackProgressEntriesCompanion data, ) |
| S1055 | símbolo | app/lib/data/local_db/app_database.g.dart:1299 | @override String toString() |
| S1056 | símbolo | app/lib/data/local_db/app_database.g.dart:1313 | @override int get hashCode |
| S1057 | símbolo | app/lib/data/local_db/app_database.g.dart:1323 | @override bool operator ==(Object other) |
| S1058 | símbolo | app/lib/data/local_db/app_database.g.dart:1336 | class PlaybackProgressEntriesCompanion extends UpdateCompanion<PlaybackProgressEntry> |
| S1059 | símbolo | app/lib/data/local_db/app_database.g.dart:1338 | contentId |
| S1060 | símbolo | app/lib/data/local_db/app_database.g.dart:1339 | episodeId |
| S1061 | símbolo | app/lib/data/local_db/app_database.g.dart:1340 | positionMs |
| S1062 | símbolo | app/lib/data/local_db/app_database.g.dart:1341 | durationMs |
| S1063 | símbolo | app/lib/data/local_db/app_database.g.dart:1342 | updatedAtUtc |
| S1064 | símbolo | app/lib/data/local_db/app_database.g.dart:1343 | completion |
| S1065 | símbolo | app/lib/data/local_db/app_database.g.dart:1344 | revision |
| S1066 | símbolo | app/lib/data/local_db/app_database.g.dart:1345 | rowid |
| S1067 | símbolo | app/lib/data/local_db/app_database.g.dart:1346 | const PlaybackProgressEntriesCompanion({ this.contentId = const Value.absent(), this.episodeId = const Value.absent(), this.positionMs = const Value.absent(), this.durationMs = const Value.absent(), this.updatedAtUtc = const Value.absent(), this.completion = const Value.absent(), this.revision = const Value.absent(), this.rowid = const Value.absent(), }) |
| S1068 | símbolo | app/lib/data/local_db/app_database.g.dart:1356 | PlaybackProgressEntriesCompanion.insert({ required String contentId, required String episodeId, required int positionMs, this.durationMs = const Value.absent(), required DateTime updatedAtUtc, required String completion, this.revision = const Value.absent(), this.rowid = const Value.absent(), }) : contentId = Value(contentId), episodeId = Value(episodeId), positionMs = Value(positionMs), updatedAtUtc = Value(updatedAtUtc), completion = Value(completion) |
| S1069 | símbolo | app/lib/data/local_db/app_database.g.dart:1370 | static Insertable<PlaybackProgressEntry> custom({ Expression<String>? contentId, Expression<String>? episodeId, Expression<int>? positionMs, Expression<int>? durationMs, Expression<DateTime>? updatedAtUtc, Expression<String>? completion, Expression<int>? revision, Expression<int>? rowid, }) |
| S1070 | símbolo | app/lib/data/local_db/app_database.g.dart:1392 | PlaybackProgressEntriesCompanion copyWith({ Value<String>? contentId, Value<String>? episodeId, Value<int>? positionMs, Value<int?>? durationMs, Value<DateTime>? updatedAtUtc, Value<String>? completion, Value<int>? revision, Value<int>? rowid, }) |
| S1071 | símbolo | app/lib/data/local_db/app_database.g.dart:1414 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1072 | símbolo | app/lib/data/local_db/app_database.g.dart:1444 | @override String toString() |
| S1073 | símbolo | app/lib/data/local_db/app_database.g.dart:1460 | class $AnimeIdentityEntriesTable extends AnimeIdentityEntries with TableInfo<$AnimeIdentityEntriesTable, AnimeIdentityEntry> |
| S1074 | símbolo | app/lib/data/local_db/app_database.g.dart:1463 | attachedDatabase |
| S1075 | símbolo | app/lib/data/local_db/app_database.g.dart:1465 | $AnimeIdentityEntriesTable(this.attachedDatabase, [this._alias]) |
| S1076 | símbolo | app/lib/data/local_db/app_database.g.dart:1470 | animeId = GeneratedColumn<String>( 'anime_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1077 | símbolo | app/lib/data/local_db/app_database.g.dart:1481 | createdAtUtc = GeneratedColumn<DateTime>( 'created_at_utc', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true, ) |
| S1078 | símbolo | app/lib/data/local_db/app_database.g.dart:1488 | @override List<GeneratedColumn> get $columns |
| S1079 | símbolo | app/lib/data/local_db/app_database.g.dart:1490 | @override String get aliasedName |
| S1080 | símbolo | app/lib/data/local_db/app_database.g.dart:1492 | @override String get actualTableName |
| S1081 | símbolo | app/lib/data/local_db/app_database.g.dart:1494 | $name = 'anime_identity_entries' |
| S1082 | símbolo | app/lib/data/local_db/app_database.g.dart:1495 | @override VerificationContext validateIntegrity( Insertable<AnimeIdentityEntry> instance, { bool isInserting = false, }) |
| S1083 | símbolo | app/lib/data/local_db/app_database.g.dart:1524 | @override Set<GeneratedColumn> get $primaryKey |
| S1084 | símbolo | app/lib/data/local_db/app_database.g.dart:1526 | @override AnimeIdentityEntry map(Map<String, dynamic> data, {String? tablePrefix}) |
| S1085 | símbolo | app/lib/data/local_db/app_database.g.dart:1541 | @override $AnimeIdentityEntriesTable createAlias(String alias) |
| S1086 | símbolo | app/lib/data/local_db/app_database.g.dart:1547 | class AnimeIdentityEntry extends DataClass implements Insertable<AnimeIdentityEntry> |
| S1087 | símbolo | app/lib/data/local_db/app_database.g.dart:1549 | animeId |
| S1088 | símbolo | app/lib/data/local_db/app_database.g.dart:1550 | createdAtUtc |
| S1089 | símbolo | app/lib/data/local_db/app_database.g.dart:1551 | const AnimeIdentityEntry({required this.animeId, required this.createdAtUtc}) |
| S1090 | símbolo | app/lib/data/local_db/app_database.g.dart:1552 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1091 | símbolo | app/lib/data/local_db/app_database.g.dart:1560 | AnimeIdentityEntriesCompanion toCompanion(bool nullToAbsent) |
| S1092 | símbolo | app/lib/data/local_db/app_database.g.dart:1567 | factory AnimeIdentityEntry.fromJson( Map<String, dynamic> json, { ValueSerializer? serializer, }) |
| S1093 | símbolo | app/lib/data/local_db/app_database.g.dart:1577 | @override Map<String, dynamic> toJson({ValueSerializer? serializer}) |
| S1094 | símbolo | app/lib/data/local_db/app_database.g.dart:1586 | AnimeIdentityEntry copyWith({String? animeId, DateTime? createdAtUtc}) |
| S1095 | símbolo | app/lib/data/local_db/app_database.g.dart:1591 | AnimeIdentityEntry copyWithCompanion(AnimeIdentityEntriesCompanion data) |
| S1096 | símbolo | app/lib/data/local_db/app_database.g.dart:1600 | @override String toString() |
| S1097 | símbolo | app/lib/data/local_db/app_database.g.dart:1609 | @override int get hashCode |
| S1098 | símbolo | app/lib/data/local_db/app_database.g.dart:1611 | @override bool operator ==(Object other) |
| S1099 | símbolo | app/lib/data/local_db/app_database.g.dart:1619 | class AnimeIdentityEntriesCompanion extends UpdateCompanion<AnimeIdentityEntry> |
| S1100 | símbolo | app/lib/data/local_db/app_database.g.dart:1621 | animeId |
| S1101 | símbolo | app/lib/data/local_db/app_database.g.dart:1622 | createdAtUtc |
| S1102 | símbolo | app/lib/data/local_db/app_database.g.dart:1623 | rowid |
| S1103 | símbolo | app/lib/data/local_db/app_database.g.dart:1624 | const AnimeIdentityEntriesCompanion({ this.animeId = const Value.absent(), this.createdAtUtc = const Value.absent(), this.rowid = const Value.absent(), }) |
| S1104 | símbolo | app/lib/data/local_db/app_database.g.dart:1629 | AnimeIdentityEntriesCompanion.insert({ required String animeId, required DateTime createdAtUtc, this.rowid = const Value.absent(), }) : animeId = Value(animeId), createdAtUtc = Value(createdAtUtc) |
| S1105 | símbolo | app/lib/data/local_db/app_database.g.dart:1635 | static Insertable<AnimeIdentityEntry> custom({ Expression<String>? animeId, Expression<DateTime>? createdAtUtc, Expression<int>? rowid, }) |
| S1106 | símbolo | app/lib/data/local_db/app_database.g.dart:1647 | AnimeIdentityEntriesCompanion copyWith({ Value<String>? animeId, Value<DateTime>? createdAtUtc, Value<int>? rowid, }) |
| S1107 | símbolo | app/lib/data/local_db/app_database.g.dart:1659 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1108 | símbolo | app/lib/data/local_db/app_database.g.dart:1674 | @override String toString() |
| S1109 | símbolo | app/lib/data/local_db/app_database.g.dart:1685 | class $ExternalAnimeIdentifiersTable extends ExternalAnimeIdentifiers with TableInfo<$ExternalAnimeIdentifiersTable, ExternalAnimeIdentifier> |
| S1110 | símbolo | app/lib/data/local_db/app_database.g.dart:1688 | attachedDatabase |
| S1111 | símbolo | app/lib/data/local_db/app_database.g.dart:1690 | $ExternalAnimeIdentifiersTable(this.attachedDatabase, [this._alias]) |
| S1112 | símbolo | app/lib/data/local_db/app_database.g.dart:1695 | providerId = GeneratedColumn<String>( 'provider_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1113 | símbolo | app/lib/data/local_db/app_database.g.dart:1706 | externalId = GeneratedColumn<String>( 'external_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1114 | símbolo | app/lib/data/local_db/app_database.g.dart:1717 | animeId = GeneratedColumn<String>( 'anime_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways( 'REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE', ), ) |
| S1115 | símbolo | app/lib/data/local_db/app_database.g.dart:1731 | evidence = GeneratedColumn<String>( 'evidence', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1116 | símbolo | app/lib/data/local_db/app_database.g.dart:1742 | linkedAtUtc = GeneratedColumn<DateTime>( 'linked_at_utc', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true, ) |
| S1117 | símbolo | app/lib/data/local_db/app_database.g.dart:1749 | @override List<GeneratedColumn> get $columns |
| S1118 | símbolo | app/lib/data/local_db/app_database.g.dart:1757 | @override String get aliasedName |
| S1119 | símbolo | app/lib/data/local_db/app_database.g.dart:1759 | @override String get actualTableName |
| S1120 | símbolo | app/lib/data/local_db/app_database.g.dart:1761 | $name = 'external_anime_identifiers' |
| S1121 | símbolo | app/lib/data/local_db/app_database.g.dart:1762 | @override VerificationContext validateIntegrity( Insertable<ExternalAnimeIdentifier> instance, { bool isInserting = false, }) |
| S1122 | símbolo | app/lib/data/local_db/app_database.g.dart:1815 | @override Set<GeneratedColumn> get $primaryKey |
| S1123 | símbolo | app/lib/data/local_db/app_database.g.dart:1817 | @override ExternalAnimeIdentifier map( Map<String, dynamic> data, { String? tablePrefix, }) |
| S1124 | símbolo | app/lib/data/local_db/app_database.g.dart:1847 | @override $ExternalAnimeIdentifiersTable createAlias(String alias) |
| S1125 | símbolo | app/lib/data/local_db/app_database.g.dart:1853 | class ExternalAnimeIdentifier extends DataClass implements Insertable<ExternalAnimeIdentifier> |
| S1126 | símbolo | app/lib/data/local_db/app_database.g.dart:1855 | providerId |
| S1127 | símbolo | app/lib/data/local_db/app_database.g.dart:1856 | externalId |
| S1128 | símbolo | app/lib/data/local_db/app_database.g.dart:1857 | animeId |
| S1129 | símbolo | app/lib/data/local_db/app_database.g.dart:1858 | evidence |
| S1130 | símbolo | app/lib/data/local_db/app_database.g.dart:1859 | linkedAtUtc |
| S1131 | símbolo | app/lib/data/local_db/app_database.g.dart:1860 | const ExternalAnimeIdentifier({ required this.providerId, required this.externalId, required this.animeId, required this.evidence, required this.linkedAtUtc, }) |
| S1132 | símbolo | app/lib/data/local_db/app_database.g.dart:1867 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1133 | símbolo | app/lib/data/local_db/app_database.g.dart:1878 | ExternalAnimeIdentifiersCompanion toCompanion(bool nullToAbsent) |
| S1134 | símbolo | app/lib/data/local_db/app_database.g.dart:1888 | factory ExternalAnimeIdentifier.fromJson( Map<String, dynamic> json, { ValueSerializer? serializer, }) |
| S1135 | símbolo | app/lib/data/local_db/app_database.g.dart:1901 | @override Map<String, dynamic> toJson({ValueSerializer? serializer}) |
| S1136 | símbolo | app/lib/data/local_db/app_database.g.dart:1913 | ExternalAnimeIdentifier copyWith({ String? providerId, String? externalId, String? animeId, String? evidence, DateTime? linkedAtUtc, }) |
| S1137 | símbolo | app/lib/data/local_db/app_database.g.dart:1926 | ExternalAnimeIdentifier copyWithCompanion( ExternalAnimeIdentifiersCompanion data, ) |
| S1138 | símbolo | app/lib/data/local_db/app_database.g.dart:1944 | @override String toString() |
| S1139 | símbolo | app/lib/data/local_db/app_database.g.dart:1956 | @override int get hashCode |
| S1140 | símbolo | app/lib/data/local_db/app_database.g.dart:1959 | @override bool operator ==(Object other) |
| S1141 | símbolo | app/lib/data/local_db/app_database.g.dart:1970 | class ExternalAnimeIdentifiersCompanion extends UpdateCompanion<ExternalAnimeIdentifier> |
| S1142 | símbolo | app/lib/data/local_db/app_database.g.dart:1972 | providerId |
| S1143 | símbolo | app/lib/data/local_db/app_database.g.dart:1973 | externalId |
| S1144 | símbolo | app/lib/data/local_db/app_database.g.dart:1974 | animeId |
| S1145 | símbolo | app/lib/data/local_db/app_database.g.dart:1975 | evidence |
| S1146 | símbolo | app/lib/data/local_db/app_database.g.dart:1976 | linkedAtUtc |
| S1147 | símbolo | app/lib/data/local_db/app_database.g.dart:1977 | rowid |
| S1148 | símbolo | app/lib/data/local_db/app_database.g.dart:1978 | const ExternalAnimeIdentifiersCompanion({ this.providerId = const Value.absent(), this.externalId = const Value.absent(), this.animeId = const Value.absent(), this.evidence = const Value.absent(), this.linkedAtUtc = const Value.absent(), this.rowid = const Value.absent(), }) |
| S1149 | símbolo | app/lib/data/local_db/app_database.g.dart:1986 | ExternalAnimeIdentifiersCompanion.insert({ required String providerId, required String externalId, required String animeId, required String evidence, required DateTime linkedAtUtc, this.rowid = const Value.absent(), }) : providerId = Value(providerId), externalId = Value(externalId), animeId = Value(animeId), evidence = Value(evidence), linkedAtUtc = Value(linkedAtUtc) |
| S1150 | símbolo | app/lib/data/local_db/app_database.g.dart:1998 | static Insertable<ExternalAnimeIdentifier> custom({ Expression<String>? providerId, Expression<String>? externalId, Expression<String>? animeId, Expression<String>? evidence, Expression<DateTime>? linkedAtUtc, Expression<int>? rowid, }) |
| S1151 | símbolo | app/lib/data/local_db/app_database.g.dart:2016 | ExternalAnimeIdentifiersCompanion copyWith({ Value<String>? providerId, Value<String>? externalId, Value<String>? animeId, Value<String>? evidence, Value<DateTime>? linkedAtUtc, Value<int>? rowid, }) |
| S1152 | símbolo | app/lib/data/local_db/app_database.g.dart:2034 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1153 | símbolo | app/lib/data/local_db/app_database.g.dart:2058 | @override String toString() |
| S1154 | símbolo | app/lib/data/local_db/app_database.g.dart:2072 | class $AnimeIdentityRelationshipsTable extends AnimeIdentityRelationships with TableInfo<$AnimeIdentityRelationshipsTable, AnimeIdentityRelationship> |
| S1155 | símbolo | app/lib/data/local_db/app_database.g.dart:2076 | attachedDatabase |
| S1156 | símbolo | app/lib/data/local_db/app_database.g.dart:2078 | $AnimeIdentityRelationshipsTable(this.attachedDatabase, [this._alias]) |
| S1157 | símbolo | app/lib/data/local_db/app_database.g.dart:2083 | sourceAnimeId = GeneratedColumn<String>( 'source_anime_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways( 'REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE', ), ) |
| S1158 | símbolo | app/lib/data/local_db/app_database.g.dart:2097 | targetAnimeId = GeneratedColumn<String>( 'target_anime_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways( 'REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE', ), ) |
| S1159 | símbolo | app/lib/data/local_db/app_database.g.dart:2111 | relationshipKind = GeneratedColumn<String>( 'relationship_kind', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1160 | símbolo | app/lib/data/local_db/app_database.g.dart:2122 | evidence = GeneratedColumn<String>( 'evidence', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, ) |
| S1161 | símbolo | app/lib/data/local_db/app_database.g.dart:2133 | linkedAtUtc = GeneratedColumn<DateTime>( 'linked_at_utc', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true, ) |
| S1162 | símbolo | app/lib/data/local_db/app_database.g.dart:2140 | @override List<GeneratedColumn> get $columns |
| S1163 | símbolo | app/lib/data/local_db/app_database.g.dart:2148 | @override String get aliasedName |
| S1164 | símbolo | app/lib/data/local_db/app_database.g.dart:2150 | @override String get actualTableName |
| S1165 | símbolo | app/lib/data/local_db/app_database.g.dart:2152 | $name = 'anime_identity_relationships' |
| S1166 | símbolo | app/lib/data/local_db/app_database.g.dart:2153 | @override VerificationContext validateIntegrity( Insertable<AnimeIdentityRelationship> instance, { bool isInserting = false, }) |
| S1167 | símbolo | app/lib/data/local_db/app_database.g.dart:2215 | @override Set<GeneratedColumn> get $primaryKey |
| S1168 | símbolo | app/lib/data/local_db/app_database.g.dart:2221 | @override AnimeIdentityRelationship map( Map<String, dynamic> data, { String? tablePrefix, }) |
| S1169 | símbolo | app/lib/data/local_db/app_database.g.dart:2251 | @override $AnimeIdentityRelationshipsTable createAlias(String alias) |
| S1170 | símbolo | app/lib/data/local_db/app_database.g.dart:2257 | class AnimeIdentityRelationship extends DataClass implements Insertable<AnimeIdentityRelationship> |
| S1171 | símbolo | app/lib/data/local_db/app_database.g.dart:2259 | sourceAnimeId |
| S1172 | símbolo | app/lib/data/local_db/app_database.g.dart:2260 | targetAnimeId |
| S1173 | símbolo | app/lib/data/local_db/app_database.g.dart:2261 | relationshipKind |
| S1174 | símbolo | app/lib/data/local_db/app_database.g.dart:2262 | evidence |
| S1175 | símbolo | app/lib/data/local_db/app_database.g.dart:2263 | linkedAtUtc |
| S1176 | símbolo | app/lib/data/local_db/app_database.g.dart:2264 | const AnimeIdentityRelationship({ required this.sourceAnimeId, required this.targetAnimeId, required this.relationshipKind, required this.evidence, required this.linkedAtUtc, }) |
| S1177 | símbolo | app/lib/data/local_db/app_database.g.dart:2271 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1178 | símbolo | app/lib/data/local_db/app_database.g.dart:2282 | AnimeIdentityRelationshipsCompanion toCompanion(bool nullToAbsent) |
| S1179 | símbolo | app/lib/data/local_db/app_database.g.dart:2292 | factory AnimeIdentityRelationship.fromJson( Map<String, dynamic> json, { ValueSerializer? serializer, }) |
| S1180 | símbolo | app/lib/data/local_db/app_database.g.dart:2305 | @override Map<String, dynamic> toJson({ValueSerializer? serializer}) |
| S1181 | símbolo | app/lib/data/local_db/app_database.g.dart:2317 | AnimeIdentityRelationship copyWith({ String? sourceAnimeId, String? targetAnimeId, String? relationshipKind, String? evidence, DateTime? linkedAtUtc, }) |
| S1182 | símbolo | app/lib/data/local_db/app_database.g.dart:2330 | AnimeIdentityRelationship copyWithCompanion( AnimeIdentityRelationshipsCompanion data, ) |
| S1183 | símbolo | app/lib/data/local_db/app_database.g.dart:2350 | @override String toString() |
| S1184 | símbolo | app/lib/data/local_db/app_database.g.dart:2362 | @override int get hashCode |
| S1185 | símbolo | app/lib/data/local_db/app_database.g.dart:2370 | @override bool operator ==(Object other) |
| S1186 | símbolo | app/lib/data/local_db/app_database.g.dart:2381 | class AnimeIdentityRelationshipsCompanion extends UpdateCompanion<AnimeIdentityRelationship> |
| S1187 | símbolo | app/lib/data/local_db/app_database.g.dart:2383 | sourceAnimeId |
| S1188 | símbolo | app/lib/data/local_db/app_database.g.dart:2384 | targetAnimeId |
| S1189 | símbolo | app/lib/data/local_db/app_database.g.dart:2385 | relationshipKind |
| S1190 | símbolo | app/lib/data/local_db/app_database.g.dart:2386 | evidence |
| S1191 | símbolo | app/lib/data/local_db/app_database.g.dart:2387 | linkedAtUtc |
| S1192 | símbolo | app/lib/data/local_db/app_database.g.dart:2388 | rowid |
| S1193 | símbolo | app/lib/data/local_db/app_database.g.dart:2389 | const AnimeIdentityRelationshipsCompanion({ this.sourceAnimeId = const Value.absent(), this.targetAnimeId = const Value.absent(), this.relationshipKind = const Value.absent(), this.evidence = const Value.absent(), this.linkedAtUtc = const Value.absent(), this.rowid = const Value.absent(), }) |
| S1194 | símbolo | app/lib/data/local_db/app_database.g.dart:2397 | AnimeIdentityRelationshipsCompanion.insert({ required String sourceAnimeId, required String targetAnimeId, required String relationshipKind, required String evidence, required DateTime linkedAtUtc, this.rowid = const Value.absent(), }) : sourceAnimeId = Value(sourceAnimeId), targetAnimeId = Value(targetAnimeId), relationshipKind = Value(relationshipKind), evidence = Value(evidence), linkedAtUtc = Value(linkedAtUtc) |
| S1195 | símbolo | app/lib/data/local_db/app_database.g.dart:2409 | static Insertable<AnimeIdentityRelationship> custom({ Expression<String>? sourceAnimeId, Expression<String>? targetAnimeId, Expression<String>? relationshipKind, Expression<String>? evidence, Expression<DateTime>? linkedAtUtc, Expression<int>? rowid, }) |
| S1196 | símbolo | app/lib/data/local_db/app_database.g.dart:2427 | AnimeIdentityRelationshipsCompanion copyWith({ Value<String>? sourceAnimeId, Value<String>? targetAnimeId, Value<String>? relationshipKind, Value<String>? evidence, Value<DateTime>? linkedAtUtc, Value<int>? rowid, }) |
| S1197 | símbolo | app/lib/data/local_db/app_database.g.dart:2445 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1198 | símbolo | app/lib/data/local_db/app_database.g.dart:2469 | @override String toString() |
| S1199 | símbolo | app/lib/data/local_db/app_database.g.dart:2483 | class $LocalLibraryEntriesTable extends LocalLibraryEntries with TableInfo<$LocalLibraryEntriesTable, LocalLibraryEntry> |
| S1200 | símbolo | app/lib/data/local_db/app_database.g.dart:2486 | attachedDatabase |
| S1201 | símbolo | app/lib/data/local_db/app_database.g.dart:2488 | $LocalLibraryEntriesTable(this.attachedDatabase, [this._alias]) |
| S1202 | símbolo | app/lib/data/local_db/app_database.g.dart:2493 | animeId = GeneratedColumn<String>( 'anime_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways( 'REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE', ), ) |
| S1203 | símbolo | app/lib/data/local_db/app_database.g.dart:2507 | addedAtUtc = GeneratedColumn<DateTime>( 'added_at_utc', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true, ) |
| S1204 | símbolo | app/lib/data/local_db/app_database.g.dart:2516 | status = GeneratedColumn<String>( 'status', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: false, defaultValue: const Constant('planned'), ) |
| S1205 | símbolo | app/lib/data/local_db/app_database.g.dart:2524 | @override List<GeneratedColumn> get $columns |
| S1206 | símbolo | app/lib/data/local_db/app_database.g.dart:2526 | @override String get aliasedName |
| S1207 | símbolo | app/lib/data/local_db/app_database.g.dart:2528 | @override String get actualTableName |
| S1208 | símbolo | app/lib/data/local_db/app_database.g.dart:2530 | $name = 'library_entries' |
| S1209 | símbolo | app/lib/data/local_db/app_database.g.dart:2531 | @override VerificationContext validateIntegrity( Insertable<LocalLibraryEntry> instance, { bool isInserting = false, }) |
| S1210 | símbolo | app/lib/data/local_db/app_database.g.dart:2566 | @override Set<GeneratedColumn> get $primaryKey |
| S1211 | símbolo | app/lib/data/local_db/app_database.g.dart:2568 | @override LocalLibraryEntry map(Map<String, dynamic> data, {String? tablePrefix}) |
| S1212 | símbolo | app/lib/data/local_db/app_database.g.dart:2587 | @override $LocalLibraryEntriesTable createAlias(String alias) |
| S1213 | símbolo | app/lib/data/local_db/app_database.g.dart:2593 | class LocalLibraryEntry extends DataClass implements Insertable<LocalLibraryEntry> |
| S1214 | símbolo | app/lib/data/local_db/app_database.g.dart:2595 | animeId |
| S1215 | símbolo | app/lib/data/local_db/app_database.g.dart:2596 | addedAtUtc |
| S1216 | símbolo | app/lib/data/local_db/app_database.g.dart:2597 | status |
| S1217 | símbolo | app/lib/data/local_db/app_database.g.dart:2598 | const LocalLibraryEntry({ required this.animeId, required this.addedAtUtc, required this.status, }) |
| S1218 | símbolo | app/lib/data/local_db/app_database.g.dart:2603 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1219 | símbolo | app/lib/data/local_db/app_database.g.dart:2612 | LocalLibraryEntriesCompanion toCompanion(bool nullToAbsent) |
| S1220 | símbolo | app/lib/data/local_db/app_database.g.dart:2620 | factory LocalLibraryEntry.fromJson( Map<String, dynamic> json, { ValueSerializer? serializer, }) |
| S1221 | símbolo | app/lib/data/local_db/app_database.g.dart:2631 | @override Map<String, dynamic> toJson({ValueSerializer? serializer}) |
| S1222 | símbolo | app/lib/data/local_db/app_database.g.dart:2641 | LocalLibraryEntry copyWith({ String? animeId, DateTime? addedAtUtc, String? status, }) |
| S1223 | símbolo | app/lib/data/local_db/app_database.g.dart:2650 | LocalLibraryEntry copyWithCompanion(LocalLibraryEntriesCompanion data) |
| S1224 | símbolo | app/lib/data/local_db/app_database.g.dart:2660 | @override String toString() |
| S1225 | símbolo | app/lib/data/local_db/app_database.g.dart:2670 | @override int get hashCode |
| S1226 | símbolo | app/lib/data/local_db/app_database.g.dart:2672 | @override bool operator ==(Object other) |
| S1227 | símbolo | app/lib/data/local_db/app_database.g.dart:2681 | class LocalLibraryEntriesCompanion extends UpdateCompanion<LocalLibraryEntry> |
| S1228 | símbolo | app/lib/data/local_db/app_database.g.dart:2682 | animeId |
| S1229 | símbolo | app/lib/data/local_db/app_database.g.dart:2683 | addedAtUtc |
| S1230 | símbolo | app/lib/data/local_db/app_database.g.dart:2684 | status |
| S1231 | símbolo | app/lib/data/local_db/app_database.g.dart:2685 | rowid |
| S1232 | símbolo | app/lib/data/local_db/app_database.g.dart:2686 | const LocalLibraryEntriesCompanion({ this.animeId = const Value.absent(), this.addedAtUtc = const Value.absent(), this.status = const Value.absent(), this.rowid = const Value.absent(), }) |
| S1233 | símbolo | app/lib/data/local_db/app_database.g.dart:2692 | LocalLibraryEntriesCompanion.insert({ required String animeId, required DateTime addedAtUtc, this.status = const Value.absent(), this.rowid = const Value.absent(), }) : animeId = Value(animeId), addedAtUtc = Value(addedAtUtc) |
| S1234 | símbolo | app/lib/data/local_db/app_database.g.dart:2699 | static Insertable<LocalLibraryEntry> custom({ Expression<String>? animeId, Expression<DateTime>? addedAtUtc, Expression<String>? status, Expression<int>? rowid, }) |
| S1235 | símbolo | app/lib/data/local_db/app_database.g.dart:2713 | LocalLibraryEntriesCompanion copyWith({ Value<String>? animeId, Value<DateTime>? addedAtUtc, Value<String>? status, Value<int>? rowid, }) |
| S1236 | símbolo | app/lib/data/local_db/app_database.g.dart:2727 | @override Map<String, Expression> toColumns(bool nullToAbsent) |
| S1237 | símbolo | app/lib/data/local_db/app_database.g.dart:2745 | @override String toString() |
| S1238 | símbolo | app/lib/data/local_db/app_database.g.dart:2840 | typedef $$SettingsEntriesTableCreateCompanionBuilder = SettingsEntriesCompanion Function( |
| S1239 | símbolo | app/lib/data/local_db/app_database.g.dart:2847 | typedef $$SettingsEntriesTableUpdateCompanionBuilder = SettingsEntriesCompanion Function( |
| S1240 | símbolo | app/lib/data/local_db/app_database.g.dart:2855 | class $$SettingsEntriesTableFilterComposer extends Composer<_$AppDatabase, $SettingsEntriesTable> |
| S1241 | símbolo | app/lib/data/local_db/app_database.g.dart:2857 | $$SettingsEntriesTableFilterComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1242 | símbolo | app/lib/data/local_db/app_database.g.dart:2864 | ColumnFilters<String> get settingKey |
| S1243 | símbolo | app/lib/data/local_db/app_database.g.dart:2869 | ColumnFilters<String> get valueJson |
| S1244 | símbolo | app/lib/data/local_db/app_database.g.dart:2874 | ColumnFilters<DateTime> get updatedAt |
| S1245 | símbolo | app/lib/data/local_db/app_database.g.dart:2880 | class $$SettingsEntriesTableOrderingComposer extends Composer<_$AppDatabase, $SettingsEntriesTable> |
| S1246 | símbolo | app/lib/data/local_db/app_database.g.dart:2882 | $$SettingsEntriesTableOrderingComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1247 | símbolo | app/lib/data/local_db/app_database.g.dart:2889 | ColumnOrderings<String> get settingKey |
| S1248 | símbolo | app/lib/data/local_db/app_database.g.dart:2894 | ColumnOrderings<String> get valueJson |
| S1249 | símbolo | app/lib/data/local_db/app_database.g.dart:2899 | ColumnOrderings<DateTime> get updatedAt |
| S1250 | símbolo | app/lib/data/local_db/app_database.g.dart:2905 | class $$SettingsEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $SettingsEntriesTable> |
| S1251 | símbolo | app/lib/data/local_db/app_database.g.dart:2907 | $$SettingsEntriesTableAnnotationComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1252 | símbolo | app/lib/data/local_db/app_database.g.dart:2914 | GeneratedColumn<String> get settingKey |
| S1253 | símbolo | app/lib/data/local_db/app_database.g.dart:2919 | GeneratedColumn<String> get valueJson |
| S1254 | símbolo | app/lib/data/local_db/app_database.g.dart:2922 | GeneratedColumn<DateTime> get updatedAt |
| S1255 | símbolo | app/lib/data/local_db/app_database.g.dart:2926 | class $$SettingsEntriesTableTableManager extends RootTableManager< _$AppDatabase, $SettingsEntriesTable, SettingsEntry, $$SettingsEntriesTableFilterComposer, $$SettingsEntriesTableOrderingComposer, $$SettingsEntriesTableAnnotationComposer, $$SettingsEntriesTableCreateCompanionBuilder, $$SettingsEntriesTableUpdateCompanionBuilder, ( SettingsEntry, BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>, ), SettingsEntry, PrefetchHooks Function() > |
| S1256 | símbolo | app/lib/data/local_db/app_database.g.dart:2944 | $$SettingsEntriesTableTableManager( _$AppDatabase db, $SettingsEntriesTable table, ) : super( TableManagerState( db: db, table: table, createFilteringComposer: () => $$SettingsEntriesTableFilterComposer($db: db, $table: table), createOrderingComposer: () => $$SettingsEntriesTableOrderingComposer($db: db, $table: table), createComputedFieldComposer: () => $$SettingsEntriesTableAnnotationComposer($db: db, $table: table), updateCompanionCallback: ({ Value<String> settingKey = const Value.absent(), Value<String> valueJson = const Value.absent(), Value<DateTime> updatedAt = const Value.absent(), Value<int> rowid = const Value.absent(), }) => SettingsEntriesCompanion( settingKey: settingKey, valueJson: valueJson, updatedAt: updatedAt, rowid: rowid, ), createCompanionCallback: ({ required String settingKey, required String valueJson, required DateTime updatedAt, Value<int> rowid = const Value.absent(), }) => SettingsEntriesCompanion.insert( settingKey: settingKey, valueJson: valueJson, updatedAt: updatedAt, rowid: rowid, ), withReferenceMapper: (p0) => p0 .map( (e) => ( e.readTable<$SettingsEntriesTable, SettingsEntry>(table), BaseReferences< _$AppDatabase, $SettingsEntriesTable, SettingsEntry >(db, table, e), ), ) .toList(), prefetchHooksCallback: null, ), ) |
| S1257 | símbolo | app/lib/data/local_db/app_database.g.dart:2998 | typedef $$SettingsEntriesTableProcessedTableManager = ProcessedTableManager< _$AppDatabase, $SettingsEntriesTable, SettingsEntry, $$SettingsEntriesTableFilterComposer, $$SettingsEntriesTableOrderingComposer, $$SettingsEntriesTableAnnotationComposer, $$SettingsEntriesTableCreateCompanionBuilder, $$SettingsEntriesTableUpdateCompanionBuilder, ( SettingsEntry, BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>, ), SettingsEntry, PrefetchHooks Function() >; |
| S1258 | símbolo | app/lib/data/local_db/app_database.g.dart:3015 | typedef $$ProgressDocumentsTableCreateCompanionBuilder = ProgressDocumentsCompanion Function( |
| S1259 | símbolo | app/lib/data/local_db/app_database.g.dart:3022 | typedef $$ProgressDocumentsTableUpdateCompanionBuilder = ProgressDocumentsCompanion Function( |
| S1260 | símbolo | app/lib/data/local_db/app_database.g.dart:3030 | class $$ProgressDocumentsTableFilterComposer extends Composer<_$AppDatabase, $ProgressDocumentsTable> |
| S1261 | símbolo | app/lib/data/local_db/app_database.g.dart:3032 | $$ProgressDocumentsTableFilterComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1262 | símbolo | app/lib/data/local_db/app_database.g.dart:3039 | ColumnFilters<String> get documentKey |
| S1263 | símbolo | app/lib/data/local_db/app_database.g.dart:3044 | ColumnFilters<String> get payloadJson |
| S1264 | símbolo | app/lib/data/local_db/app_database.g.dart:3049 | ColumnFilters<DateTime> get updatedAt |
| S1265 | símbolo | app/lib/data/local_db/app_database.g.dart:3055 | class $$ProgressDocumentsTableOrderingComposer extends Composer<_$AppDatabase, $ProgressDocumentsTable> |
| S1266 | símbolo | app/lib/data/local_db/app_database.g.dart:3057 | $$ProgressDocumentsTableOrderingComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1267 | símbolo | app/lib/data/local_db/app_database.g.dart:3064 | ColumnOrderings<String> get documentKey |
| S1268 | símbolo | app/lib/data/local_db/app_database.g.dart:3069 | ColumnOrderings<String> get payloadJson |
| S1269 | símbolo | app/lib/data/local_db/app_database.g.dart:3074 | ColumnOrderings<DateTime> get updatedAt |
| S1270 | símbolo | app/lib/data/local_db/app_database.g.dart:3080 | class $$ProgressDocumentsTableAnnotationComposer extends Composer<_$AppDatabase, $ProgressDocumentsTable> |
| S1271 | símbolo | app/lib/data/local_db/app_database.g.dart:3082 | $$ProgressDocumentsTableAnnotationComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1272 | símbolo | app/lib/data/local_db/app_database.g.dart:3089 | GeneratedColumn<String> get documentKey |
| S1273 | símbolo | app/lib/data/local_db/app_database.g.dart:3094 | GeneratedColumn<String> get payloadJson |
| S1274 | símbolo | app/lib/data/local_db/app_database.g.dart:3099 | GeneratedColumn<DateTime> get updatedAt |
| S1275 | símbolo | app/lib/data/local_db/app_database.g.dart:3103 | class $$ProgressDocumentsTableTableManager extends RootTableManager< _$AppDatabase, $ProgressDocumentsTable, ProgressDocument, $$ProgressDocumentsTableFilterComposer, $$ProgressDocumentsTableOrderingComposer, $$ProgressDocumentsTableAnnotationComposer, $$ProgressDocumentsTableCreateCompanionBuilder, $$ProgressDocumentsTableUpdateCompanionBuilder, ( ProgressDocument, BaseReferences< _$AppDatabase, $ProgressDocumentsTable, ProgressDocument >, ), ProgressDocument, PrefetchHooks Function() > |
| S1276 | símbolo | app/lib/data/local_db/app_database.g.dart:3125 | $$ProgressDocumentsTableTableManager( _$AppDatabase db, $ProgressDocumentsTable table, ) : super( TableManagerState( db: db, table: table, createFilteringComposer: () => $$ProgressDocumentsTableFilterComposer($db: db, $table: table), createOrderingComposer: () => $$ProgressDocumentsTableOrderingComposer($db: db, $table: table), createComputedFieldComposer: () => $$ProgressDocumentsTableAnnotationComposer( $db: db, $table: table, ), updateCompanionCallback: ({ Value<String> documentKey = const Value.absent(), Value<String> payloadJson = const Value.absent(), Value<DateTime> updatedAt = const Value.absent(), Value<int> rowid = const Value.absent(), }) => ProgressDocumentsCompanion( documentKey: documentKey, payloadJson: payloadJson, updatedAt: updatedAt, rowid: rowid, ), createCompanionCallback: ({ required String documentKey, required String payloadJson, required DateTime updatedAt, Value<int> rowid = const Value.absent(), }) => ProgressDocumentsCompanion.insert( documentKey: documentKey, payloadJson: payloadJson, updatedAt: updatedAt, rowid: rowid, ), withReferenceMapper: (p0) => p0 .map( (e) => ( e.readTable<$ProgressDocumentsTable, ProgressDocument>(table), BaseReferences< _$AppDatabase, $ProgressDocumentsTable, ProgressDocument >(db, table, e), ), ) .toList(), prefetchHooksCallback: null, ), ) |
| S1277 | símbolo | app/lib/data/local_db/app_database.g.dart:3182 | typedef $$ProgressDocumentsTableProcessedTableManager = ProcessedTableManager< _$AppDatabase, $ProgressDocumentsTable, ProgressDocument, $$ProgressDocumentsTableFilterComposer, $$ProgressDocumentsTableOrderingComposer, $$ProgressDocumentsTableAnnotationComposer, $$ProgressDocumentsTableCreateCompanionBuilder, $$ProgressDocumentsTableUpdateCompanionBuilder, ( ProgressDocument, BaseReferences< _$AppDatabase, $ProgressDocumentsTable, ProgressDocument >, ), ProgressDocument, PrefetchHooks Function() >; |
| S1278 | símbolo | app/lib/data/local_db/app_database.g.dart:3203 | typedef $$LatestAnimeSearchTableCreateCompanionBuilder = LatestAnimeSearchCompanion Function( |
| S1279 | símbolo | app/lib/data/local_db/app_database.g.dart:3213 | typedef $$LatestAnimeSearchTableUpdateCompanionBuilder = LatestAnimeSearchCompanion Function( |
| S1280 | símbolo | app/lib/data/local_db/app_database.g.dart:3224 | class $$LatestAnimeSearchTableFilterComposer extends Composer<_$AppDatabase, $LatestAnimeSearchTable> |
| S1281 | símbolo | app/lib/data/local_db/app_database.g.dart:3226 | $$LatestAnimeSearchTableFilterComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1282 | símbolo | app/lib/data/local_db/app_database.g.dart:3233 | ColumnFilters<String> get slot |
| S1283 | símbolo | app/lib/data/local_db/app_database.g.dart:3238 | ColumnFilters<String> get searchQuery |
| S1284 | símbolo | app/lib/data/local_db/app_database.g.dart:3243 | ColumnFilters<int> get page |
| S1285 | símbolo | app/lib/data/local_db/app_database.g.dart:3248 | ColumnFilters<int> get perPage |
| S1286 | símbolo | app/lib/data/local_db/app_database.g.dart:3253 | ColumnFilters<String> get resultJson |
| S1287 | símbolo | app/lib/data/local_db/app_database.g.dart:3258 | ColumnFilters<DateTime> get cachedAt |
| S1288 | símbolo | app/lib/data/local_db/app_database.g.dart:3264 | class $$LatestAnimeSearchTableOrderingComposer extends Composer<_$AppDatabase, $LatestAnimeSearchTable> |
| S1289 | símbolo | app/lib/data/local_db/app_database.g.dart:3266 | $$LatestAnimeSearchTableOrderingComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1290 | símbolo | app/lib/data/local_db/app_database.g.dart:3273 | ColumnOrderings<String> get slot |
| S1291 | símbolo | app/lib/data/local_db/app_database.g.dart:3278 | ColumnOrderings<String> get searchQuery |
| S1292 | símbolo | app/lib/data/local_db/app_database.g.dart:3283 | ColumnOrderings<int> get page |
| S1293 | símbolo | app/lib/data/local_db/app_database.g.dart:3288 | ColumnOrderings<int> get perPage |
| S1294 | símbolo | app/lib/data/local_db/app_database.g.dart:3293 | ColumnOrderings<String> get resultJson |
| S1295 | símbolo | app/lib/data/local_db/app_database.g.dart:3298 | ColumnOrderings<DateTime> get cachedAt |
| S1296 | símbolo | app/lib/data/local_db/app_database.g.dart:3304 | class $$LatestAnimeSearchTableAnnotationComposer extends Composer<_$AppDatabase, $LatestAnimeSearchTable> |
| S1297 | símbolo | app/lib/data/local_db/app_database.g.dart:3306 | $$LatestAnimeSearchTableAnnotationComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1298 | símbolo | app/lib/data/local_db/app_database.g.dart:3313 | GeneratedColumn<String> get slot |
| S1299 | símbolo | app/lib/data/local_db/app_database.g.dart:3316 | GeneratedColumn<String> get searchQuery |
| S1300 | símbolo | app/lib/data/local_db/app_database.g.dart:3321 | GeneratedColumn<int> get page |
| S1301 | símbolo | app/lib/data/local_db/app_database.g.dart:3324 | GeneratedColumn<int> get perPage |
| S1302 | símbolo | app/lib/data/local_db/app_database.g.dart:3327 | GeneratedColumn<String> get resultJson |
| S1303 | símbolo | app/lib/data/local_db/app_database.g.dart:3332 | GeneratedColumn<DateTime> get cachedAt |
| S1304 | símbolo | app/lib/data/local_db/app_database.g.dart:3336 | class $$LatestAnimeSearchTableTableManager extends RootTableManager< _$AppDatabase, $LatestAnimeSearchTable, LatestAnimeSearchData, $$LatestAnimeSearchTableFilterComposer, $$LatestAnimeSearchTableOrderingComposer, $$LatestAnimeSearchTableAnnotationComposer, $$LatestAnimeSearchTableCreateCompanionBuilder, $$LatestAnimeSearchTableUpdateCompanionBuilder, ( LatestAnimeSearchData, BaseReferences< _$AppDatabase, $LatestAnimeSearchTable, LatestAnimeSearchData >, ), LatestAnimeSearchData, PrefetchHooks Function() > |
| S1305 | símbolo | app/lib/data/local_db/app_database.g.dart:3358 | $$LatestAnimeSearchTableTableManager( _$AppDatabase db, $LatestAnimeSearchTable table, ) : super( TableManagerState( db: db, table: table, createFilteringComposer: () => $$LatestAnimeSearchTableFilterComposer($db: db, $table: table), createOrderingComposer: () => $$LatestAnimeSearchTableOrderingComposer($db: db, $table: table), createComputedFieldComposer: () => $$LatestAnimeSearchTableAnnotationComposer( $db: db, $table: table, ), updateCompanionCallback: ({ Value<String> slot = const Value.absent(), Value<String> searchQuery = const Value.absent(), Value<int> page = const Value.absent(), Value<int> perPage = const Value.absent(), Value<String> resultJson = const Value.absent(), Value<DateTime> cachedAt = const Value.absent(), Value<int> rowid = const Value.absent(), }) => LatestAnimeSearchCompanion( slot: slot, searchQuery: searchQuery, page: page, perPage: perPage, resultJson: resultJson, cachedAt: cachedAt, rowid: rowid, ), createCompanionCallback: ({ required String slot, required String searchQuery, required int page, required int perPage, required String resultJson, required DateTime cachedAt, Value<int> rowid = const Value.absent(), }) => LatestAnimeSearchCompanion.insert( slot: slot, searchQuery: searchQuery, page: page, perPage: perPage, resultJson: resultJson, cachedAt: cachedAt, rowid: rowid, ), withReferenceMapper: (p0) => p0 .map( (e) => ( e.readTable<$LatestAnimeSearchTable, LatestAnimeSearchData>( table, ), BaseReferences< _$AppDatabase, $LatestAnimeSearchTable, LatestAnimeSearchData >(db, table, e), ), ) .toList(), prefetchHooksCallback: null, ), ) |
| S1306 | símbolo | app/lib/data/local_db/app_database.g.dart:3429 | typedef $$LatestAnimeSearchTableProcessedTableManager = ProcessedTableManager< _$AppDatabase, $LatestAnimeSearchTable, LatestAnimeSearchData, $$LatestAnimeSearchTableFilterComposer, $$LatestAnimeSearchTableOrderingComposer, $$LatestAnimeSearchTableAnnotationComposer, $$LatestAnimeSearchTableCreateCompanionBuilder, $$LatestAnimeSearchTableUpdateCompanionBuilder, ( LatestAnimeSearchData, BaseReferences< _$AppDatabase, $LatestAnimeSearchTable, LatestAnimeSearchData >, ), LatestAnimeSearchData, PrefetchHooks Function() >; |
| S1307 | símbolo | app/lib/data/local_db/app_database.g.dart:3450 | typedef $$PlaybackProgressEntriesTableCreateCompanionBuilder = PlaybackProgressEntriesCompanion Function( |
| S1308 | símbolo | app/lib/data/local_db/app_database.g.dart:3461 | typedef $$PlaybackProgressEntriesTableUpdateCompanionBuilder = PlaybackProgressEntriesCompanion Function( |
| S1309 | símbolo | app/lib/data/local_db/app_database.g.dart:3473 | class $$PlaybackProgressEntriesTableFilterComposer extends Composer<_$AppDatabase, $PlaybackProgressEntriesTable> |
| S1310 | símbolo | app/lib/data/local_db/app_database.g.dart:3475 | $$PlaybackProgressEntriesTableFilterComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1311 | símbolo | app/lib/data/local_db/app_database.g.dart:3482 | ColumnFilters<String> get contentId |
| S1312 | símbolo | app/lib/data/local_db/app_database.g.dart:3487 | ColumnFilters<String> get episodeId |
| S1313 | símbolo | app/lib/data/local_db/app_database.g.dart:3492 | ColumnFilters<int> get positionMs |
| S1314 | símbolo | app/lib/data/local_db/app_database.g.dart:3497 | ColumnFilters<int> get durationMs |
| S1315 | símbolo | app/lib/data/local_db/app_database.g.dart:3502 | ColumnFilters<DateTime> get updatedAtUtc |
| S1316 | símbolo | app/lib/data/local_db/app_database.g.dart:3507 | ColumnFilters<String> get completion |
| S1317 | símbolo | app/lib/data/local_db/app_database.g.dart:3512 | ColumnFilters<int> get revision |
| S1318 | símbolo | app/lib/data/local_db/app_database.g.dart:3518 | class $$PlaybackProgressEntriesTableOrderingComposer extends Composer<_$AppDatabase, $PlaybackProgressEntriesTable> |
| S1319 | símbolo | app/lib/data/local_db/app_database.g.dart:3520 | $$PlaybackProgressEntriesTableOrderingComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1320 | símbolo | app/lib/data/local_db/app_database.g.dart:3527 | ColumnOrderings<String> get contentId |
| S1321 | símbolo | app/lib/data/local_db/app_database.g.dart:3532 | ColumnOrderings<String> get episodeId |
| S1322 | símbolo | app/lib/data/local_db/app_database.g.dart:3537 | ColumnOrderings<int> get positionMs |
| S1323 | símbolo | app/lib/data/local_db/app_database.g.dart:3542 | ColumnOrderings<int> get durationMs |
| S1324 | símbolo | app/lib/data/local_db/app_database.g.dart:3547 | ColumnOrderings<DateTime> get updatedAtUtc |
| S1325 | símbolo | app/lib/data/local_db/app_database.g.dart:3552 | ColumnOrderings<String> get completion |
| S1326 | símbolo | app/lib/data/local_db/app_database.g.dart:3557 | ColumnOrderings<int> get revision |
| S1327 | símbolo | app/lib/data/local_db/app_database.g.dart:3563 | class $$PlaybackProgressEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $PlaybackProgressEntriesTable> |
| S1328 | símbolo | app/lib/data/local_db/app_database.g.dart:3565 | $$PlaybackProgressEntriesTableAnnotationComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1329 | símbolo | app/lib/data/local_db/app_database.g.dart:3572 | GeneratedColumn<String> get contentId |
| S1330 | símbolo | app/lib/data/local_db/app_database.g.dart:3575 | GeneratedColumn<String> get episodeId |
| S1331 | símbolo | app/lib/data/local_db/app_database.g.dart:3578 | GeneratedColumn<int> get positionMs |
| S1332 | símbolo | app/lib/data/local_db/app_database.g.dart:3583 | GeneratedColumn<int> get durationMs |
| S1333 | símbolo | app/lib/data/local_db/app_database.g.dart:3588 | GeneratedColumn<DateTime> get updatedAtUtc |
| S1334 | símbolo | app/lib/data/local_db/app_database.g.dart:3593 | GeneratedColumn<String> get completion |
| S1335 | símbolo | app/lib/data/local_db/app_database.g.dart:3598 | GeneratedColumn<int> get revision |
| S1336 | símbolo | app/lib/data/local_db/app_database.g.dart:3602 | class $$PlaybackProgressEntriesTableTableManager extends RootTableManager< _$AppDatabase, $PlaybackProgressEntriesTable, PlaybackProgressEntry, $$PlaybackProgressEntriesTableFilterComposer, $$PlaybackProgressEntriesTableOrderingComposer, $$PlaybackProgressEntriesTableAnnotationComposer, $$PlaybackProgressEntriesTableCreateCompanionBuilder, $$PlaybackProgressEntriesTableUpdateCompanionBuilder, ( PlaybackProgressEntry, BaseReferences< _$AppDatabase, $PlaybackProgressEntriesTable, PlaybackProgressEntry >, ), PlaybackProgressEntry, PrefetchHooks Function() > |
| S1337 | símbolo | app/lib/data/local_db/app_database.g.dart:3624 | $$PlaybackProgressEntriesTableTableManager( _$AppDatabase db, $PlaybackProgressEntriesTable table, ) : super( TableManagerState( db: db, table: table, createFilteringComposer: () => $$PlaybackProgressEntriesTableFilterComposer( $db: db, $table: table, ), createOrderingComposer: () => $$PlaybackProgressEntriesTableOrderingComposer( $db: db, $table: table, ), createComputedFieldComposer: () => $$PlaybackProgressEntriesTableAnnotationComposer( $db: db, $table: table, ), updateCompanionCallback: ({ Value<String> contentId = const Value.absent(), Value<String> episodeId = const Value.absent(), Value<int> positionMs = const Value.absent(), Value<int?> durationMs = const Value.absent(), Value<DateTime> updatedAtUtc = const Value.absent(), Value<String> completion = const Value.absent(), Value<int> revision = const Value.absent(), Value<int> rowid = const Value.absent(), }) => PlaybackProgressEntriesCompanion( contentId: contentId, episodeId: episodeId, positionMs: positionMs, durationMs: durationMs, updatedAtUtc: updatedAtUtc, completion: completion, revision: revision, rowid: rowid, ), createCompanionCallback: ({ required String contentId, required String episodeId, required int positionMs, Value<int?> durationMs = const Value.absent(), required DateTime updatedAtUtc, required String completion, Value<int> revision = const Value.absent(), Value<int> rowid = const Value.absent(), }) => PlaybackProgressEntriesCompanion.insert( contentId: contentId, episodeId: episodeId, positionMs: positionMs, durationMs: durationMs, updatedAtUtc: updatedAtUtc, completion: completion, revision: revision, rowid: rowid, ), withReferenceMapper: (p0) => p0 .map( (e) => ( e.readTable< $PlaybackProgressEntriesTable, PlaybackProgressEntry >(table), BaseReferences< _$AppDatabase, $PlaybackProgressEntriesTable, PlaybackProgressEntry >(db, table, e), ), ) .toList(), prefetchHooksCallback: null, ), ) |
| S1338 | símbolo | app/lib/data/local_db/app_database.g.dart:3706 | typedef $$PlaybackProgressEntriesTableProcessedTableManager = ProcessedTableManager< _$AppDatabase, $PlaybackProgressEntriesTable, PlaybackProgressEntry, $$PlaybackProgressEntriesTableFilterComposer, $$PlaybackProgressEntriesTableOrderingComposer, $$PlaybackProgressEntriesTableAnnotationComposer, $$PlaybackProgressEntriesTableCreateCompanionBuilder, $$PlaybackProgressEntriesTableUpdateCompanionBuilder, ( PlaybackProgressEntry, BaseReferences< _$AppDatabase, $PlaybackProgressEntriesTable, PlaybackProgressEntry >, ), PlaybackProgressEntry, PrefetchHooks Function() >; |
| S1339 | símbolo | app/lib/data/local_db/app_database.g.dart:3727 | typedef $$AnimeIdentityEntriesTableCreateCompanionBuilder = AnimeIdentityEntriesCompanion Function( |
| S1340 | símbolo | app/lib/data/local_db/app_database.g.dart:3733 | typedef $$AnimeIdentityEntriesTableUpdateCompanionBuilder = AnimeIdentityEntriesCompanion Function( |
| S1341 | símbolo | app/lib/data/local_db/app_database.g.dart:3740 | final class $$AnimeIdentityEntriesTableReferences extends BaseReferences< _$AppDatabase, $AnimeIdentityEntriesTable, AnimeIdentityEntry > |
| S1342 | símbolo | app/lib/data/local_db/app_database.g.dart:3747 | $$AnimeIdentityEntriesTableReferences( super.$_db, super.$_table, super.$_typedResult, ) |
| S1343 | símbolo | app/lib/data/local_db/app_database.g.dart:3763 | $$ExternalAnimeIdentifiersTableProcessedTableManager get externalAnimeIdentifiersRefs |
| S1344 | símbolo | app/lib/data/local_db/app_database.g.dart:3791 | $$AnimeIdentityRelationshipsTableProcessedTableManager get outgoingRelationships |
| S1345 | símbolo | app/lib/data/local_db/app_database.g.dart:3821 | $$AnimeIdentityRelationshipsTableProcessedTableManager get incomingRelationships |
| S1346 | símbolo | app/lib/data/local_db/app_database.g.dart:3849 | $$LocalLibraryEntriesTableProcessedTableManager get localLibraryEntriesRefs |
| S1347 | símbolo | app/lib/data/local_db/app_database.g.dart:3867 | class $$AnimeIdentityEntriesTableFilterComposer extends Composer<_$AppDatabase, $AnimeIdentityEntriesTable> |
| S1348 | símbolo | app/lib/data/local_db/app_database.g.dart:3869 | $$AnimeIdentityEntriesTableFilterComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1349 | símbolo | app/lib/data/local_db/app_database.g.dart:3876 | ColumnFilters<String> get animeId |
| S1350 | símbolo | app/lib/data/local_db/app_database.g.dart:3881 | ColumnFilters<DateTime> get createdAtUtc |
| S1351 | símbolo | app/lib/data/local_db/app_database.g.dart:3886 | Expression<bool> externalAnimeIdentifiersRefs( Expression<bool> Function($$ExternalAnimeIdentifiersTableFilterComposer f) f, ) |
| S1352 | símbolo | app/lib/data/local_db/app_database.g.dart:3913 | Expression<bool> outgoingRelationships( Expression<bool> Function($$AnimeIdentityRelationshipsTableFilterComposer f) f, ) |
| S1353 | símbolo | app/lib/data/local_db/app_database.g.dart:3940 | Expression<bool> incomingRelationships( Expression<bool> Function($$AnimeIdentityRelationshipsTableFilterComposer f) f, ) |
| S1354 | símbolo | app/lib/data/local_db/app_database.g.dart:3967 | Expression<bool> localLibraryEntriesRefs( Expression<bool> Function($$LocalLibraryEntriesTableFilterComposer f) f, ) |
| S1355 | símbolo | app/lib/data/local_db/app_database.g.dart:3993 | class $$AnimeIdentityEntriesTableOrderingComposer extends Composer<_$AppDatabase, $AnimeIdentityEntriesTable> |
| S1356 | símbolo | app/lib/data/local_db/app_database.g.dart:3995 | $$AnimeIdentityEntriesTableOrderingComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1357 | símbolo | app/lib/data/local_db/app_database.g.dart:4002 | ColumnOrderings<String> get animeId |
| S1358 | símbolo | app/lib/data/local_db/app_database.g.dart:4007 | ColumnOrderings<DateTime> get createdAtUtc |
| S1359 | símbolo | app/lib/data/local_db/app_database.g.dart:4013 | class $$AnimeIdentityEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $AnimeIdentityEntriesTable> |
| S1360 | símbolo | app/lib/data/local_db/app_database.g.dart:4015 | $$AnimeIdentityEntriesTableAnnotationComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1361 | símbolo | app/lib/data/local_db/app_database.g.dart:4022 | GeneratedColumn<String> get animeId |
| S1362 | símbolo | app/lib/data/local_db/app_database.g.dart:4025 | GeneratedColumn<DateTime> get createdAtUtc |
| S1363 | símbolo | app/lib/data/local_db/app_database.g.dart:4030 | Expression<T> externalAnimeIdentifiersRefs<T extends Object>( Expression<T> Function($$ExternalAnimeIdentifiersTableAnnotationComposer a) f, ) |
| S1364 | símbolo | app/lib/data/local_db/app_database.g.dart:4057 | Expression<T> outgoingRelationships<T extends Object>( Expression<T> Function( $$AnimeIdentityRelationshipsTableAnnotationComposer a, ) f, ) |
| S1365 | símbolo | app/lib/data/local_db/app_database.g.dart:4086 | Expression<T> incomingRelationships<T extends Object>( Expression<T> Function( $$AnimeIdentityRelationshipsTableAnnotationComposer a, ) f, ) |
| S1366 | símbolo | app/lib/data/local_db/app_database.g.dart:4115 | Expression<T> localLibraryEntriesRefs<T extends Object>( Expression<T> Function($$LocalLibraryEntriesTableAnnotationComposer a) f, ) |
| S1367 | símbolo | app/lib/data/local_db/app_database.g.dart:4142 | class $$AnimeIdentityEntriesTableTableManager extends RootTableManager< _$AppDatabase, $AnimeIdentityEntriesTable, AnimeIdentityEntry, $$AnimeIdentityEntriesTableFilterComposer, $$AnimeIdentityEntriesTableOrderingComposer, $$AnimeIdentityEntriesTableAnnotationComposer, $$AnimeIdentityEntriesTableCreateCompanionBuilder, $$AnimeIdentityEntriesTableUpdateCompanionBuilder, (AnimeIdentityEntry, $$AnimeIdentityEntriesTableReferences), AnimeIdentityEntry, PrefetchHooks Function( |
| S1368 | símbolo | app/lib/data/local_db/app_database.g.dart:4162 | $$AnimeIdentityEntriesTableTableManager( _$AppDatabase db, $AnimeIdentityEntriesTable table, ) : super( TableManagerState( db: db, table: table, createFilteringComposer: () => $$AnimeIdentityEntriesTableFilterComposer($db: db, $table: table), createOrderingComposer: () => $$AnimeIdentityEntriesTableOrderingComposer( $db: db, $table: table, ), createComputedFieldComposer: () => $$AnimeIdentityEntriesTableAnnotationComposer( $db: db, $table: table, ), updateCompanionCallback: ({ Value<String> animeId = const Value.absent(), Value<DateTime> createdAtUtc = const Value.absent(), Value<int> rowid = const Value.absent(), }) => AnimeIdentityEntriesCompanion( animeId: animeId, createdAtUtc: createdAtUtc, rowid: rowid, ), createCompanionCallback: ({ required String animeId, required DateTime createdAtUtc, Value<int> rowid = const Value.absent(), }) => AnimeIdentityEntriesCompanion.insert( animeId: animeId, createdAtUtc: createdAtUtc, rowid: rowid, ), withReferenceMapper: (p0) => p0 .map( (e) => ( e.readTable<$AnimeIdentityEntriesTable, AnimeIdentityEntry>( table, ), $$AnimeIdentityEntriesTableReferences(db, table, e), ), ) .toList(), prefetchHooksCallback: ({ externalAnimeIdentifiersRefs = false, outgoingRelationships = false, incomingRelationships = false, localLibraryEntriesRefs = false, }) { return PrefetchHooks( db: db, explicitlyWatchedTables: [ if (externalAnimeIdentifiersRefs) db.externalAnimeIdentifiers, if (outgoingRelationships) db.animeIdentityRelationships, if (incomingRelationships) db.animeIdentityRelationships, if (localLibraryEntriesRefs) db.localLibraryEntries, ], addJoins: null, getPrefetchedDataCallback: (items) async { return [ if (externalAnimeIdentifiersRefs) await $_getPrefetchedDataByColumns< AnimeIdentityEntry, $AnimeIdentityEntriesTable, ExternalAnimeIdentifier, $ExternalAnimeIdentifiersTable >( currentTable: table, referencedTable: $$AnimeIdentityEntriesTableReferences ._externalAnimeIdentifiersRefsTable(db), managerFromTypedResult: (p0) => $$AnimeIdentityEntriesTableReferences( db, table, p0, ).externalAnimeIdentifiersRefs, currentColumn: 'anime_id', referencedColumn: 'anime_id', typedResults: items, ), if (outgoingRelationships) await $_getPrefetchedDataByColumns< AnimeIdentityEntry, $AnimeIdentityEntriesTable, AnimeIdentityRelationship, $AnimeIdentityRelationshipsTable >( currentTable: table, referencedTable: $$AnimeIdentityEntriesTableReferences ._outgoingRelationshipsTable(db), managerFromTypedResult: (p0) => $$AnimeIdentityEntriesTableReferences( db, table, p0, ).outgoingRelationships, currentColumn: 'anime_id', referencedColumn: 'source_anime_id', typedResults: items, ), if (incomingRelationships) await $_getPrefetchedDataByColumns< AnimeIdentityEntry, $AnimeIdentityEntriesTable, AnimeIdentityRelationship, $AnimeIdentityRelationshipsTable >( currentTable: table, referencedTable: $$AnimeIdentityEntriesTableReferences ._incomingRelationshipsTable(db), managerFromTypedResult: (p0) => $$AnimeIdentityEntriesTableReferences( db, table, p0, ).incomingRelationships, currentColumn: 'anime_id', referencedColumn: 'target_anime_id', typedResults: items, ), if (localLibraryEntriesRefs) await $_getPrefetchedDataByColumns< AnimeIdentityEntry, $AnimeIdentityEntriesTable, LocalLibraryEntry, $LocalLibraryEntriesTable >( currentTable: table, referencedTable: $$AnimeIdentityEntriesTableReferences ._localLibraryEntriesRefsTable(db), managerFromTypedResult: (p0) => $$AnimeIdentityEntriesTableReferences( db, table, p0, ).localLibraryEntriesRefs, currentColumn: 'anime_id', referencedColumn: 'anime_id', typedResults: items, ), ]; }, ); }, ), ) |
| S1369 | símbolo | app/lib/data/local_db/app_database.g.dart:4318 | typedef $$AnimeIdentityEntriesTableProcessedTableManager = ProcessedTableManager< _$AppDatabase, $AnimeIdentityEntriesTable, AnimeIdentityEntry, $$AnimeIdentityEntriesTableFilterComposer, $$AnimeIdentityEntriesTableOrderingComposer, $$AnimeIdentityEntriesTableAnnotationComposer, $$AnimeIdentityEntriesTableCreateCompanionBuilder, $$AnimeIdentityEntriesTableUpdateCompanionBuilder, (AnimeIdentityEntry, $$AnimeIdentityEntriesTableReferences), AnimeIdentityEntry, PrefetchHooks Function( |
| S1370 | símbolo | app/lib/data/local_db/app_database.g.dart:4337 | typedef $$ExternalAnimeIdentifiersTableCreateCompanionBuilder = ExternalAnimeIdentifiersCompanion Function( |
| S1371 | símbolo | app/lib/data/local_db/app_database.g.dart:4346 | typedef $$ExternalAnimeIdentifiersTableUpdateCompanionBuilder = ExternalAnimeIdentifiersCompanion Function( |
| S1372 | símbolo | app/lib/data/local_db/app_database.g.dart:4356 | final class $$ExternalAnimeIdentifiersTableReferences extends BaseReferences< _$AppDatabase, $ExternalAnimeIdentifiersTable, ExternalAnimeIdentifier > |
| S1373 | símbolo | app/lib/data/local_db/app_database.g.dart:4363 | $$ExternalAnimeIdentifiersTableReferences( super.$_db, super.$_table, super.$_typedResult, ) |
| S1374 | símbolo | app/lib/data/local_db/app_database.g.dart:4375 | $$AnimeIdentityEntriesTableProcessedTableManager get animeId |
| S1375 | símbolo | app/lib/data/local_db/app_database.g.dart:4390 | class $$ExternalAnimeIdentifiersTableFilterComposer extends Composer<_$AppDatabase, $ExternalAnimeIdentifiersTable> |
| S1376 | símbolo | app/lib/data/local_db/app_database.g.dart:4392 | $$ExternalAnimeIdentifiersTableFilterComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1377 | símbolo | app/lib/data/local_db/app_database.g.dart:4399 | ColumnFilters<String> get providerId |
| S1378 | símbolo | app/lib/data/local_db/app_database.g.dart:4404 | ColumnFilters<String> get externalId |
| S1379 | símbolo | app/lib/data/local_db/app_database.g.dart:4409 | ColumnFilters<String> get evidence |
| S1380 | símbolo | app/lib/data/local_db/app_database.g.dart:4414 | ColumnFilters<DateTime> get linkedAtUtc |
| S1381 | símbolo | app/lib/data/local_db/app_database.g.dart:4419 | $$AnimeIdentityEntriesTableFilterComposer get animeId |
| S1382 | símbolo | app/lib/data/local_db/app_database.g.dart:4443 | class $$ExternalAnimeIdentifiersTableOrderingComposer extends Composer<_$AppDatabase, $ExternalAnimeIdentifiersTable> |
| S1383 | símbolo | app/lib/data/local_db/app_database.g.dart:4445 | $$ExternalAnimeIdentifiersTableOrderingComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1384 | símbolo | app/lib/data/local_db/app_database.g.dart:4452 | ColumnOrderings<String> get providerId |
| S1385 | símbolo | app/lib/data/local_db/app_database.g.dart:4457 | ColumnOrderings<String> get externalId |
| S1386 | símbolo | app/lib/data/local_db/app_database.g.dart:4462 | ColumnOrderings<String> get evidence |
| S1387 | símbolo | app/lib/data/local_db/app_database.g.dart:4467 | ColumnOrderings<DateTime> get linkedAtUtc |
| S1388 | símbolo | app/lib/data/local_db/app_database.g.dart:4472 | $$AnimeIdentityEntriesTableOrderingComposer get animeId |
| S1389 | símbolo | app/lib/data/local_db/app_database.g.dart:4497 | class $$ExternalAnimeIdentifiersTableAnnotationComposer extends Composer<_$AppDatabase, $ExternalAnimeIdentifiersTable> |
| S1390 | símbolo | app/lib/data/local_db/app_database.g.dart:4499 | $$ExternalAnimeIdentifiersTableAnnotationComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1391 | símbolo | app/lib/data/local_db/app_database.g.dart:4506 | GeneratedColumn<String> get providerId |
| S1392 | símbolo | app/lib/data/local_db/app_database.g.dart:4511 | GeneratedColumn<String> get externalId |
| S1393 | símbolo | app/lib/data/local_db/app_database.g.dart:4516 | GeneratedColumn<String> get evidence |
| S1394 | símbolo | app/lib/data/local_db/app_database.g.dart:4519 | GeneratedColumn<DateTime> get linkedAtUtc |
| S1395 | símbolo | app/lib/data/local_db/app_database.g.dart:4524 | $$AnimeIdentityEntriesTableAnnotationComposer get animeId |
| S1396 | símbolo | app/lib/data/local_db/app_database.g.dart:4549 | class $$ExternalAnimeIdentifiersTableTableManager extends RootTableManager< _$AppDatabase, $ExternalAnimeIdentifiersTable, ExternalAnimeIdentifier, $$ExternalAnimeIdentifiersTableFilterComposer, $$ExternalAnimeIdentifiersTableOrderingComposer, $$ExternalAnimeIdentifiersTableAnnotationComposer, $$ExternalAnimeIdentifiersTableCreateCompanionBuilder, $$ExternalAnimeIdentifiersTableUpdateCompanionBuilder, (ExternalAnimeIdentifier, $$ExternalAnimeIdentifiersTableReferences), ExternalAnimeIdentifier, PrefetchHooks Function( |
| S1397 | símbolo | app/lib/data/local_db/app_database.g.dart:4564 | $$ExternalAnimeIdentifiersTableTableManager( _$AppDatabase db, $ExternalAnimeIdentifiersTable table, ) : super( TableManagerState( db: db, table: table, createFilteringComposer: () => $$ExternalAnimeIdentifiersTableFilterComposer( $db: db, $table: table, ), createOrderingComposer: () => $$ExternalAnimeIdentifiersTableOrderingComposer( $db: db, $table: table, ), createComputedFieldComposer: () => $$ExternalAnimeIdentifiersTableAnnotationComposer( $db: db, $table: table, ), updateCompanionCallback: ({ Value<String> providerId = const Value.absent(), Value<String> externalId = const Value.absent(), Value<String> animeId = const Value.absent(), Value<String> evidence = const Value.absent(), Value<DateTime> linkedAtUtc = const Value.absent(), Value<int> rowid = const Value.absent(), }) => ExternalAnimeIdentifiersCompanion( providerId: providerId, externalId: externalId, animeId: animeId, evidence: evidence, linkedAtUtc: linkedAtUtc, rowid: rowid, ), createCompanionCallback: ({ required String providerId, required String externalId, required String animeId, required String evidence, required DateTime linkedAtUtc, Value<int> rowid = const Value.absent(), }) => ExternalAnimeIdentifiersCompanion.insert( providerId: providerId, externalId: externalId, animeId: animeId, evidence: evidence, linkedAtUtc: linkedAtUtc, rowid: rowid, ), withReferenceMapper: (p0) => p0 .map( (e) => ( e.readTable< $ExternalAnimeIdentifiersTable, ExternalAnimeIdentifier >(table), $$ExternalAnimeIdentifiersTableReferences(db, table, e), ), ) .toList(), prefetchHooksCallback: ({animeId = false}) { return PrefetchHooks( db: db, explicitlyWatchedTables: [], addJoins: < T extends TableManagerState< dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic > >(state) { if (animeId) { state = state.withJoin( currentTable: table, currentColumn: table.animeId, referencedTable: $$ExternalAnimeIdentifiersTableReferences ._animeIdTable(db), referencedColumn: $$ExternalAnimeIdentifiersTableReferences ._animeIdTable(db) .animeId, ) as T; } return state; }, getPrefetchedDataCallback: (items) async { return []; }, ); }, ), ) |
| S1398 | símbolo | app/lib/data/local_db/app_database.g.dart:4674 | typedef $$ExternalAnimeIdentifiersTableProcessedTableManager = ProcessedTableManager< _$AppDatabase, $ExternalAnimeIdentifiersTable, ExternalAnimeIdentifier, $$ExternalAnimeIdentifiersTableFilterComposer, $$ExternalAnimeIdentifiersTableOrderingComposer, $$ExternalAnimeIdentifiersTableAnnotationComposer, $$ExternalAnimeIdentifiersTableCreateCompanionBuilder, $$ExternalAnimeIdentifiersTableUpdateCompanionBuilder, (ExternalAnimeIdentifier, $$ExternalAnimeIdentifiersTableReferences), ExternalAnimeIdentifier, PrefetchHooks Function( |
| S1399 | símbolo | app/lib/data/local_db/app_database.g.dart:4688 | typedef $$AnimeIdentityRelationshipsTableCreateCompanionBuilder = AnimeIdentityRelationshipsCompanion Function( |
| S1400 | símbolo | app/lib/data/local_db/app_database.g.dart:4697 | typedef $$AnimeIdentityRelationshipsTableUpdateCompanionBuilder = AnimeIdentityRelationshipsCompanion Function( |
| S1401 | símbolo | app/lib/data/local_db/app_database.g.dart:4707 | final class $$AnimeIdentityRelationshipsTableReferences extends BaseReferences< _$AppDatabase, $AnimeIdentityRelationshipsTable, AnimeIdentityRelationship > |
| S1402 | símbolo | app/lib/data/local_db/app_database.g.dart:4714 | $$AnimeIdentityRelationshipsTableReferences( super.$_db, super.$_table, super.$_typedResult, ) |
| S1403 | símbolo | app/lib/data/local_db/app_database.g.dart:4725 | $$AnimeIdentityEntriesTableProcessedTableManager get sourceAnimeId |
| S1404 | símbolo | app/lib/data/local_db/app_database.g.dart:4744 | $$AnimeIdentityEntriesTableProcessedTableManager get targetAnimeId |
| S1405 | símbolo | app/lib/data/local_db/app_database.g.dart:4759 | class $$AnimeIdentityRelationshipsTableFilterComposer extends Composer<_$AppDatabase, $AnimeIdentityRelationshipsTable> |
| S1406 | símbolo | app/lib/data/local_db/app_database.g.dart:4761 | $$AnimeIdentityRelationshipsTableFilterComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1407 | símbolo | app/lib/data/local_db/app_database.g.dart:4768 | ColumnFilters<String> get relationshipKind |
| S1408 | símbolo | app/lib/data/local_db/app_database.g.dart:4773 | ColumnFilters<String> get evidence |
| S1409 | símbolo | app/lib/data/local_db/app_database.g.dart:4778 | ColumnFilters<DateTime> get linkedAtUtc |
| S1410 | símbolo | app/lib/data/local_db/app_database.g.dart:4783 | $$AnimeIdentityEntriesTableFilterComposer get sourceAnimeId |
| S1411 | símbolo | app/lib/data/local_db/app_database.g.dart:4806 | $$AnimeIdentityEntriesTableFilterComposer get targetAnimeId |
| S1412 | símbolo | app/lib/data/local_db/app_database.g.dart:4830 | class $$AnimeIdentityRelationshipsTableOrderingComposer extends Composer<_$AppDatabase, $AnimeIdentityRelationshipsTable> |
| S1413 | símbolo | app/lib/data/local_db/app_database.g.dart:4832 | $$AnimeIdentityRelationshipsTableOrderingComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1414 | símbolo | app/lib/data/local_db/app_database.g.dart:4839 | ColumnOrderings<String> get relationshipKind |
| S1415 | símbolo | app/lib/data/local_db/app_database.g.dart:4844 | ColumnOrderings<String> get evidence |
| S1416 | símbolo | app/lib/data/local_db/app_database.g.dart:4849 | ColumnOrderings<DateTime> get linkedAtUtc |
| S1417 | símbolo | app/lib/data/local_db/app_database.g.dart:4854 | $$AnimeIdentityEntriesTableOrderingComposer get sourceAnimeId |
| S1418 | símbolo | app/lib/data/local_db/app_database.g.dart:4878 | $$AnimeIdentityEntriesTableOrderingComposer get targetAnimeId |
| S1419 | símbolo | app/lib/data/local_db/app_database.g.dart:4903 | class $$AnimeIdentityRelationshipsTableAnnotationComposer extends Composer<_$AppDatabase, $AnimeIdentityRelationshipsTable> |
| S1420 | símbolo | app/lib/data/local_db/app_database.g.dart:4905 | $$AnimeIdentityRelationshipsTableAnnotationComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1421 | símbolo | app/lib/data/local_db/app_database.g.dart:4912 | GeneratedColumn<String> get relationshipKind |
| S1422 | símbolo | app/lib/data/local_db/app_database.g.dart:4917 | GeneratedColumn<String> get evidence |
| S1423 | símbolo | app/lib/data/local_db/app_database.g.dart:4920 | GeneratedColumn<DateTime> get linkedAtUtc |
| S1424 | símbolo | app/lib/data/local_db/app_database.g.dart:4925 | $$AnimeIdentityEntriesTableAnnotationComposer get sourceAnimeId |
| S1425 | símbolo | app/lib/data/local_db/app_database.g.dart:4949 | $$AnimeIdentityEntriesTableAnnotationComposer get targetAnimeId |
| S1426 | símbolo | app/lib/data/local_db/app_database.g.dart:4974 | class $$AnimeIdentityRelationshipsTableTableManager extends RootTableManager< _$AppDatabase, $AnimeIdentityRelationshipsTable, AnimeIdentityRelationship, $$AnimeIdentityRelationshipsTableFilterComposer, $$AnimeIdentityRelationshipsTableOrderingComposer, $$AnimeIdentityRelationshipsTableAnnotationComposer, $$AnimeIdentityRelationshipsTableCreateCompanionBuilder, $$AnimeIdentityRelationshipsTableUpdateCompanionBuilder, ( AnimeIdentityRelationship, $$AnimeIdentityRelationshipsTableReferences, ), AnimeIdentityRelationship, PrefetchHooks Function( |
| S1427 | símbolo | app/lib/data/local_db/app_database.g.dart:4992 | $$AnimeIdentityRelationshipsTableTableManager( _$AppDatabase db, $AnimeIdentityRelationshipsTable table, ) : super( TableManagerState( db: db, table: table, createFilteringComposer: () => $$AnimeIdentityRelationshipsTableFilterComposer( $db: db, $table: table, ), createOrderingComposer: () => $$AnimeIdentityRelationshipsTableOrderingComposer( $db: db, $table: table, ), createComputedFieldComposer: () => $$AnimeIdentityRelationshipsTableAnnotationComposer( $db: db, $table: table, ), updateCompanionCallback: ({ Value<String> sourceAnimeId = const Value.absent(), Value<String> targetAnimeId = const Value.absent(), Value<String> relationshipKind = const Value.absent(), Value<String> evidence = const Value.absent(), Value<DateTime> linkedAtUtc = const Value.absent(), Value<int> rowid = const Value.absent(), }) => AnimeIdentityRelationshipsCompanion( sourceAnimeId: sourceAnimeId, targetAnimeId: targetAnimeId, relationshipKind: relationshipKind, evidence: evidence, linkedAtUtc: linkedAtUtc, rowid: rowid, ), createCompanionCallback: ({ required String sourceAnimeId, required String targetAnimeId, required String relationshipKind, required String evidence, required DateTime linkedAtUtc, Value<int> rowid = const Value.absent(), }) => AnimeIdentityRelationshipsCompanion.insert( sourceAnimeId: sourceAnimeId, targetAnimeId: targetAnimeId, relationshipKind: relationshipKind, evidence: evidence, linkedAtUtc: linkedAtUtc, rowid: rowid, ), withReferenceMapper: (p0) => p0 .map( (e) => ( e.readTable< $AnimeIdentityRelationshipsTable, AnimeIdentityRelationship >(table), $$AnimeIdentityRelationshipsTableReferences(db, table, e), ), ) .toList(), prefetchHooksCallback: ({sourceAnimeId = false, targetAnimeId = false}) { return PrefetchHooks( db: db, explicitlyWatchedTables: [], addJoins: < T extends TableManagerState< dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic > >(state) { if (sourceAnimeId) { state = state.withJoin( currentTable: table, currentColumn: table.sourceAnimeId, referencedTable: $$AnimeIdentityRelationshipsTableReferences ._sourceAnimeIdTable(db), referencedColumn: $$AnimeIdentityRelationshipsTableReferences ._sourceAnimeIdTable(db) .animeId, ) as T; } if (targetAnimeId) { state = state.withJoin( currentTable: table, currentColumn: table.targetAnimeId, referencedTable: $$AnimeIdentityRelationshipsTableReferences ._targetAnimeIdTable(db), referencedColumn: $$AnimeIdentityRelationshipsTableReferences ._targetAnimeIdTable(db) .animeId, ) as T; } return state; }, getPrefetchedDataCallback: (items) async { return []; }, ); }, ), ) |
| S1428 | símbolo | app/lib/data/local_db/app_database.g.dart:5116 | typedef $$AnimeIdentityRelationshipsTableProcessedTableManager = ProcessedTableManager< _$AppDatabase, $AnimeIdentityRelationshipsTable, AnimeIdentityRelationship, $$AnimeIdentityRelationshipsTableFilterComposer, $$AnimeIdentityRelationshipsTableOrderingComposer, $$AnimeIdentityRelationshipsTableAnnotationComposer, $$AnimeIdentityRelationshipsTableCreateCompanionBuilder, $$AnimeIdentityRelationshipsTableUpdateCompanionBuilder, (AnimeIdentityRelationship, $$AnimeIdentityRelationshipsTableReferences), AnimeIdentityRelationship, PrefetchHooks Function( |
| S1429 | símbolo | app/lib/data/local_db/app_database.g.dart:5130 | typedef $$LocalLibraryEntriesTableCreateCompanionBuilder = LocalLibraryEntriesCompanion Function( |
| S1430 | símbolo | app/lib/data/local_db/app_database.g.dart:5137 | typedef $$LocalLibraryEntriesTableUpdateCompanionBuilder = LocalLibraryEntriesCompanion Function( |
| S1431 | símbolo | app/lib/data/local_db/app_database.g.dart:5145 | final class $$LocalLibraryEntriesTableReferences extends BaseReferences< _$AppDatabase, $LocalLibraryEntriesTable, LocalLibraryEntry > |
| S1432 | símbolo | app/lib/data/local_db/app_database.g.dart:5152 | $$LocalLibraryEntriesTableReferences( super.$_db, super.$_table, super.$_typedResult, ) |
| S1433 | símbolo | app/lib/data/local_db/app_database.g.dart:5163 | $$AnimeIdentityEntriesTableProcessedTableManager get animeId |
| S1434 | símbolo | app/lib/data/local_db/app_database.g.dart:5178 | class $$LocalLibraryEntriesTableFilterComposer extends Composer<_$AppDatabase, $LocalLibraryEntriesTable> |
| S1435 | símbolo | app/lib/data/local_db/app_database.g.dart:5180 | $$LocalLibraryEntriesTableFilterComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1436 | símbolo | app/lib/data/local_db/app_database.g.dart:5187 | ColumnFilters<DateTime> get addedAtUtc |
| S1437 | símbolo | app/lib/data/local_db/app_database.g.dart:5192 | ColumnFilters<String> get status |
| S1438 | símbolo | app/lib/data/local_db/app_database.g.dart:5197 | $$AnimeIdentityEntriesTableFilterComposer get animeId |
| S1439 | símbolo | app/lib/data/local_db/app_database.g.dart:5221 | class $$LocalLibraryEntriesTableOrderingComposer extends Composer<_$AppDatabase, $LocalLibraryEntriesTable> |
| S1440 | símbolo | app/lib/data/local_db/app_database.g.dart:5223 | $$LocalLibraryEntriesTableOrderingComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1441 | símbolo | app/lib/data/local_db/app_database.g.dart:5230 | ColumnOrderings<DateTime> get addedAtUtc |
| S1442 | símbolo | app/lib/data/local_db/app_database.g.dart:5235 | ColumnOrderings<String> get status |
| S1443 | símbolo | app/lib/data/local_db/app_database.g.dart:5240 | $$AnimeIdentityEntriesTableOrderingComposer get animeId |
| S1444 | símbolo | app/lib/data/local_db/app_database.g.dart:5265 | class $$LocalLibraryEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $LocalLibraryEntriesTable> |
| S1445 | símbolo | app/lib/data/local_db/app_database.g.dart:5267 | $$LocalLibraryEntriesTableAnnotationComposer({ required super.$db, required super.$table, super.joinBuilder, super.$addJoinBuilderToRootComposer, super.$removeJoinBuilderFromRootComposer, }) |
| S1446 | símbolo | app/lib/data/local_db/app_database.g.dart:5274 | GeneratedColumn<DateTime> get addedAtUtc |
| S1447 | símbolo | app/lib/data/local_db/app_database.g.dart:5279 | GeneratedColumn<String> get status |
| S1448 | símbolo | app/lib/data/local_db/app_database.g.dart:5282 | $$AnimeIdentityEntriesTableAnnotationComposer get animeId |
| S1449 | símbolo | app/lib/data/local_db/app_database.g.dart:5307 | class $$LocalLibraryEntriesTableTableManager extends RootTableManager< _$AppDatabase, $LocalLibraryEntriesTable, LocalLibraryEntry, $$LocalLibraryEntriesTableFilterComposer, $$LocalLibraryEntriesTableOrderingComposer, $$LocalLibraryEntriesTableAnnotationComposer, $$LocalLibraryEntriesTableCreateCompanionBuilder, $$LocalLibraryEntriesTableUpdateCompanionBuilder, (LocalLibraryEntry, $$LocalLibraryEntriesTableReferences), LocalLibraryEntry, PrefetchHooks Function( |
| S1450 | símbolo | app/lib/data/local_db/app_database.g.dart:5322 | $$LocalLibraryEntriesTableTableManager( _$AppDatabase db, $LocalLibraryEntriesTable table, ) : super( TableManagerState( db: db, table: table, createFilteringComposer: () => $$LocalLibraryEntriesTableFilterComposer($db: db, $table: table), createOrderingComposer: () => $$LocalLibraryEntriesTableOrderingComposer( $db: db, $table: table, ), createComputedFieldComposer: () => $$LocalLibraryEntriesTableAnnotationComposer( $db: db, $table: table, ), updateCompanionCallback: ({ Value<String> animeId = const Value.absent(), Value<DateTime> addedAtUtc = const Value.absent(), Value<String> status = const Value.absent(), Value<int> rowid = const Value.absent(), }) => LocalLibraryEntriesCompanion( animeId: animeId, addedAtUtc: addedAtUtc, status: status, rowid: rowid, ), createCompanionCallback: ({ required String animeId, required DateTime addedAtUtc, Value<String> status = const Value.absent(), Value<int> rowid = const Value.absent(), }) => LocalLibraryEntriesCompanion.insert( animeId: animeId, addedAtUtc: addedAtUtc, status: status, rowid: rowid, ), withReferenceMapper: (p0) => p0 .map( (e) => ( e.readTable<$LocalLibraryEntriesTable, LocalLibraryEntry>( table, ), $$LocalLibraryEntriesTableReferences(db, table, e), ), ) .toList(), prefetchHooksCallback: ({animeId = false}) { return PrefetchHooks( db: db, explicitlyWatchedTables: [], addJoins: < T extends TableManagerState< dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic > >(state) { if (animeId) { state = state.withJoin( currentTable: table, currentColumn: table.animeId, referencedTable: $$LocalLibraryEntriesTableReferences ._animeIdTable(db), referencedColumn: $$LocalLibraryEntriesTableReferences ._animeIdTable(db) .animeId, ) as T; } return state; }, getPrefetchedDataCallback: (items) async { return []; }, ); }, ), ) |
| S1451 | símbolo | app/lib/data/local_db/app_database.g.dart:5418 | typedef $$LocalLibraryEntriesTableProcessedTableManager = ProcessedTableManager< _$AppDatabase, $LocalLibraryEntriesTable, LocalLibraryEntry, $$LocalLibraryEntriesTableFilterComposer, $$LocalLibraryEntriesTableOrderingComposer, $$LocalLibraryEntriesTableAnnotationComposer, $$LocalLibraryEntriesTableCreateCompanionBuilder, $$LocalLibraryEntriesTableUpdateCompanionBuilder, (LocalLibraryEntry, $$LocalLibraryEntriesTableReferences), LocalLibraryEntry, PrefetchHooks Function( |
| S1452 | símbolo | app/lib/data/local_db/app_database.g.dart:5433 | class $AppDatabaseManager |
| S1453 | símbolo | app/lib/data/local_db/app_database.g.dart:5435 | $AppDatabaseManager(this._db) |
| S1454 | símbolo | app/lib/data/local_db/app_database.g.dart:5436 | $$SettingsEntriesTableTableManager get settingsEntries |
| S1455 | símbolo | app/lib/data/local_db/app_database.g.dart:5438 | $$ProgressDocumentsTableTableManager get progressDocuments |
| S1456 | símbolo | app/lib/data/local_db/app_database.g.dart:5440 | $$LatestAnimeSearchTableTableManager get latestAnimeSearch |
| S1457 | símbolo | app/lib/data/local_db/app_database.g.dart:5442 | $$PlaybackProgressEntriesTableTableManager get playbackProgressEntries |
| S1458 | símbolo | app/lib/data/local_db/app_database.g.dart:5447 | $$AnimeIdentityEntriesTableTableManager get animeIdentityEntries |
| S1459 | símbolo | app/lib/data/local_db/app_database.g.dart:5449 | $$ExternalAnimeIdentifiersTableTableManager get externalAnimeIdentifiers |
| S1460 | símbolo | app/lib/data/local_db/app_database.g.dart:5454 | $$AnimeIdentityRelationshipsTableTableManager get animeIdentityRelationships |
| S1461 | símbolo | app/lib/data/local_db/app_database.g.dart:5460 | $$LocalLibraryEntriesTableTableManager get localLibraryEntries |
| S1462 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:5 | /// Bounded persistent storage for explicitly requested AniList IDs. final class DriftAniListDetailCache |
| S1463 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:7 | const DriftAniListDetailCache(this.database) |
| S1464 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:8 | database |
| S1465 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:10 | Future<({String payload, DateTime fetchedAt})?> read(int id) |
| S1466 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:27 | Future<List<String>> findByTitle(String title, int limit, int offset) |
| S1467 | símbolo | app/lib/data/local_db/drift_anilist_detail_cache.dart:51 | Future<void> write(int id, String payload, DateTime fetchedAt) |
| S1468 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:11 | final class DriftAnimeIdentityRepository implements AnimeIdentityRepository |
| S1469 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:12 | DriftAnimeIdentityRepository({ required this.database, required this.idGenerator, DateTime Function()? clock, }) : _clock = clock ?? DateTime.now |
| S1470 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:18 | database |
| S1471 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:19 | idGenerator |
| S1472 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:22 | @override Future<Result<AnimeIdentity?>> getById(AnimeId id) |
| S1473 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:31 | @override Future<Result<AnimeIdentity?>> findByExternalId(ExternalAnimeId id) |
| S1474 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:48 | @override Future<Result<AnimeIdentity>> getOrCreateForExternalId( ExternalAnimeId id, { required IdentityLinkEvidence evidence, }) |
| S1475 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:107 | @override Future<Result<AnimeIdentity>> createLocalIdentity() |
| S1476 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:132 | @override Future<Result<AnimeIdentity>> linkExternalId({ required AnimeId animeId, required ExternalAnimeId externalId, required IdentityLinkEvidence evidence, }) |
| S1477 | símbolo | app/lib/data/local_db/drift_anime_identity_repository.dart:188 | @override Future<Result<AnimeIdentity>> addRelationship({ required AnimeId sourceId, required AnimeId targetId, required AnimeRelationshipKind kind, required IdentityLinkEvidence evidence, }) |
| S1478 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:10 | final class DriftLocalLibraryRepository implements LocalLibraryRepository |
| S1479 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:11 | DriftLocalLibraryRepository({ required this.database, DateTime Function()? clock, }) : _clock = clock ?? DateTime.now |
| S1480 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:16 | database |
| S1481 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:19 | @override Future<Result<List<LibraryEntry>>> list() |
| S1482 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:31 | @override Future<Result<LibraryEntry?>> get(AnimeId animeId) |
| S1483 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:44 | @override Future<Result<LibraryEntry>> add(AnimeId animeId) |
| S1484 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:78 | @override Future<Result<LibraryEntry>> setStatus( AnimeId animeId, LibraryStatus status, ) |
| S1485 | símbolo | app/lib/data/local_db/drift_local_library_repository.dart:106 | @override Future<Result<void>> remove(AnimeId animeId) |
| S1486 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:10 | final class DriftPlaybackProgressRepository implements PlaybackProgressRepository |
| S1487 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:12 | const DriftPlaybackProgressRepository(this.database) |
| S1488 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:13 | database |
| S1489 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:15 | @override Future<Result<void>> upsert(PlaybackProgress progress) |
| S1490 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:41 | @override Future<Result<PlaybackProgress?>> get(ProgressKey identity) |
| S1491 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:78 | @override Future<Result<List<PlaybackProgress>>> list(ContentIdFilter filter) |
| S1492 | símbolo | app/lib/data/local_db/drift_playback_progress_repository.dart:116 | @override Future<Result<void>> delete(ProgressKey key) |
| S1493 | símbolo | app/lib/data/local_db/local_progress_repository.dart:9 | final class LocalProgressRepository implements ProgressRepository |
| S1494 | símbolo | app/lib/data/local_db/local_progress_repository.dart:10 | LocalProgressRepository({required this.database, DateTime Function()? clock}) : _clock = clock ?? DateTime.now |
| S1495 | símbolo | app/lib/data/local_db/local_progress_repository.dart:13 | database |
| S1496 | símbolo | app/lib/data/local_db/local_progress_repository.dart:16 | @override Future<Result<void>> save(ProgressDraft draft) |
| S1497 | símbolo | app/lib/data/local_db/local_progress_repository.dart:47 | @override Future<Result<ProgressDocument?>> getByIdentity(String identity) |
| S1498 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:3 | /// AnimeApp-owned identities; external provider IDs are stored separately. class AnimeIdentityEntries extends Table |
| S1499 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:5 | TextColumn get animeId |
| S1500 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:7 | DateTimeColumn get createdAtUtc |
| S1501 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:9 | @override Set<Column<Object>> get primaryKey |
| S1502 | símbolo | app/lib/data/local_db/tables/anime_identity_entries.dart:12 | @override List<String> get customConstraints |
| S1503 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:5 | /// Directed, typed franchise relationships. No title-based relationships are /// generated automatically. class AnimeIdentityRelationships extends Table |
| S1504 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:8 | @ReferenceName('outgoingRelationships') TextColumn get sourceAnimeId |
| S1505 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:17 | @ReferenceName('incomingRelationships') TextColumn get targetAnimeId |
| S1506 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:26 | TextColumn get relationshipKind |
| S1507 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:28 | TextColumn get evidence |
| S1508 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:30 | DateTimeColumn get linkedAtUtc |
| S1509 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:32 | @override Set<Column<Object>> get primaryKey |
| S1510 | símbolo | app/lib/data/local_db/tables/anime_identity_relationships.dart:39 | @override List<String> get customConstraints |
| S1511 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:5 | /// Namespaced crosswalk; each provider ID can point to at most one local ID. @TableIndex(name: 'external_anime_identifiers_by_anime', columns: |
| S1512 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:8 | TextColumn get providerId |
| S1513 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:10 | TextColumn get externalId |
| S1514 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:12 | TextColumn get animeId |
| S1515 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:20 | TextColumn get evidence |
| S1516 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:22 | DateTimeColumn get linkedAtUtc |
| S1517 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:24 | @override Set<Column<Object>> get primaryKey |
| S1518 | símbolo | app/lib/data/local_db/tables/external_anime_identifiers.dart:27 | @override List<String> get customConstraints |
| S1519 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:3 | /// One replace-on-search slot; avoids accumulating or bulk storing API data. class LatestAnimeSearch extends Table |
| S1520 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:5 | TextColumn get slot |
| S1521 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:7 | TextColumn get searchQuery |
| S1522 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:9 | IntColumn get page |
| S1523 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:11 | IntColumn get perPage |
| S1524 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:13 | TextColumn get resultJson |
| S1525 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:15 | DateTimeColumn get cachedAt |
| S1526 | símbolo | app/lib/data/local_db/tables/latest_anime_search.dart:17 | @override Set<Column<Object>> get primaryKey |
| S1527 | símbolo | app/lib/data/local_db/tables/library_entries.dart:5 | /// User-owned local library membership, independent from metadata retention. @TableIndex(name: 'library_entries_by_added_at', columns: |
| S1528 | símbolo | app/lib/data/local_db/tables/library_entries.dart:8 | TextColumn get animeId |
| S1529 | símbolo | app/lib/data/local_db/tables/library_entries.dart:16 | DateTimeColumn get addedAtUtc |
| S1530 | símbolo | app/lib/data/local_db/tables/library_entries.dart:18 | TextColumn get status |
| S1531 | símbolo | app/lib/data/local_db/tables/library_entries.dart:21 | @override Set<Column<Object>> get primaryKey |
| S1532 | símbolo | app/lib/data/local_db/tables/library_entries.dart:24 | @override String get tableName |
| S1533 | símbolo | app/lib/data/local_db/tables/library_entries.dart:27 | @override List<String> get customConstraints |
| S1534 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:3 | class PlaybackProgressEntries extends Table |
| S1535 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:4 | TextColumn get contentId |
| S1536 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:5 | TextColumn get episodeId |
| S1537 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:6 | IntColumn get positionMs |
| S1538 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:7 | IntColumn get durationMs |
| S1539 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:8 | DateTimeColumn get updatedAtUtc |
| S1540 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:9 | TextColumn get completion |
| S1541 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:10 | IntColumn get revision |
| S1542 | símbolo | app/lib/data/local_db/tables/playback_progress_entries.dart:12 | @override Set<Column<Object>> get primaryKey |
| S1543 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:3 | /// Opaque durable progress document; business semantics belong to F1.10. class ProgressDocuments extends Table |
| S1544 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:5 | TextColumn get documentKey |
| S1545 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:7 | TextColumn get payloadJson |
| S1546 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:9 | DateTimeColumn get updatedAt |
| S1547 | símbolo | app/lib/data/local_db/tables/progress_documents.dart:11 | @override Set<Column<Object>> get primaryKey |
| S1548 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:3 | /// Persisted value envelope. Domain code owns serialization and validation. class SettingsEntries extends Table |
| S1549 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:5 | TextColumn get settingKey |
| S1550 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:7 | TextColumn get valueJson |
| S1551 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:9 | DateTimeColumn get updatedAt |
| S1552 | símbolo | app/lib/data/local_db/tables/settings_entries.dart:11 | @override Set<Column<Object>> get primaryKey |
| S1553 | símbolo | app/lib/data/local_db/uuid_anime_id_generator.dart:5 | /// RFC 4122 version 4 IDs generated locally with the platform secure RNG. final class UuidAnimeIdGenerator implements AnimeIdGenerator |
| S1554 | símbolo | app/lib/data/local_db/uuid_anime_id_generator.dart:7 | UuidAnimeIdGenerator({Random? random}) : _random = random ?? Random.secure() |
| S1555 | símbolo | app/lib/data/local_db/uuid_anime_id_generator.dart:11 | @override AnimeId generate() |
| S1556 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:7 | /// Deterministic, synthetic catalog for local development and tests. /// /// This provider performs no I/O and contains no data from AniList, TMDB, or /// Kitsu. Replace it only after a real provider is approved for the product. final class FakeMetadataProvider implements MetadataProvider, PublicAnimeBrowseProvider |
| S1557 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:13 | FakeMetadataProvider({DateTime Function()? clock}) : _clock = clock ?? _fixedClock |
| S1558 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:16 | providerId = MetadataProviderId('demo') |
| S1559 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:19 | searchRequestCount = 0 |
| S1560 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:20 | detailsRequestCount = 0 |
| S1561 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:67 | @override MetadataProviderId get id |
| S1562 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:70 | @override Set<MetadataCapability> get capabilities |
| S1563 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:76 | @override Future<ProviderResult<List<ProviderAnimeMetadata>>> searchAnime( String query, { int limit = 20, }) |
| S1564 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:96 | @override Future<ProviderResult<List<ProviderAnimeMetadata>>> browsePopular({ int limit = 20, }) |
| S1565 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:101 | @override Future<ProviderResult<List<ProviderAnimeMetadata>>> browseTrending({ int limit = 20, }) |
| S1566 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:107 | @override Future<ProviderResult<ProviderAnimeMetadata>> getAnimeByExternalId( ExternalAnimeId id, ) |
| S1567 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:119 | @override Future<ProviderResult<List<ProviderEpisodeMetadata>>> getEpisodes( ExternalAnimeId animeId, ) |
| S1568 | símbolo | app/lib/data/metadata/fake_metadata_provider.dart:124 | @override Future<ProviderResult<ProviderHealth>> checkHealth() |
| S1569 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:11 | typedef OpenSubtitlesSecret = Future<String?> Function(); |
| S1570 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:12 | typedef OpenSubtitlesStorageDirectory = Future<Directory> Function(); |
| S1571 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:13 | typedef OpenSubtitlesFileToken = String Function(); |
| S1572 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:15 | /// OpenSubtitles.com REST API v1 adapter. API and file-download hosts are /// validated separately; credentials are sent only to the API origin. final class OpenSubtitlesClient implements ExternalSubtitleCatalog |
| S1573 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:18 | factory OpenSubtitlesClient({ required OpenSubtitlesSecret apiKey, OpenSubtitlesSecret? bearerToken, Dio? dio, Directory? storageDirectory, OpenSubtitlesStorageDirectory? storageDirectoryProvider, OpenSubtitlesFileToken? fileToken, int maxDownloadBytes = 10 * 1024 * 1024, }) |
| S1574 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:52 | bearerToken |
| S1575 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:55 | storageDirectory |
| S1576 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:58 | maxDownloadBytes |
| S1577 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:63 | void close() |
| S1578 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:72 | @override Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search( ExternalSubtitleQuery query, ) |
| S1579 | símbolo | app/lib/data/opensubtitles/opensubtitles_client.dart:178 | @override Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download( ExternalSubtitleCandidate candidate, ) |
| S1580 | símbolo | app/lib/data/player/engine/active_player_lease.dart:3 | /// Reserves the single native-player slot until asynchronous cleanup succeeds. /// /// Concurrent [release] calls share the same Future. If cleanup fails, the /// lease stays active and a later call retries the original cleanup callback. final class ActivePlayerLease |
| S1581 | símbolo | app/lib/data/player/engine/active_player_lease.dart:12 | /// Whether an allocated native player still owns the exclusive slot. static bool get hasActiveLease |
| S1582 | símbolo | app/lib/data/player/engine/active_player_lease.dart:15 | static ActivePlayerLease acquire() |
| S1583 | símbolo | app/lib/data/player/engine/active_player_lease.dart:22 | /// Retries cleanup for an active lease whose previous cleanup failed. /// Throws if a live owner has not requested cleanup yet. static Future<void> retryPendingRelease() |
| S1584 | símbolo | app/lib/data/player/engine/active_player_lease.dart:38 | Future<void> release(Future<void> Function() cleanup) |
| S1585 | símbolo | app/lib/data/player/engine/active_player_lease.dart:69 | /// A different live engine still owns the single native-player slot. final class ActivePlayerLeaseInUse extends StateError |
| S1586 | símbolo | app/lib/data/player/engine/active_player_lease.dart:71 | ActivePlayerLeaseInUse() : super('An active media_kit Player still owns the lease.') |
| S1587 | símbolo | app/lib/data/player/engine/media_codec_support_android.dart:3 | /// Android H.264 policy. /// /// media_kit/libmpv on Android decodes H.264 through `MediaCodec` (hardware or /// software), so the application ships no decoder and nothing is prepared. /// Android was not executed in this project yet: the report states the /// expected strategy, not a verified device run. final class AndroidMediaCodecSupport |
| S1588 | símbolo | app/lib/data/player/engine/media_codec_support_android.dart:10 | const AndroidMediaCodecSupport() |
| S1589 | símbolo | app/lib/data/player/engine/media_codec_support_android.dart:12 | MediaCodecReport prepare() |
| S1590 | símbolo | app/lib/data/player/engine/media_codec_support_io.dart:11 | /// Prepares H.264 support once per process and reports the strategy used. /// /// The result is cached: the first call decides for the process lifetime, /// because a decoder mapped by the dynamic linker cannot be replaced later. MediaCodecReport prepareMediaCodecSupport() |
| S1591 | símbolo | app/lib/data/player/engine/media_codec_support_io.dart:29 | /// Selects the platform adapter. Injectable so tests can exercise every /// platform branch without leaving Linux. final class MediaCodecSupportRegistry |
| S1592 | símbolo | app/lib/data/player/engine/media_codec_support_io.dart:32 | MediaCodecSupportRegistry({ String? operatingSystem, LinuxMediaCodecSupport? linux, AndroidMediaCodecSupport? android, WindowsMediaCodecSupport? windows, SystemMediaCodecSupport? other, }) : _operatingSystem = operatingSystem ?? Platform.operatingSystem, _linux = linux ?? LinuxMediaCodecSupport(), _android = android ?? const AndroidMediaCodecSupport(), _windows = windows ?? const WindowsMediaCodecSupport(), _other = other ?? const SystemMediaCodecSupport() |
| S1593 | símbolo | app/lib/data/player/engine/media_codec_support_io.dart:50 | MediaCodecReport prepare() |
| S1594 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:8 | linuxOpenH264FileName = 'libopenh264.so.8' |
| S1595 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:11 | linuxOpenH264PathVariable = 'KONGROO_OPENH264_PATH' |
| S1596 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:16 | /// Whether a decoder was loaded into this process at runtime. bool get linuxDecoderPreloaded |
| S1597 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:19 | /// Linux H.264 policy. /// /// Fedora ships `noopenh264`: an ABI-compatible stub without a decoder, and /// `libavcodec` declares `libopenh264.so.8` as `DT_NEEDED`. The supported fix /// is the bundled decoder installed by `app/linux/local_codec.cmake`, which /// also gives the executable a transitive `DT_RPATH`; this adapter reports /// that case. /// /// An explicitly configured decoder outside the bundle is loaded at runtime /// as a best effort. The app does not search cwd or ancestor directories for /// native libraries. Preloading cannot replace a library the dynamic linker /// already mapped for a `DT_NEEDED` entry. final class LinuxMediaCodecSupport |
| S1598 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:32 | LinuxMediaCodecSupport({ Map<String, String>? environment, String? resolvedExecutable, bool Function(String path)? isRegularFile, DynamicLibrary Function(String path)? openLibrary, }) : _environment = environment ?? Platform.environment, _resolvedExecutable = resolvedExecutable ?? Platform.resolvedExecutable, _isRegularFile = isRegularFile ?? _isRegularFileWithElfHeader, _openLibrary = openLibrary ?? DynamicLibrary.open |
| S1599 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:47 | MediaCodecReport prepare() |
| S1600 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:94 | /// Ordered, deduplicated decoder candidates for the current process. /// /// Resolution is pure so every branch is unit-testable. It considers only an /// explicit [linuxOpenH264PathVariable] override and the library adjacent to /// the executable; it never walks cwd or executable ancestors. final class LinuxCodecLocator |
| S1601 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:100 | const LinuxCodecLocator({ this.environment = const {}, required this.resolvedExecutable, required this.isRegularFile, }) |
| S1602 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:106 | environment |
| S1603 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:107 | resolvedExecutable |
| S1604 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:108 | isRegularFile |
| S1605 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:110 | List<String> candidates() |
| S1606 | símbolo | app/lib/data/player/engine/media_codec_support_linux.dart:125 | String? resolve() |
| S1607 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:1 | /// How the application provides H.264 decoding to media_kit/libmpv. /// /// The enum is platform-agnostic so every adapter reports the same contract; /// only the strategy differs per operating system. enum MediaCodecStrategy |
| S1608 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:6 | /// The operating system decodes H.264 (Android MediaCodec, Windows /// Media Foundation / ffmpeg bundled by media_kit). platform |
| S1609 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:10 | /// A verified decoder was installed next to the application and the loader /// resolves it before the system copy (Linux `DT_RPATH`). bundled |
| S1610 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:14 | /// A decoder was loaded into the process at runtime from the project tree. /// /// This only helps where the media stack resolves the codec lazily; it never /// replaces a library the dynamic linker already mapped. preloaded |
| S1611 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:20 | /// Nothing was prepared; the system library policy decides. system |
| S1612 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:24 | /// Result of preparing the platform decoder stack once per process. /// /// Adapters must never throw: a missing decoder is a reported state, not a /// startup failure. Callers log the report and continue. final class MediaCodecReport |
| S1613 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:29 | const MediaCodecReport({ required this.platform, required this.strategy, this.decoderPath, this.detail, }) |
| S1614 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:37 | platform |
| S1615 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:39 | strategy |
| S1616 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:42 | decoderPath |
| S1617 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:45 | detail |
| S1618 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:47 | /// Whether a decoder path is known to exist for H.264 playback. /// /// `system` means the platform policy is unknown to the application, so it /// is reported as not prepared instead of assumed healthy. bool get prepared |
| S1619 | símbolo | app/lib/data/player/engine/media_codec_support_model.dart:53 | @override String toString() |
| S1620 | símbolo | app/lib/data/player/engine/media_codec_support_stub.dart:3 | /// Environments without `dart:io` (web) have no native media_kit backend, so /// there is nothing to prepare. MediaCodecReport prepareMediaCodecSupport() |
| S1621 | símbolo | app/lib/data/player/engine/media_codec_support_system.dart:3 | /// Fallback for platforms without a dedicated adapter (macOS, iOS, BSD, ...). /// /// Nothing is inferred about their codec stack: the report delegates to the /// system policy instead of claiming playback support. final class SystemMediaCodecSupport |
| S1622 | símbolo | app/lib/data/player/engine/media_codec_support_system.dart:8 | const SystemMediaCodecSupport() |
| S1623 | símbolo | app/lib/data/player/engine/media_codec_support_system.dart:10 | MediaCodecReport prepare(String platform) |
| S1624 | símbolo | app/lib/data/player/engine/media_codec_support_windows.dart:3 | /// Windows H.264 policy. /// /// media_kit ships its own libmpv/ffmpeg build for Windows, including the /// H.264 decoder, so the application ships no extra decoder and nothing is /// prepared. Windows was not executed in this project yet: the report states /// the expected strategy, not a verified desktop run. final class WindowsMediaCodecSupport |
| S1625 | símbolo | app/lib/data/player/engine/media_codec_support_windows.dart:10 | const WindowsMediaCodecSupport() |
| S1626 | símbolo | app/lib/data/player/engine/media_codec_support_windows.dart:12 | MediaCodecReport prepare() |
| S1627 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:21 | /// F2.2 adapter. The sole owner of one media_kit Player and its video surface. final class MediaKitSpikeEngine implements PlaybackSpikeEngine, PlaybackAudioSelection, PlaybackVideoSelection, PlaybackPerformanceSource |
| S1628 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:28 | factory MediaKitSpikeEngine({ Set<Uri> demoSources = const {}, Set<Uri> trustedExternalSources = const {}, Map<Uri, List<ProviderSubtitle>> providerSubtitles = const {}, }) |
| S1629 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:102 | /// Creates an engine whose native dispose call can be fault-injected. @visibleForTesting factory MediaKitSpikeEngine.forTesting({ required Future<void> Function(Player player) disposePlayer, Future<void> Function()? auxiliaryCleanupForTesting, }) |
| S1630 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:163 | /// Retries cleanup left pending after a previous dispose failure. /// If native Player.dispose itself failed, the lease stays quarantined and /// this rethrows that failure; restarting the process is required before a /// new native Player can be created safely. static Future<void> retryPendingDispose() |
| S1631 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:170 | /// Whether a live or quarantined native Player still owns the exclusive slot. static bool get hasActivePlayerLease |
| S1632 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:222 | /// The UI surface uses this controller for this adapter's single Player. VideoController get videoController |
| S1633 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:227 | /// Creates the presentation controller after the caller owns this engine. /// If setup throws, the caller can still await [dispose] and retry cleanup. void attachVideoSurface() |
| S1634 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:237 | /// Most recently observed engine state, useful for diagnostics/tests. PlaybackSpikeSnapshot get currentSnapshot |
| S1635 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:240 | @override Future<PlaybackPerformanceSample> samplePerformance() |
| S1636 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:260 | @override Stream<PlaybackSpikeSnapshot> get snapshots |
| S1637 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:263 | @override Future<void> initialize() |
| S1638 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:307 | @override Future<void> open( Uri source, { int sourceGeneration = 0, PlaybackRequestHeaders httpHeaders = const PlaybackRequestHeaders.empty(), }) |
| S1639 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:433 | @override Future<void> play() |
| S1640 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:460 | @override Future<void> pause() |
| S1641 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:466 | @override Future<void> seek(Duration position) |
| S1642 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:472 | @override Future<void> setVolume(double volume) |
| S1643 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:487 | @override Future<void> selectSubtitleTrack(String id) |
| S1644 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:517 | @override Future<ExternalSubtitleDecision> loadExternalSubtitle( Uri source, { required HardsubStatus hardsubStatus, String? title, String? language, }) |
| S1645 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:557 | @override Future<void> applySubtitleStyle(SubtitleStyle style) |
| S1646 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:575 | @override Future<void> setSubtitleDelay(Duration delay) |
| S1647 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:586 | @override Future<void> stop() |
| S1648 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:607 | @override Future<void> dispose() |
| S1649 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:763 | @override Future<void> selectAudioTrack(String id) |
| S1650 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:788 | @override Future<void> selectVideoTrack(String id) |
| S1651 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:935 | @visibleForTesting Future<String> subtitlePropertyForTesting(String property) |
| S1652 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:970 | /// Cleanup failed after all safe cleanup steps were attempted. /// /// [nativePlayerStillOwned] is true only while the native-player lease remains /// quarantined. Auxiliary stream cleanup failures do not retain that lease /// after `Player.dispose()` has completed successfully. final class MediaKitSpikeEngineDisposeFailure extends StateError |
| S1653 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:976 | MediaKitSpikeEngineDisposeFailure({ required this.nativePlayerStillOwned, required this.cause, this.causeStack, }) : super('MediaKit engine cleanup failed.') |
| S1654 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:982 | nativePlayerStillOwned |
| S1655 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:983 | cause |
| S1656 | símbolo | app/lib/data/player/engine/media_kit_spike_engine.dart:984 | causeStack |
| S1657 | símbolo | app/lib/data/player/engine/mpv_performance_reader.dart:7 | /// Reads a bounded set of native properties once per requested sample. /// `NativePlayer.getProperty` returns an empty string for unavailable mpv /// properties. This reader never changes playback configuration. Future<PlaybackPerformanceSample> readMpvPerformance( Player player, { double? positionEventsPerSecond, }) |
| S1658 | símbolo | app/lib/data/player/engine/mpv_subtitle_properties_native.dart:3 | Future<void> writeMpvSubtitleProperty( Player player, String property, String value, ) |
| S1659 | símbolo | app/lib/data/player/engine/mpv_subtitle_properties_native.dart:34 | Future<String> readMpvSubtitleProperty(Player player, String property) |
| S1660 | símbolo | app/lib/data/player/engine/mpv_subtitle_properties_stub.dart:3 | Future<void> writeMpvSubtitleProperty( Player player, String property, String value, ) |
| S1661 | símbolo | app/lib/data/player/engine/mpv_subtitle_properties_stub.dart:11 | Future<String> readMpvSubtitleProperty(Player player, String property) |
| S1662 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:17 | enum AllAnimeAudioVariant |
| S1663 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:17 | sub |
| S1664 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:17 | dub |
| S1665 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:19 | /// Build-pinned crypto materials for the AllAnime/M.Kissa client-crypto /// protocol. The site rotates the mask and build id per release; the values /// are public client constants (they live in the site's own JS bundle, chunk /// `B3DA467b.js` for build 190) and are refreshed per release, exactly like /// every maintained CLI client does. /// /// Protocol (verified live 2026-11-18, mission ANILILI): /// 1. epoch = now / 604800000; boot token = /// hex(HMAC-SHA256(HMAC-SHA256(mask, bootPrefix), joinPrefix + epoch)) sent /// as `x-aa-boot` to `/client-crypto/v1/bootstrap?buildId=B&k=k7`, which /// returns the authoritative `epoch` and `partB` (base64 32 bytes). /// 2. request key = partB XOR mask (32 bytes). /// 3. `aaReq` = base64(0x01 ‖ iv ‖ AES-256-GCM(key, iv, payload)) where /// payload = |
| S1666 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:41 | const AllAnimeBootMaterials({ required this.buildId, required this.maskHex, required this.bootPrefix, required this.joinPrefix, required this.queryHash, this.lane = 'k7', }) |
| S1667 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:51 | current = AllAnimeBootMaterials( buildId: '190', maskHex: '65c85a8520d83eafafdff966cc3f5187ab774d238f60338ff4fc0ae7d941ca35', bootPrefix: 'rEVwtVi:190', joinPrefix: 'mkissa.to~k7~190~mkissa~', queryHash: '670bbf38d0868f446e2346c1e956ca2c40c416e733ca248fd54e04f1c8b99145', ) |
| S1668 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:60 | buildId |
| S1669 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:61 | maskHex |
| S1670 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:62 | bootPrefix |
| S1671 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:63 | joinPrefix |
| S1672 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:64 | queryHash |
| S1673 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:65 | lane |
| S1674 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:68 | epochMs = 604800000 |
| S1675 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:71 | final class AllAnimePlaybackProvider extends EpisodeSourceAdapter |
| S1676 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:72 | AllAnimePlaybackProvider( Dio client, { Uri? apiOrigin, this.variant = AllAnimeAudioVariant.sub, PublicPlaybackHttp? transport, AllAnimeBootMaterials materials = AllAnimeBootMaterials.current, }) : apiOrigin = apiOrigin ?? Uri.https('api.mkissa.net'), _materials = materials |
| S1677 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:96 | apiOrigin |
| S1678 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:97 | variant |
| S1679 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:111 | @override PlaybackProviderId get id |
| S1680 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:116 | @override Set<PlaybackProviderCapability> get capabilities |
| S1681 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:161 | @override Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime( AnimeIdentity identity, { required PlaybackCancellationToken cancellation, }) |
| S1682 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:290 | @override Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes( SourceAnimeMatch match, { required PlaybackCancellationToken cancellation, }) |
| S1683 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:302 | @override Future<PlaybackProviderResult<EpisodeRef>> findEpisode( SourceAnimeMatch match, { required int episodeNumber, required PlaybackCancellationToken cancellation, }) |
| S1684 | símbolo | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:313 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources( EpisodeRef episode, { required PlaybackCancellationToken cancellation, }) |
| S1685 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:14 | /// AnimeAV1 catalogue protocol adapted from Anilili d7b80f1 (MIT-0). /// Requires a confirmed MAL crosswalk. Host resolution belongs to resolvers. final class AnimeAv1PlaybackProvider extends EpisodeSourceAdapter |
| S1686 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:17 | AnimeAv1PlaybackProvider(Dio client, {Uri? origin}) : origin = origin ?? Uri.https('animeav1.com') |
| S1687 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:27 | origin |
| S1688 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:32 | @override PlaybackProviderId get id |
| S1689 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:35 | @override Set<PlaybackProviderCapability> get capabilities |
| S1690 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:120 | @override Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime( AnimeIdentity identity, { required PlaybackCancellationToken cancellation, }) |
| S1691 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:207 | @override Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes( SourceAnimeMatch match, { required PlaybackCancellationToken cancellation, }) |
| S1692 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:227 | /// One catalog pass instead of the three-phase default: the episode page /// already carries the media record (MAL id + episode index) and the embeds, /// so listing episodes first and re-fetching the media page would only add /// two round trips before the first frame. @override Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode requested, { required PlaybackCancellationToken cancellation, }) |
| S1693 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:256 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources( EpisodeRef episode, { required PlaybackCancellationToken cancellation, }) |
| S1694 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:358 | /// Bounded adaptation of Anilili's SvelteKit/devalue pageData/hydrate parser. abstract final class AnimeAv1PageData |
| S1695 | símbolo | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:360 | static Map<String, dynamic> decode(String text) |
| S1696 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:12 | enum AnimeGgAudioVariant |
| S1697 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:12 | sub |
| S1698 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:12 | dub |
| S1699 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:14 | /// AnimeGG public site adapter, adapted from Anilili's `AnivexaClient.animegg` /// (project Anilili, MIT-0) to the site's current markup: search anchors carry /// the title in an `h2`, episode lists use `anm_det_pop` links, and watch pages /// expose `data-toggle="tab"` mirrors whose `/embed/ |
| S1700 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:21 | AnimeGgPlaybackProvider( Dio client, { Uri? origin, this.variant = AnimeGgAudioVariant.sub, PublicPlaybackHttp? transport, }) : origin = origin ?? Uri.https('www.animegg.org') |
| S1701 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:35 | origin |
| S1702 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:36 | variant |
| S1703 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:69 | @override PlaybackProviderId get id |
| S1704 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:74 | @override Set<PlaybackProviderCapability> get capabilities |
| S1705 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:107 | @override Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime( AnimeIdentity identity, { required PlaybackCancellationToken cancellation, }) |
| S1706 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:158 | @override Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes( SourceAnimeMatch match, { required PlaybackCancellationToken cancellation, }) |
| S1707 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:170 | @override Future<PlaybackProviderResult<EpisodeRef>> findEpisode( SourceAnimeMatch match, { required int episodeNumber, required PlaybackCancellationToken cancellation, }) |
| S1708 | símbolo | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:181 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources( EpisodeRef episode, { required PlaybackCancellationToken cancellation, }) |
| S1709 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:12 | /// AniZone public site adapter, adapted from Anilili's `AnivexaClient.anizone` /// (project Anilili, MIT-0) to the site's current Livewire markup: search /// results and the player manifest live in escaped JSON snapshots, so the /// adapter decodes those escapes instead of the retired `anmTitles` markup. /// No cookies, sessions, or JavaScript execution; the page's own published /// player JSON is read as text. final class AniZonePlaybackProvider extends EpisodeSourceAdapter |
| S1710 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:19 | AniZonePlaybackProvider( Dio client, { Uri? origin, PublicPlaybackHttp? transport, }) : origin = origin ?? Uri.https('anizone.to') |
| S1711 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:32 | origin |
| S1712 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:57 | @override PlaybackProviderId get id |
| S1713 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:60 | @override Set<PlaybackProviderCapability> get capabilities |
| S1714 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:81 | @override Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime( AnimeIdentity identity, { required PlaybackCancellationToken cancellation, }) |
| S1715 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:127 | @override Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes( SourceAnimeMatch match, { required PlaybackCancellationToken cancellation, }) |
| S1716 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:139 | @override Future<PlaybackProviderResult<EpisodeRef>> findEpisode( SourceAnimeMatch match, { required int episodeNumber, required PlaybackCancellationToken cancellation, }) |
| S1717 | símbolo | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:150 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources( EpisodeRef episode, { required PlaybackCancellationToken cancellation, }) |
| S1718 | símbolo | app/lib/data/player/providers/episode_source_support.dart:4 | /// Shared helpers for every `EpisodeSourceAdapter` implementation. /// /// The adapters previously carried three identical private helpers /// (`_read`, `_check`, `_contractTitle`); they now delegate here so the /// failure mapping and the conservative title normalization have exactly /// one definition. Behavior is unchanged except where noted: MegaPlay used /// to let `ArgumentError` escape to the adapter's catch-all (`unavailable`) /// and now maps it to `invalidResponse`, the semantically correct /// classification for malformed payloads (both are non-transient). abstract final class EpisodeSourceSupport |
| S1719 | símbolo | app/lib/data/player/providers/episode_source_support.dart:14 | /// Cancellation guard. Throws the transport's `cancelled` failure so the /// provider result maps to the shared cancellation kind. static void check(PlaybackCancellationToken cancellation) |
| S1720 | símbolo | app/lib/data/player/providers/episode_source_support.dart:22 | /// Conservative contract-title normalization (lowercase, collapsed /// whitespace). Matching stays strict: an adapter may only accept a /// candidate whose normalized title equals one of the requested titles. static String contractTitle(String value) |
| S1721 | símbolo | app/lib/data/player/providers/episode_source_support.dart:28 | /// Wraps a provider load into a result: /// `null` → [PlaybackProviderEmpty], transport failures → their own /// result, malformed payloads (`FormatException`, `ArgumentError`) → /// `invalidResponse`. Cancellation surfaces through the transport failure. static Future<PlaybackProviderResult<T>> read<T>( Future<T?> Function() load, ) |
| S1722 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:6 | /// Normalizes an already-public, direct media URI without owning transport or /// playback. Host reachability and decoding are verified by the playback path. final class DirectMediaHostResolver implements PlaybackVideoHostResolver |
| S1723 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:9 | DirectMediaHostResolver({DateTime Function()? clock}) : _clock = clock ?? DateTime.now |
| S1724 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:12 | stableHostId = 'direct-media' |
| S1725 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:16 | @override String get hostId |
| S1726 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:19 | @override String get resolverId |
| S1727 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:22 | @override bool supports(SourceCandidate candidate) |
| S1728 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:30 | @override Future<PlaybackProviderResult<PlayableSource>> resolve( PlaybackSource source, SourceCandidate candidate, { required PlaybackCancellationToken cancellation, }) |
| S1729 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:71 | static PlaybackMediaFormat formatFor( Uri uri, { PlaybackMediaFormat declared = PlaybackMediaFormat.unknown, }) |
| S1730 | símbolo | app/lib/data/player/providers/hosts/direct_media_host_resolver.dart:83 | /// Rejects obvious local/private destinations before handing a source to /// libmpv. DNS names are not resolved here; host-specific network adapters /// must validate redirects and resolved addresses at their own boundary. static bool isSyntacticallyPublicHttps(Uri uri, {int port = 443}) |
| S1731 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:10 | /// VOE's published player config, adapted from Anilili AnimeAv1Parser (MIT-0). /// Follows one literal public player redirect; never runs JavaScript. final class VoeVideoHostResolver implements PlaybackVideoHostResolver |
| S1732 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:13 | VoeVideoHostResolver( this._client, { Set<String> embedHosts = const {'voe.sx'}, }) : _embedHosts = Set.unmodifiable(embedHosts), _http = PublicPlaybackHttp(_client, Set.of(embedHosts)) |
| S1733 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:37 | @override String get hostId |
| S1734 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:39 | @override String get resolverId |
| S1735 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:42 | @override bool supports(SourceCandidate candidate) |
| S1736 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:49 | @override Future<PlaybackProviderResult<PlayableSource>> resolve( PlaybackSource source, SourceCandidate candidate, { required PlaybackCancellationToken cancellation, }) |
| S1737 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:141 | static Uri? publishedRedirect(String page) |
| S1738 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:153 | static Uri? decodeSource(String page) |
| S1739 | símbolo | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:155 | /// Decodes the published player config once: the signed HLS source plus any /// soft subtitle tracks it genuinely declares. Captions are optional and are /// only accepted as public HTTPS `.vtt` files; an entry that fails validation /// is dropped rather than repaired or invented. static ({Uri source, List<ProviderSubtitle> captions})? decodePlayer( String page, ) |
| S1740 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:1 | /// HTML and JS-string parsing helpers shared by the scraped-site providers, /// ported from Anilili's `NativeProviderParsers.kt` (project Anilili, MIT-0). /// /// All helpers are pure string functions: no transport, no host access, and /// no JavaScript execution. Bounded input sizes are enforced by callers. abstract final class HtmlPlaybackParsers |
| S1741 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:7 | /// Attribute value of [name] inside a single [tag] string, quoted (possibly /// multiline) or unquoted, with entities decoded. Empty when absent. static String attr(String tag, String name) |
| S1742 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:26 | /// Visible text of an HTML fragment, tags stripped and entities decoded. static String stripTags(String html) |
| S1743 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:34 | /// Named and numeric entity decoding plus JS backslash-slash normalization. static String decodeEntities(String value) |
| S1744 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:58 | /// Anilili's normalization: lowercase and strip everything but `[a-z0-9]`. /// Used only to rank candidates; conservative selection stays elsewhere. static String normalize(String value) |
| S1745 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:63 | /// Bigram Dice similarity with containment bonus, as in Anilili's /// `titleScore`. Pure ranking aid — never used to approve a match alone. static double titleScore(String query, String candidate) |
| S1746 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:89 | /// Resolves [value] against [base]; absolute values pass through unchanged. static String absoluteUrl(String base, String value) |
| S1747 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:98 | /// Every HLS-looking URL in an HTML fragment, entities and JS slashes /// decoded, protocol-relative forms upgraded to https. static List<String> hlsUrls(String html) |
| S1748 | símbolo | app/lib/data/player/providers/html_playback_parsers.dart:114 | /// Decodes the escaped JSON that AniZone-style servers embed inside /// `wire:snapshot` attributes and `JSON.parse('...')` strings: /// `\u0022` (with one to three leading backslashes) becomes a quote, /// `\/` variants become plain slashes, and `\uXXXX` becomes its character. static String decodeJsonEscapes(String raw) |
| S1749 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:10 | /// JKAnime playback provider that extracts servers from episode page scripts. /// /// Reads the `var servers = |
| S1750 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:23 | JKAnimePlaybackProvider({this.httpClient}) |
| S1751 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:25 | httpClient |
| S1752 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:27 | semanticVersion = '1.0.0' |
| S1753 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:30 | id = PlaybackProviderId('jkanime') |
| S1754 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:32 | @override Set<PlaybackProviderCapability> get capabilities |
| S1755 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:37 | @override String get adapterVersion |
| S1756 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:41 | knownFileHosts = { 'ok.ru', 'streamwish', 'vidhide', 'filelions', 'filemoon', 'mp4upload', 'yourupload', 'streamtape', 'voe', 'doodstream', 'mixdrop', 'mega', } |
| S1757 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:57 | jkServerTypes = { 'jkplayer', 'um.php', 'jk.php', } |
| S1758 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:65 | suspectPatterns = { 'streamwish', 'voe', 'vidhide', } |
| S1759 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:72 | cloudflareBackoff = [5, 15, 30, 60] |
| S1760 | símbolo | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:245 | /// Parse the episode page and emit sources. @override Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode episode, { required PlaybackCancellationToken cancellation, }) |
| S1761 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:15 | enum MegaPlayAudioVariant |
| S1762 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:15 | sub |
| S1763 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:15 | dub |
| S1764 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:17 | /// Exact AniList/episode MegaPlay endpoint with a MyAnimeList fallback, /// adapted from Anilili (MIT-0): the `ani` route first, then the `mal` route /// that 2Dhive itself embeds. No title search, inferred episode index, /// cookies, or JavaScript execution. final class MegaPlayPlaybackProvider extends EpisodeSourceAdapter |
| S1765 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:22 | MegaPlayPlaybackProvider( Dio client, { Uri? origin, this.variant = MegaPlayAudioVariant.sub, PublicPlaybackHttp? transport, }) : origin = origin ?? defaultOrigin |
| S1766 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:36 | defaultOrigin = Uri.https('megaplay.buzz') |
| S1767 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:38 | origin |
| S1768 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:39 | variant |
| S1769 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:48 | @override PlaybackProviderId get id |
| S1770 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:53 | @override Set<PlaybackProviderCapability> get capabilities |
| S1771 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:154 | @override Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime( AnimeIdentity identity, { required PlaybackCancellationToken cancellation, }) |
| S1772 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:168 | @override Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes( SourceAnimeMatch match, { required PlaybackCancellationToken cancellation, }) |
| S1773 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:180 | @override Future<PlaybackProviderResult<EpisodeRef>> findEpisode( SourceAnimeMatch match, { required int episodeNumber, required PlaybackCancellationToken cancellation, }) |
| S1774 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:192 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode requested, { required PlaybackCancellationToken cancellation, }) |
| S1775 | símbolo | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:208 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources( EpisodeRef episode, { required PlaybackCancellationToken cancellation, }) |
| S1776 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:12 | miruroCatalogOrigins = <String>['www.miruro.cx'] |
| S1777 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:14 | /// Small HTTP adapter for the public Miruro REST catalog. /// /// This uses ordinary HTTPS GETs: the catalog route through [MiruroHttp2Client] /// because the backend serves it only over HTTP/2, and `/health` through /// [PublicPlaybackHttp], which is enough for the liveness probe. It does not send /// cookies, browser fingerprints, challenge answers, or authentication. final class MiruroCatalogApi |
| S1778 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:21 | MiruroCatalogApi(this._http, {MiruroCatalogTransport? transport}) : _http2 = transport ?? MiruroHttp2Client() |
| S1779 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:24 | maxDecodedBytes = 8 * 1024 * 1024 |
| S1780 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:45 | Future<String> get( String path, { Map<String, String> query = const <String, String>{}, required PlaybackCancellationToken cancellation, required PlaybackHttpStage stage, int maxResponseBytes = PublicPlaybackHttp.defaultMaxResponseBytes, }) |
| S1781 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:122 | /// Verifies the backend is alive with a hard 4 s bound. /// /// `/health` is served by the same host over HTTP/1.1, so it exercises the /// public liveness route without duplicating the HTTP/2 transport. It returns /// `false` instead of throwing so a caller can classify an outage without /// sharing its request cancellation. Future<bool> probeHealth({ required PlaybackCancellationToken cancellation, }) |
| S1782 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:154 | /// Releases the pooled HTTP/2 connection, when the transport owns one. Future<void> close() |
| S1783 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:160 | /// Decodes the upstream JSON or its documented XOR-then-gzip catalog body. /// Decompression is bounded to prevent a small response from expanding into /// an unbounded allocation on modest devices. static String decodePayload(Uint8List bytes) |
| S1784 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:8 | /// Typed view of the public Miruro catalog config used by Anilili. final class MiruroProviderConfig |
| S1785 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:10 | const MiruroProviderConfig({ required this.key, required this.label, required this.visible, this.parent, this.isEmbed = false, this.announcedLanguage = 'unknown', }) |
| S1786 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:19 | key |
| S1787 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:20 | label |
| S1788 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:21 | visible |
| S1789 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:22 | parent |
| S1790 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:23 | isEmbed |
| S1791 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:24 | announcedLanguage |
| S1792 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:27 | final class MiruroTitleRecord |
| S1793 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:28 | const MiruroTitleRecord({ required this.id, this.title, this.subCount, this.dubCount, }) |
| S1794 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:35 | id |
| S1795 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:36 | title |
| S1796 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:37 | subCount |
| S1797 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:38 | dubCount |
| S1798 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:41 | final class MiruroCatalogEpisode |
| S1799 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:42 | const MiruroCatalogEpisode({required this.number, this.title, this.kind}) |
| S1800 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:44 | number |
| S1801 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:45 | title |
| S1802 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:46 | kind |
| S1803 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:49 | /// Pure parser for the catalog protocol and its provider alternatives. /// /// It follows Anilili's separation between catalog decoding, provider identity, /// episode numbering and the streams returned by one `play` response. Direct /// media URLs are kept as host candidates; quality variants on the same server /// are collapsed to the highest declared rendition so they are not presented /// as separate servers. final class MiruroCatalogParser |
| S1804 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:57 | const MiruroCatalogParser() |
| S1805 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:59 | maxProviders = 64 |
| S1806 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:60 | maxEpisodes = 20000 |
| S1807 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:61 | maxServersPerSource = 32 |
| S1808 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:63 | List<MiruroProviderConfig> parseConfig(String body) |
| S1809 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:104 | MiruroTitleRecord? parseTitle(String body, {required int anilistId}) |
| S1810 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:141 | ({List<MiruroCatalogEpisode> episodes, String? nextCursor}) parseEpisodes( String body, ) |
| S1811 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:172 | List<PlaybackSource> parsePlaybackSources({ required String body, required List<MiruroProviderConfig> config, required EpisodeRef episode, }) |
| S1812 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:15 | /// AniList → Miruro title → episode → direct server candidates. /// /// It adapts Anilili's public REST catalog flow to Kongroo's existing /// `EpisodeSourceAdapter` and manager. It does not create a player or resolve /// iframe pages. Only direct, declared HTTPS media streams reach the generic /// `DirectMediaHostResolver`. final class MiruroCatalogPlaybackProvider extends EpisodeSourceAdapter |
| S1813 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:22 | MiruroCatalogPlaybackProvider( this._api, { this._parser = const MiruroCatalogParser(), DateTime Function()? clock, }) : _clock = clock ?? DateTime.now |
| S1814 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:28 | semanticVersion = '1.0.0' |
| S1815 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:51 | id = PlaybackProviderId('miruro-catalog') |
| S1816 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:53 | @override Set<PlaybackProviderCapability> get capabilities |
| S1817 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:59 | @override String get adapterVersion |
| S1818 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:62 | @override Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime( AnimeIdentity identity, { required PlaybackCancellationToken cancellation, }) |
| S1819 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:75 | /// The detail page already has its episode index from Kitsu. Resolve its /// selected number directly instead of downloading a provider-wide list on /// each playback click. [listEpisodes] remains available for catalog views. @override Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode requested, { required PlaybackCancellationToken cancellation, }) |
| S1820 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:113 | @override Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes( SourceAnimeMatch match, { required PlaybackCancellationToken cancellation, }) |
| S1821 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:130 | @override Future<PlaybackProviderResult<EpisodeRef>> findEpisode( SourceAnimeMatch match, { required int episodeNumber, required PlaybackCancellationToken cancellation, }) |
| S1822 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:155 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources( EpisodeRef episode, { required PlaybackCancellationToken cancellation, }) |
| S1823 | símbolo | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:402 | PlaybackSourceProvider createMiruroCatalogProvider( MiruroCatalogApi api, { DateTime Function()? clock, }) |
| S1824 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:8 | /// One bounded HTTP/2 response, already decoded from the framing layer. final class MiruroHttp2Response |
| S1825 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:10 | const MiruroHttp2Response({ required this.statusCode, required this.headers, required this.body, }) |
| S1826 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:16 | statusCode |
| S1827 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:17 | headers |
| S1828 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:18 | body |
| S1829 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:21 | /// The narrow slice of HTTP the catalog needs, so a test can substitute it. abstract interface class MiruroCatalogTransport |
| S1830 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:23 | Future<MiruroHttp2Response> get( Uri uri, { required Map<String, String> headers, required Duration timeout, required int maxBytes, }) |
| S1831 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:31 | /// Minimal HTTP/2 GET transport for the public Miruro backend. /// /// Why this exists: the backend's catalog route is only served over HTTP/2. /// The same host answers `/health` over HTTP/1.1, so this is not a network, /// address, or client block; it is a route rule that the site's own browser /// satisfies by negotiating `h2` through ALPN. Dart's `dart:io` HTTP client is /// HTTP/1.1 only, so the catalog is read through this narrow client instead. /// /// It sends exactly the request the site's own bundle sends: `GET`, no body, no /// cookies, no authorization, and the standard fetch-metadata context. Keep it /// that way: this class is not a general-purpose evasion layer. final class MiruroHttp2Client implements MiruroCatalogTransport |
| S1832 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:43 | MiruroHttp2Client({ this.connectTimeout = const Duration(seconds: 8), this.maxIdleLifetime = const Duration(seconds: 90), }) |
| S1833 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:49 | connectTimeout |
| S1834 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:52 | maxIdleLifetime |
| S1835 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:56 | /// Sends one `GET` to [uri] and returns the decoded response. @override Future<MiruroHttp2Response> get( Uri uri, { required Map<String, String> headers, required Duration timeout, required int maxBytes, }) |
| S1836 | símbolo | app/lib/data/player/providers/miruro/miruro_http2_client.dart:105 | Future<void> close() |
| S1837 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:9 | /// Loopback reverse proxy for Miruro media. /// /// Every resolved stream is published as `http://127.0.0.1:<port>/media/<id>`, /// so the player never holds a backend CDN URL. The proxy is the single place /// that applies the `Referer`/`Origin`/`User-Agent` the backend declares, /// forwards `Range`, and preserves `206` with `Content-Range`. That keeps seek /// correct, hides mirror and token rotation from the engine, and lets the source /// appear as an internal, labelled stream. /// /// Scope: public `GET` only, loopback only, no request body, no cookies, no /// authorization. Sub-resources are addressed by an opaque id plus the base64url /// of their absolute upstream URL, which is validated against the registered /// upstream host family before any request leaves the process. final class MiruroMediaProxy |
| S1838 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:33 | /// Binds an ephemeral loopback port and starts serving. static Future<MiruroMediaProxy> start() |
| S1839 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:45 | /// Origin the engine must allowlist, e.g. `http://127.0.0.1:45123`. String get origin |
| S1840 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:48 | /// Publishes [upstream] and returns the loopback URI to play. Uri expose(Uri upstream, {PlaybackRequestHeaders? headers}) |
| S1841 | símbolo | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:55 | /// Drops every published entry. Called when the provider is disposed. Future<void> close() |
| S1842 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:6 | enum MockPlaybackScenario |
| S1843 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:7 | valid |
| S1844 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:8 | alternatives |
| S1845 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:9 | unavailableSource |
| S1846 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:10 | timeout |
| S1847 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:11 | empty |
| S1848 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:12 | providerError |
| S1849 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:13 | forbidden |
| S1850 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:14 | malformed |
| S1851 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:15 | wrongEpisode |
| S1852 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:16 | malformedResolution |
| S1853 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:19 | /// Deterministic provider fixture. It performs no HTTP or filesystem access. final class MockPlaybackProvider implements PlaybackSourceProvider, PlaybackVideoHostResolver |
| S1854 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:22 | MockPlaybackProvider({ required this.id, this.scenario = MockPlaybackScenario.valid, this.requestGate, this.resolveGate, this.requestStarted, this.requestCompleted, Set<String> unavailableServerIds = const {}, Map<String, Uri> serverEndpoints = const {}, Set<PlaybackProviderCapability>? capabilities, }) : unavailableServerIds = Set.unmodifiable(unavailableServerIds), serverEndpoints = Map.unmodifiable(serverEndpoints), capabilitiesOverride = capabilities == null ? null : Set.unmodifiable(capabilities) |
| S1855 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:39 | id |
| S1856 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:40 | scenario |
| S1857 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:41 | requestGate |
| S1858 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:42 | resolveGate |
| S1859 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:43 | requestStarted |
| S1860 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:44 | requestCompleted |
| S1861 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:45 | unavailableServerIds |
| S1862 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:46 | serverEndpoints |
| S1863 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:47 | capabilitiesOverride |
| S1864 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:48 | findCalls = 0 |
| S1865 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:49 | resolveCalls = 0 |
| S1866 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:50 | attemptedServers = [] |
| S1867 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:52 | @override Set<PlaybackProviderCapability> get capabilities |
| S1868 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:60 | @override String get resolverId |
| S1869 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:63 | @override String get hostId |
| S1870 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:66 | @override bool supports(SourceCandidate server) |
| S1871 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:71 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode episode, { required PlaybackCancellationToken cancellation, }) |
| S1872 | símbolo | app/lib/data/player/providers/mock/mock_playback_provider.dart:142 | @override Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve( PlaybackSource source, SourceCandidate server, { required PlaybackCancellationToken cancellation, }) |
| S1873 | símbolo | app/lib/data/player/providers/playback_providers_module.dart:19 | /// Composition root for anime discovery and shared direct-media resolution. /// /// MegaPlay and Miruro provide automatic episode discovery. Wikimedia is an explicit /// regression provider for a known public-domain title; user-defined sources /// are optional. The module registers one generic direct-media resolver and /// never creates or owns the playback engine. final class PlaybackProvidersModule |
| S1874 | símbolo | app/lib/data/player/providers/playback_providers_module.dart:28 | factory PlaybackProvidersModule.open({ DateTime Function()? clock, bool enableMiruro = true, bool enableMegaPlay = true, bool enableAnimeAv1 = true, bool enableAllAnime = true, bool enableAniZone = true, bool enableAnimeGg = true, bool enableWikimedia = false, bool enableJkanime = true, Iterable<UserDefinedSourceEntry> userSources = const [], }) |
| S1875 | símbolo | app/lib/data/player/providers/playback_providers_module.dart:229 | manager |
| S1876 | símbolo | app/lib/data/player/providers/playback_providers_module.dart:233 | /// Idempotent lifecycle hook retained by the app composition root. void close() |
| S1877 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:8 | /// Shared mapping for public episode indexes identified by a unique exact title. abstract base class PublicEpisodeProvider extends EpisodeSourceAdapter |
| S1878 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:10 | @override Set<PlaybackProviderCapability> get capabilities |
| S1879 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:16 | Future<PlaybackProviderResult<T>> read<T>(Future<T?> Function() load) |
| S1880 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:30 | List<SourceAnimeMatch>? exactMatches( AnimeIdentity identity, Map<String, String> titlesBySlug, ) |
| S1881 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:50 | List<EpisodeRef> episodes(SourceAnimeMatch match, Iterable<int> numbers) |
| S1882 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:59 | String episodePath(String slug, int number) |
| S1883 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:61 | bool validSlug(String slug) |
| S1884 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:63 | bool allowsDirectMedia(Uri uri) |
| S1885 | símbolo | app/lib/data/player/providers/public_episode_provider.dart:65 | List<PlaybackSource>? sources( EpisodeRef episode, Iterable<(String, Uri)> alternatives, { PlaybackRequestHeaders mediaHeaders = const PlaybackRequestHeaders.empty(), }) |
| S1886 | símbolo | app/lib/data/player/providers/public_playback_http.dart:13 | /// Bounded ordinary GETs to exact provider or embed hosts. final class PublicPlaybackHttp |
| S1887 | símbolo | app/lib/data/player/providers/public_playback_http.dart:15 | defaultMaxResponseBytes = 2 * 1024 * 1024 |
| S1888 | símbolo | app/lib/data/player/providers/public_playback_http.dart:16 | maxAllowedResponseBytes = 8 * 1024 * 1024 |
| S1889 | símbolo | app/lib/data/player/providers/public_playback_http.dart:20 | maxErrorBodyBytes = 4096 |
| S1890 | símbolo | app/lib/data/player/providers/public_playback_http.dart:22 | PublicPlaybackHttp( this.client, this.allowedHosts, { this.userAgent = 'Kongroo/0.1 (public anime catalog client)', this.enforceCooldown = true, this.maxConcurrent, }) |
| S1891 | símbolo | app/lib/data/player/providers/public_playback_http.dart:30 | client |
| S1892 | símbolo | app/lib/data/player/providers/public_playback_http.dart:31 | allowedHosts |
| S1893 | símbolo | app/lib/data/player/providers/public_playback_http.dart:32 | userAgent |
| S1894 | símbolo | app/lib/data/player/providers/public_playback_http.dart:33 | enforceCooldown |
| S1895 | símbolo | app/lib/data/player/providers/public_playback_http.dart:34 | maxConcurrent |
| S1896 | símbolo | app/lib/data/player/providers/public_playback_http.dart:65 | Future<String> read( Uri uri, PlaybackCancellationToken cancellation, { PlaybackHttpStage stage = PlaybackHttpStage.catalog, int maxResponseBytes = defaultMaxResponseBytes, PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(), bool ajax = false, }) |
| S1897 | símbolo | app/lib/data/player/providers/public_playback_http.dart:83 | /// Posts one bounded JSON document through the same host allowlist, /// cancellation, timeout and retry policy as [read]. Used by public catalog /// APIs whose documented search endpoint requires a request body. Future<String> readJson( Uri uri, PlaybackCancellationToken cancellation, { required String jsonBody, PlaybackHttpStage stage = PlaybackHttpStage.catalog, int maxResponseBytes = defaultMaxResponseBytes, PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(), }) |
| S1898 | símbolo | app/lib/data/player/providers/public_playback_http.dart:109 | /// Reads a bounded binary response through the same host, cancellation, /// timeout and retry policy as [read]. Used for public APIs whose documented /// catalog payload is compressed or otherwise not UTF-8 text. Future<Uint8List> readBytes( Uri uri, PlaybackCancellationToken cancellation, { PlaybackHttpStage stage = PlaybackHttpStage.catalog, int maxResponseBytes = defaultMaxResponseBytes, PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(), }) |
| S1899 | símbolo | app/lib/data/player/providers/public_playback_http.dart:129 | /// Verifies the selected host's public response headers before offering it. /// Only one same-origin redirect to another admitted media URI is allowed. Future<Uri> checkMp4( Uri uri, PlaybackCancellationToken cancellation, { required bool Function(Uri) allows, required PlaybackRequestHeaders headers, }) |
| S1900 | símbolo | app/lib/data/player/providers/public_playback_http.dart:451 | final class PublicPlaybackFailure implements Exception |
| S1901 | símbolo | app/lib/data/player/providers/public_playback_http.dart:452 | const PublicPlaybackFailure( this.kind, { this.status, this.host, this.server, this.retryAfter, this.stage, this.contentType, }) |
| S1902 | símbolo | app/lib/data/player/providers/public_playback_http.dart:461 | kind |
| S1903 | símbolo | app/lib/data/player/providers/public_playback_http.dart:462 | status |
| S1904 | símbolo | app/lib/data/player/providers/public_playback_http.dart:463 | host |
| S1905 | símbolo | app/lib/data/player/providers/public_playback_http.dart:464 | server |
| S1906 | símbolo | app/lib/data/player/providers/public_playback_http.dart:465 | retryAfter |
| S1907 | símbolo | app/lib/data/player/providers/public_playback_http.dart:466 | stage |
| S1908 | símbolo | app/lib/data/player/providers/public_playback_http.dart:467 | contentType |
| S1909 | símbolo | app/lib/data/player/providers/public_playback_http.dart:469 | PlaybackProviderFailed<T> result<T>() |
| S1910 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:1 | /// Immutable specification for a playback provider. /// /// Defines what a provider is, how it is categorized, and under what /// conditions it appears in the "Fuentes encontradas" dialog. /// /// Instances are created once at module initialization and collected /// into a [ProviderRegistry] which is the single source of truth for /// what providers exist and which are visible. class ProviderSpec |
| S1911 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:10 | const ProviderSpec({ required this.key, required this.label, required this.kind, this.extractor, required this.priority, required this.enabledByDefault, this.flag, required this.license, }) |
| S1912 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:22 | key |
| S1913 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:24 | label |
| S1914 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:26 | kind |
| S1915 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:29 | extractor |
| S1916 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:31 | priority |
| S1917 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:34 | enabledByDefault |
| S1918 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:38 | flag |
| S1919 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:40 | license |
| S1920 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:43 | /// Kind of playback provider, determining how sources are resolved. enum ProviderKind |
| S1921 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:44 | file |
| S1922 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:44 | hls |
| S1923 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:44 | drm |
| S1924 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:44 | iframe |
| S1925 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:46 | /// Single source of truth for all playback providers visible in the UI. /// /// The [PlaybackProviderManager] and the "Fuentes encontradas" dialog both /// read from this registry. Adding or removing a [ProviderSpec] automatically /// changes what appears in the source list — no separate hardcoded list exists. final class ProviderRegistry |
| S1926 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:52 | const ProviderRegistry(this._specs) |
| S1927 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:58 | /// Returns only the specs that are enabled (considering [enabledByDefault] /// and [flag]). Iterable<ProviderSpec> get visible |
| S1928 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:68 | /// Look up a spec by its key, or `null` if not found. ProviderSpec? byKey(String k) |
| S1929 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:72 | /// Returns all visible specs sorted by priority descending, with stable /// ordering for equal priorities (insertion order preserved). List<ProviderSpec> get ordered |
| S1930 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:77 | /// Whether a given key is currently visible in the UI. bool isVisible(String key) |
| S1931 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:86 | extension ProviderSpecVisibility on ProviderSpec |
| S1932 | símbolo | app/lib/data/player/providers/registry/provider_spec.dart:87 | /// True when this spec should appear in the "Fuentes encontradas" dialog. bool get isVisible |
| S1933 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:8 | /// One episode video the user explicitly registered for playback. final class UserDefinedSourceEntry |
| S1934 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:10 | UserDefinedSourceEntry({ required this.anime, required this.episodeNumber, required this.url, this.language = 'unknown', this.quality, }) |
| S1935 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:28 | anime |
| S1936 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:29 | episodeNumber |
| S1937 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:30 | url |
| S1938 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:31 | language |
| S1939 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:32 | quality |
| S1940 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:34 | /// Parses `{"sources":[{"anime":..,"episode":..,"url":..}]}`. /// Throws [FormatException] on any malformed entry instead of skipping it. static List<UserDefinedSourceEntry> parseJson(String source) |
| S1941 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:73 | /// Serves only the episodes listed by the user. It never discovers anime, /// never scrapes pages, and leaves hosts to the shared direct-media resolver. final class UserDefinedPlaybackProvider implements PlaybackSourceProvider |
| S1942 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:76 | UserDefinedPlaybackProvider(Iterable<UserDefinedSourceEntry> entries) : _entries = List<UserDefinedSourceEntry>.unmodifiable(entries) |
| S1943 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:79 | providerId = PlaybackProviderId( 'user-defined', ) |
| S1944 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:82 | adapterVersion = '1.0.0' |
| S1945 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:86 | @override PlaybackProviderId get id |
| S1946 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:89 | @override Set<PlaybackProviderCapability> get capabilities |
| S1947 | símbolo | app/lib/data/player/providers/user_sources/user_defined_playback_provider.dart:96 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode episode, { required PlaybackCancellationToken cancellation, }) |
| S1948 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:14 | /// Reviewed full anime films on Commons. The catalog contains cross-references /// and file names. The official API supplies current media and transcodes. final class WikimediaAnimeProvider extends PublicEpisodeProvider |
| S1949 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:17 | WikimediaAnimeProvider(Dio client) : _http = PublicPlaybackHttp( client, const {'commons.wikimedia.org'}, userAgent: wikimediaUserAgent, enforceCooldown: true, maxConcurrent: 2, ) |
| S1950 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:36 | id = PlaybackProviderId('wikimedia-commons') |
| S1951 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:38 | @override bool allowsDirectMedia(Uri uri) |
| S1952 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:45 | @override String episodePath(String slug, int number) |
| S1953 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:48 | @override Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime( AnimeIdentity identity, { required PlaybackCancellationToken cancellation, }) |
| S1954 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:69 | @override Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes( SourceAnimeMatch match, { required PlaybackCancellationToken cancellation, }) |
| S1955 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:85 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources( EpisodeRef episode, { required PlaybackCancellationToken cancellation, }) |
| S1956 | símbolo | app/lib/data/player/providers/wikimedia/wikimedia_identity.dart:2 | wikimediaUserAgent = 'Kongroo/1.0.0 (https://github.com/kurogamishuen15/AnimeApp-Dev/issues)' |
| S1957 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:7 | /// `flutter_secure_storage` adapter for a single AniList access token. /// /// Errors deliberately omit plugin exception details because they may include /// keyring state or secret values. No fallback to non-secure storage exists. final class FlutterSecureCredentialStore implements SecureCredentialStore |
| S1958 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:12 | FlutterSecureCredentialStore({SecureStorageApi? storage}) : _storage = storage ?? FlutterSecureStorageApi() |
| S1959 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:19 | @override Future<Result<String?>> readAccessToken() |
| S1960 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:28 | @override Future<Result<void>> writeAccessToken(String accessToken) |
| S1961 | símbolo | app/lib/data/secure_storage/flutter_secure_credential_store.dart:41 | @override Future<Result<void>> deleteAccessToken() |
| S1962 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:5 | final class FlutterSecureStorageApi implements SecureStorageApi |
| S1963 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:6 | FlutterSecureStorageApi([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage() |
| S1964 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:11 | @override Future<String?> read({required String key}) |
| S1965 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:14 | @override Future<void> write({required String key, required String value}) |
| S1966 | símbolo | app/lib/data/secure_storage/flutter_secure_storage_api.dart:18 | @override Future<void> delete({required String key}) |
| S1967 | símbolo | app/lib/data/secure_storage/secure_storage_api.dart:1 | /// Small injectable surface over the platform secure-storage plugin. /// /// The interface keeps tests independent of a desktop keyring and allows /// failure behavior to be exercised without accessing user credentials. abstract interface class SecureStorageApi |
| S1968 | símbolo | app/lib/data/secure_storage/secure_storage_api.dart:6 | Future<String?> read({required String key}) |
| S1969 | símbolo | app/lib/data/secure_storage/secure_storage_api.dart:8 | Future<void> write({required String key, required String value}) |
| S1970 | símbolo | app/lib/data/secure_storage/secure_storage_api.dart:10 | Future<void> delete({required String key}) |
| S1971 | símbolo | app/lib/data/testing/fake_sync_remote.dart:8 | typedef SyncReply = Future<Result<SyncReceipt>> Function(SyncEnvelope request); |
| S1972 | símbolo | app/lib/data/testing/fake_sync_remote.dart:10 | /// Deterministic in-memory test double; it does not model server policy. final class FakeSyncRemote implements SyncRemote |
| S1973 | símbolo | app/lib/data/testing/fake_sync_remote.dart:12 | FakeSyncRemote({SyncReply? reply}) : _reply = reply ?? _acknowledge |
| S1974 | símbolo | app/lib/data/testing/fake_sync_remote.dart:15 | requests = [] |
| S1975 | símbolo | app/lib/data/testing/fake_sync_remote.dart:17 | @override Future<Result<SyncReceipt>> submit(SyncEnvelope envelope) |
| S1976 | símbolo | app/lib/domain/app_identity.dart:1 | /// Identidad básica de la aplicación, independiente de Flutter. abstract final class AppIdentity |
| S1977 | símbolo | app/lib/domain/app_identity.dart:3 | name = 'AnimeApp' |
| S1978 | símbolo | app/lib/domain/auth/secure_credential_store.dart:3 | /// Domain-facing access-token storage contract. /// /// Implementations must use an operating-system secure store and must never /// fall back to ordinary preferences, files, or the settings database. abstract interface class SecureCredentialStore |
| S1979 | símbolo | app/lib/domain/auth/secure_credential_store.dart:8 | Future<Result<String?>> readAccessToken() |
| S1980 | símbolo | app/lib/domain/auth/secure_credential_store.dart:10 | Future<Result<void>> writeAccessToken(String accessToken) |
| S1981 | símbolo | app/lib/domain/auth/secure_credential_store.dart:12 | Future<Result<void>> deleteAccessToken() |
| S1982 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:4 | enum AnimeBrowseSort |
| S1983 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:4 | popular |
| S1984 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:4 | trending |
| S1985 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:6 | /// Domain port for user-requested, read-only anime search. abstract interface class AnimeCatalogRepository |
| S1986 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:8 | Future<Result<AnimeSearchResult>> searchAnimeById(int id) |
| S1987 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:10 | Future<Result<AnimeSearchResult>> searchAnime( String search, { int page = 1, int perPage = 20, }) |
| S1988 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:16 | /// Returns a public catalogue page without requiring a search phrase. Future<Result<AnimeSearchResult>> browseAnime({ AnimeBrowseSort sort = AnimeBrowseSort.popular, int page = 1, int perPage = 20, }) |
| S1989 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:24 | /// Local snapshots are optional for repositories backed by a persistent cache. abstract interface class CachedAnimeCatalog |
| S1990 | símbolo | app/lib/domain/catalog/anime_catalog_repository.dart:26 | Future<AnimeSummary?> readCachedAnime(int id) |
| S1991 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:3 | typedef AnimeVoiceActor = ( |
| S1992 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:4 | typedef AnimeCharacter = ( |
| S1993 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:11 | typedef RelatedAnime = ( |
| S1994 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:12 | typedef AnimeTrailer = ( |
| S1995 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:14 | /// Public episode metadata exposed by the catalogue provider. /// /// This does not represent a playable source. The number and optional title, /// thumbnail, site, and legal external watch page are catalogue data only. final class AnimeEpisodeMetadata |
| S1996 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:19 | AnimeEpisodeMetadata({ required this.number, required this.title, this.thumbnailUrl, this.site, this.externalWatchUri, }) |
| S1997 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:44 | number |
| S1998 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:45 | title |
| S1999 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:46 | thumbnailUrl |
| S2000 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:47 | site |
| S2001 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:50 | externalWatchUri |
| S2002 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:53 | /// Optional public fields fetched for a specific title, not for browse pages. final class AnimeDetailMetadata |
| S2003 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:55 | const AnimeDetailMetadata({ this.externalIds = const [], this.studios = const [], this.trailer, this.characters = const [], this.relations = const [], this.episodes = const [], this.episodeMetadataFetched = false, this.episodeCount, }) |
| S2004 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:67 | externalIds |
| S2005 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:68 | studios |
| S2006 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:69 | trailer |
| S2007 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:70 | characters |
| S2008 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:71 | relations |
| S2009 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:72 | episodes |
| S2010 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:73 | episodeMetadataFetched |
| S2011 | símbolo | app/lib/domain/catalog/anime_detail_metadata.dart:74 | episodeCount |
| S2012 | símbolo | app/lib/domain/catalog/anime_id.dart:1 | /// Stable AnimeApp identity, independent from any metadata provider. /// /// IDs are opaque ASCII values. Creation belongs to an injected ID generator; /// titles and provider IDs must never be used as the local primary key. final class AnimeId |
| S2013 | símbolo | app/lib/domain/catalog/anime_id.dart:6 | factory AnimeId(String value) |
| S2014 | símbolo | app/lib/domain/catalog/anime_id.dart:16 | value |
| S2015 | símbolo | app/lib/domain/catalog/anime_id.dart:18 | @override bool operator ==(Object other) |
| S2016 | símbolo | app/lib/domain/catalog/anime_id.dart:21 | @override int get hashCode |
| S2017 | símbolo | app/lib/domain/catalog/anime_id.dart:24 | @override String toString() |
| S2018 | símbolo | app/lib/domain/catalog/anime_id.dart:28 | /// Supplies opaque IDs at the persistence boundary. abstract interface class AnimeIdGenerator |
| S2019 | símbolo | app/lib/domain/catalog/anime_id.dart:30 | AnimeId generate() |
| S2020 | símbolo | app/lib/domain/catalog/anime_identity.dart:4 | enum IdentityLinkEvidence |
| S2021 | símbolo | app/lib/domain/catalog/anime_identity.dart:5 | trustedProviderCrossReference |
| S2022 | símbolo | app/lib/domain/catalog/anime_identity.dart:6 | verifiedOfficialReference |
| S2023 | símbolo | app/lib/domain/catalog/anime_identity.dart:7 | userConfirmed |
| S2024 | símbolo | app/lib/domain/catalog/anime_identity.dart:10 | enum AnimeRelationshipKind |
| S2025 | símbolo | app/lib/domain/catalog/anime_identity.dart:11 | season |
| S2026 | símbolo | app/lib/domain/catalog/anime_identity.dart:12 | sequel |
| S2027 | símbolo | app/lib/domain/catalog/anime_identity.dart:13 | prequel |
| S2028 | símbolo | app/lib/domain/catalog/anime_identity.dart:14 | movie |
| S2029 | símbolo | app/lib/domain/catalog/anime_identity.dart:15 | special |
| S2030 | símbolo | app/lib/domain/catalog/anime_identity.dart:16 | ova |
| S2031 | símbolo | app/lib/domain/catalog/anime_identity.dart:17 | alternateVersion |
| S2032 | símbolo | app/lib/domain/catalog/anime_identity.dart:20 | final class ExternalAnimeReference |
| S2033 | símbolo | app/lib/domain/catalog/anime_identity.dart:21 | ExternalAnimeReference({ required this.externalId, required this.evidence, required DateTime linkedAtUtc, }) : linkedAtUtc = _requireUtc(linkedAtUtc, 'linkedAtUtc') |
| S2034 | símbolo | app/lib/domain/catalog/anime_identity.dart:27 | externalId |
| S2035 | símbolo | app/lib/domain/catalog/anime_identity.dart:28 | evidence |
| S2036 | símbolo | app/lib/domain/catalog/anime_identity.dart:29 | linkedAtUtc |
| S2037 | símbolo | app/lib/domain/catalog/anime_identity.dart:32 | final class AnimeRelationship |
| S2038 | símbolo | app/lib/domain/catalog/anime_identity.dart:33 | AnimeRelationship({ required this.targetId, required this.kind, required this.evidence, required DateTime linkedAtUtc, }) : linkedAtUtc = _requireUtc(linkedAtUtc, 'linkedAtUtc') |
| S2039 | símbolo | app/lib/domain/catalog/anime_identity.dart:40 | targetId |
| S2040 | símbolo | app/lib/domain/catalog/anime_identity.dart:41 | kind |
| S2041 | símbolo | app/lib/domain/catalog/anime_identity.dart:42 | evidence |
| S2042 | símbolo | app/lib/domain/catalog/anime_identity.dart:43 | linkedAtUtc |
| S2043 | símbolo | app/lib/domain/catalog/anime_identity.dart:46 | /// The local identity and its explicitly verified provider cross-references. /// Metadata and user-owned library/progress values remain separate records. final class AnimeIdentity |
| S2044 | símbolo | app/lib/domain/catalog/anime_identity.dart:49 | AnimeIdentity({ required this.id, required DateTime createdAtUtc, Iterable<ExternalAnimeReference> externalReferences = const [], Iterable<AnimeRelationship> relationships = const [], }) : createdAtUtc = _requireUtc(createdAtUtc, 'createdAtUtc'), externalReferences = List.unmodifiable(externalReferences), relationships = List.unmodifiable(relationships) |
| S2045 | símbolo | app/lib/domain/catalog/anime_identity.dart:70 | id |
| S2046 | símbolo | app/lib/domain/catalog/anime_identity.dart:71 | createdAtUtc |
| S2047 | símbolo | app/lib/domain/catalog/anime_identity.dart:72 | externalReferences |
| S2048 | símbolo | app/lib/domain/catalog/anime_identity.dart:73 | relationships |
| S2049 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:7 | abstract interface class AnimeIdentityRepository |
| S2050 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:8 | Future<Result<AnimeIdentity?>> getById(AnimeId id) |
| S2051 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:10 | Future<Result<AnimeIdentity?>> findByExternalId(ExternalAnimeId id) |
| S2052 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:12 | /// Returns the existing exact mapping or atomically creates a local identity /// and records this explicit association. Future<Result<AnimeIdentity>> getOrCreateForExternalId( ExternalAnimeId id, { required IdentityLinkEvidence evidence, }) |
| S2053 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:19 | Future<Result<AnimeIdentity>> createLocalIdentity() |
| S2054 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:21 | /// Adds an explicit cross-reference; it never reassigns an existing mapping. Future<Result<AnimeIdentity>> linkExternalId({ required AnimeId animeId, required ExternalAnimeId externalId, required IdentityLinkEvidence evidence, }) |
| S2055 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:28 | Future<Result<AnimeIdentity>> addRelationship({ required AnimeId sourceId, required AnimeId targetId, required AnimeRelationshipKind kind, required IdentityLinkEvidence evidence, }) |
| S2056 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:36 | sealed class AnimeIdentityResolution |
| S2057 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:37 | const AnimeIdentityResolution() |
| S2058 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:40 | final class IdentityResolved extends AnimeIdentityResolution |
| S2059 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:41 | const IdentityResolved(this.animeId) |
| S2060 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:43 | animeId |
| S2061 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:46 | final class IdentityUnresolved extends AnimeIdentityResolution |
| S2062 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:47 | const IdentityUnresolved() |
| S2063 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:50 | final class IdentityAmbiguous extends AnimeIdentityResolution |
| S2064 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:51 | const IdentityAmbiguous(this.candidates) |
| S2065 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:53 | candidates |
| S2066 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:56 | /// Conservative resolver: only exact, namespaced IDs supplied as verified /// references may resolve automatically. Similar titles remain unresolved. final class AnimeIdentityResolver |
| S2067 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:59 | const AnimeIdentityResolver() |
| S2068 | símbolo | app/lib/domain/catalog/anime_identity_repository.dart:61 | AnimeIdentityResolution resolve({ required Iterable<VerifiedExternalAnimeReference> references, required Map<ExternalAnimeId, AnimeId> knownMappings, }) |
| S2069 | símbolo | app/lib/domain/catalog/anime_summary.dart:5 | /// Domain model for a small, public catalogue search result. class AnimeSummary |
| S2070 | símbolo | app/lib/domain/catalog/anime_summary.dart:7 | const AnimeSummary({ required this.id, this.romajiTitle, this.englishTitle, this.nativeTitle, this.coverImageUrl, this.bannerImageUrl, this.description, this.genres = const [], this.status, this.format, this.season, this.seasonYear, this.startDate, this.endDate, this.score, this.popularity, this.detail, }) |
| S2071 | símbolo | app/lib/domain/catalog/anime_summary.dart:27 | id |
| S2072 | símbolo | app/lib/domain/catalog/anime_summary.dart:28 | romajiTitle |
| S2073 | símbolo | app/lib/domain/catalog/anime_summary.dart:29 | englishTitle |
| S2074 | símbolo | app/lib/domain/catalog/anime_summary.dart:30 | nativeTitle |
| S2075 | símbolo | app/lib/domain/catalog/anime_summary.dart:31 | coverImageUrl |
| S2076 | símbolo | app/lib/domain/catalog/anime_summary.dart:32 | bannerImageUrl |
| S2077 | símbolo | app/lib/domain/catalog/anime_summary.dart:33 | description |
| S2078 | símbolo | app/lib/domain/catalog/anime_summary.dart:34 | genres |
| S2079 | símbolo | app/lib/domain/catalog/anime_summary.dart:35 | status |
| S2080 | símbolo | app/lib/domain/catalog/anime_summary.dart:36 | format |
| S2081 | símbolo | app/lib/domain/catalog/anime_summary.dart:37 | season |
| S2082 | símbolo | app/lib/domain/catalog/anime_summary.dart:38 | seasonYear |
| S2083 | símbolo | app/lib/domain/catalog/anime_summary.dart:39 | startDate |
| S2084 | símbolo | app/lib/domain/catalog/anime_summary.dart:40 | endDate |
| S2085 | símbolo | app/lib/domain/catalog/anime_summary.dart:41 | score |
| S2086 | símbolo | app/lib/domain/catalog/anime_summary.dart:42 | popularity |
| S2087 | símbolo | app/lib/domain/catalog/anime_summary.dart:43 | detail |
| S2088 | símbolo | app/lib/domain/catalog/anime_summary.dart:46 | /// AniList dates may contain a year, month, and/or day. class AnimeReleaseDate |
| S2089 | símbolo | app/lib/domain/catalog/anime_summary.dart:48 | const AnimeReleaseDate({this.year, this.month, this.day}) |
| S2090 | símbolo | app/lib/domain/catalog/anime_summary.dart:50 | year |
| S2091 | símbolo | app/lib/domain/catalog/anime_summary.dart:51 | month |
| S2092 | símbolo | app/lib/domain/catalog/anime_summary.dart:52 | day |
| S2093 | símbolo | app/lib/domain/catalog/anime_summary.dart:55 | enum AnimeSearchSource |
| S2094 | símbolo | app/lib/domain/catalog/anime_summary.dart:55 | anilist |
| S2095 | símbolo | app/lib/domain/catalog/anime_summary.dart:55 | localCache |
| S2096 | símbolo | app/lib/domain/catalog/anime_summary.dart:57 | /// Search data plus its source, so an offline fallback is visible to callers. class AnimeSearchResult |
| S2097 | símbolo | app/lib/domain/catalog/anime_summary.dart:59 | const AnimeSearchResult({ required this.items, required this.source, this.refreshError, }) |
| S2098 | símbolo | app/lib/domain/catalog/anime_summary.dart:65 | items |
| S2099 | símbolo | app/lib/domain/catalog/anime_summary.dart:66 | source |
| S2100 | símbolo | app/lib/domain/catalog/anime_summary.dart:67 | refreshError |
| S2101 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:5 | /// One page of the episode index for a title. /// /// The index answers "which episodes exist" only. It never returns playable /// URLs, so a listed episode is not a source and must not be shown as playable. final class EpisodeIndexPage |
| S2102 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:10 | EpisodeIndexPage({ required Iterable<ProviderEpisodeMetadata> episodes, required this.totalCount, required this.hasMore, this.nextOffset, }) : episodes = List.unmodifiable(episodes) |
| S2103 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:21 | episodes |
| S2104 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:22 | totalCount |
| S2105 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:23 | hasMore |
| S2106 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:24 | nextOffset |
| S2107 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:27 | /// Port for public episode indexes (for example Kitsu) that are reached /// without an AniList account. Source providers and host resolvers stay apart. abstract interface class EpisodeIndexProvider |
| S2108 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:30 | MetadataProviderId get id |
| S2109 | símbolo | app/lib/domain/catalog/episode_index_provider.dart:32 | Future<ProviderResult<EpisodeIndexPage>> listEpisodes( ExternalAnimeId anime, { int offset = 0, int limit = 20, }) |
| S2110 | símbolo | app/lib/domain/catalog/external_anime_id.dart:1 | /// Namespace for an independently operated metadata provider. final class MetadataProviderId |
| S2111 | símbolo | app/lib/domain/catalog/external_anime_id.dart:3 | factory MetadataProviderId(String value) |
| S2112 | símbolo | app/lib/domain/catalog/external_anime_id.dart:17 | value |
| S2113 | símbolo | app/lib/domain/catalog/external_anime_id.dart:19 | @override bool operator ==(Object other) |
| S2114 | símbolo | app/lib/domain/catalog/external_anime_id.dart:23 | @override int get hashCode |
| S2115 | símbolo | app/lib/domain/catalog/external_anime_id.dart:26 | @override String toString() |
| S2116 | símbolo | app/lib/domain/catalog/external_anime_id.dart:30 | /// Provider-scoped identifier. The provider may define case sensitivity; /// AnimeApp trims but otherwise preserves the provider's external value. final class ExternalAnimeId |
| S2117 | símbolo | app/lib/domain/catalog/external_anime_id.dart:33 | factory ExternalAnimeId({ required MetadataProviderId providerId, required String value, }) |
| S2118 | símbolo | app/lib/domain/catalog/external_anime_id.dart:46 | providerId |
| S2119 | símbolo | app/lib/domain/catalog/external_anime_id.dart:47 | value |
| S2120 | símbolo | app/lib/domain/catalog/external_anime_id.dart:49 | /// Length-prefix encoding is unambiguous even if either value contains `:`. String get canonicalKey |
| S2121 | símbolo | app/lib/domain/catalog/external_anime_id.dart:53 | @override bool operator ==(Object other) |
| S2122 | símbolo | app/lib/domain/catalog/external_anime_id.dart:59 | @override int get hashCode |
| S2123 | símbolo | app/lib/domain/catalog/external_anime_id.dart:62 | @override String toString() |
| S2124 | símbolo | app/lib/domain/catalog/library_entry.dart:3 | /// User-selected local library states; no automatic transition is implied. enum LibraryStatus |
| S2125 | símbolo | app/lib/domain/catalog/library_entry.dart:5 | planned |
| S2126 | símbolo | app/lib/domain/catalog/library_entry.dart:6 | watching |
| S2127 | símbolo | app/lib/domain/catalog/library_entry.dart:7 | rewatching |
| S2128 | símbolo | app/lib/domain/catalog/library_entry.dart:8 | paused |
| S2129 | símbolo | app/lib/domain/catalog/library_entry.dart:9 | completed |
| S2130 | símbolo | app/lib/domain/catalog/library_entry.dart:10 | abandoned |
| S2131 | símbolo | app/lib/domain/catalog/library_entry.dart:13 | /// User-owned local membership. It contains no provider-owned metadata and is /// retained when accounts/providers are disconnected or unavailable. final class LibraryEntry |
| S2132 | símbolo | app/lib/domain/catalog/library_entry.dart:16 | LibraryEntry({ required this.animeId, required DateTime addedAtUtc, this.status = LibraryStatus.planned, }) : addedAtUtc = _requireUtc(addedAtUtc) |
| S2133 | símbolo | app/lib/domain/catalog/library_entry.dart:22 | animeId |
| S2134 | símbolo | app/lib/domain/catalog/library_entry.dart:23 | addedAtUtc |
| S2135 | símbolo | app/lib/domain/catalog/library_entry.dart:24 | status |
| S2136 | símbolo | app/lib/domain/catalog/library_repository.dart:5 | abstract interface class LocalLibraryRepository |
| S2137 | símbolo | app/lib/domain/catalog/library_repository.dart:6 | Future<Result<List<LibraryEntry>>> list() |
| S2138 | símbolo | app/lib/domain/catalog/library_repository.dart:8 | Future<Result<LibraryEntry?>> get(AnimeId animeId) |
| S2139 | símbolo | app/lib/domain/catalog/library_repository.dart:10 | Future<Result<LibraryEntry>> add(AnimeId animeId) |
| S2140 | símbolo | app/lib/domain/catalog/library_repository.dart:12 | Future<Result<LibraryEntry>> setStatus(AnimeId animeId, LibraryStatus status) |
| S2141 | símbolo | app/lib/domain/catalog/library_repository.dart:14 | /// Removes membership only; identity and playback progress are preserved. Future<Result<void>> remove(AnimeId animeId) |
| S2142 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:3 | /// Provenance for one provider response. Merged fields must retain their own /// provenance; this response-level value is not permission to republish data. final class MetadataProvenance |
| S2143 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:6 | MetadataProvenance({ required this.externalId, required DateTime retrievedAtUtc, DateTime? providerUpdatedAtUtc, }) : retrievedAtUtc = _requireUtc(retrievedAtUtc, 'retrievedAtUtc'), providerUpdatedAtUtc = providerUpdatedAtUtc == null ? null : _requireUtc(providerUpdatedAtUtc, 'providerUpdatedAtUtc') |
| S2144 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:15 | externalId |
| S2145 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:16 | retrievedAtUtc |
| S2146 | símbolo | app/lib/domain/catalog/metadata_provenance.dart:17 | providerUpdatedAtUtc |
| S2147 | símbolo | app/lib/domain/catalog/metadata_provider.dart:6 | enum MetadataCapability |
| S2148 | símbolo | app/lib/domain/catalog/metadata_provider.dart:6 | publicSearch |
| S2149 | símbolo | app/lib/domain/catalog/metadata_provider.dart:6 | animeDetails |
| S2150 | símbolo | app/lib/domain/catalog/metadata_provider.dart:6 | episodeMetadata |
| S2151 | símbolo | app/lib/domain/catalog/metadata_provider.dart:8 | /// Read-only metadata source. Account synchronization is a separate port. abstract interface class MetadataProvider |
| S2152 | símbolo | app/lib/domain/catalog/metadata_provider.dart:10 | MetadataProviderId get id |
| S2153 | símbolo | app/lib/domain/catalog/metadata_provider.dart:12 | Set<MetadataCapability> get capabilities |
| S2154 | símbolo | app/lib/domain/catalog/metadata_provider.dart:14 | Future<ProviderResult<List<ProviderAnimeMetadata>>> searchAnime( String query, { int limit = 20, }) |
| S2155 | símbolo | app/lib/domain/catalog/metadata_provider.dart:19 | Future<ProviderResult<ProviderAnimeMetadata>> getAnimeByExternalId( ExternalAnimeId id, ) |
| S2156 | símbolo | app/lib/domain/catalog/metadata_provider.dart:23 | Future<ProviderResult<List<ProviderEpisodeMetadata>>> getEpisodes( ExternalAnimeId animeId, ) |
| S2157 | símbolo | app/lib/domain/catalog/metadata_provider.dart:27 | Future<ProviderResult<ProviderHealth>> checkHealth() |
| S2158 | símbolo | app/lib/domain/catalog/metadata_provider.dart:30 | final class MetadataProviderConfiguration |
| S2159 | símbolo | app/lib/domain/catalog/metadata_provider.dart:31 | const MetadataProviderConfiguration({ required this.providerId, this.enabled = false, this.priority = 100, }) |
| S2160 | símbolo | app/lib/domain/catalog/metadata_provider.dart:37 | providerId |
| S2161 | símbolo | app/lib/domain/catalog/metadata_provider.dart:38 | enabled |
| S2162 | símbolo | app/lib/domain/catalog/metadata_provider.dart:39 | priority |
| S2163 | símbolo | app/lib/domain/catalog/metadata_provider.dart:42 | /// Explicit allowlist. A registered adapter is disabled unless enabled by /// configuration; no provider is queried merely because it is installed. final class MetadataProviderRegistry |
| S2164 | símbolo | app/lib/domain/catalog/metadata_provider.dart:45 | MetadataProviderRegistry({ required Iterable<MetadataProvider> providers, Iterable<MetadataProviderConfiguration> configurations = const [], }) : _providers = List.unmodifiable(providers), _configurations = List.unmodifiable(configurations) |
| S2165 | símbolo | app/lib/domain/catalog/metadata_provider.dart:78 | List<MetadataProvider> enabledFor(MetadataCapability capability) |
| S2166 | símbolo | app/lib/domain/catalog/metadata_provider.dart:98 | /// Evidence-bearing cross-reference received from a provider or verified by /// the owner. Titles alone are never sufficient evidence for identity merges. final class VerifiedExternalAnimeReference |
| S2167 | símbolo | app/lib/domain/catalog/metadata_provider.dart:101 | const VerifiedExternalAnimeReference({ required this.externalId, required this.evidence, }) |
| S2168 | símbolo | app/lib/domain/catalog/metadata_provider.dart:106 | externalId |
| S2169 | símbolo | app/lib/domain/catalog/metadata_provider.dart:107 | evidence |
| S2170 | símbolo | app/lib/domain/catalog/metadata_provider.dart:110 | /// Optional public browse capability, independent of account authentication. abstract interface class PublicAnimeBrowseProvider |
| S2171 | símbolo | app/lib/domain/catalog/metadata_provider.dart:112 | Future<ProviderResult<List<ProviderAnimeMetadata>>> browsePopular({ int limit = 20, }) |
| S2172 | símbolo | app/lib/domain/catalog/metadata_provider.dart:115 | Future<ProviderResult<List<ProviderAnimeMetadata>>> browseTrending({ int limit = 20, }) |
| S2173 | símbolo | app/lib/domain/catalog/metadata_provider.dart:120 | abstract interface class CachedAnimeMetadataProvider |
| S2174 | símbolo | app/lib/domain/catalog/metadata_provider.dart:121 | Future<ProviderAnimeMetadata?> readCachedAnime(ExternalAnimeId id) |
| S2175 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | enum AnimeFormat |
| S2176 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | tv |
| S2177 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | movie |
| S2178 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | ova |
| S2179 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | ona |
| S2180 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | special |
| S2181 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | manga |
| S2182 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:5 | unknown |
| S2183 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:7 | enum AnimeAiringStatus |
| S2184 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:8 | finished |
| S2185 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:9 | releasing |
| S2186 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:10 | notYetReleased |
| S2187 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:11 | cancelled |
| S2188 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:12 | unknown |
| S2189 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:15 | /// Normalized adapter output; provider JSON/DTOs must stop at the adapter. /// Optional image references stay as HTTPS URLs. Image bytes and retention /// policy remain outside this domain model. final class ProviderAnimeMetadata |
| S2190 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:19 | ProviderAnimeMetadata({ required this.externalId, required this.preferredTitle, required this.provenance, this.romajiTitle, Iterable<String> alternativeTitles = const [], this.format = AnimeFormat.unknown, this.season, this.seasonYear, this.releaseYear, this.endYear, this.episodeCount, this.synopsis, this.coverImageUrl, this.bannerImageUrl, Iterable<String> genres = const [], this.airingStatus = AnimeAiringStatus.unknown, this.averageScore, this.popularity, this.detail, }) : genres = List.unmodifiable(genres), alternativeTitles = List.unmodifiable( alternativeTitles .map((String title) => title.trim()) .where((String title) => title.isNotEmpty), ) |
| S2191 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:61 | externalId |
| S2192 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:62 | preferredTitle |
| S2193 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:63 | romajiTitle |
| S2194 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:64 | alternativeTitles |
| S2195 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:65 | format |
| S2196 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:66 | season |
| S2197 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:67 | seasonYear |
| S2198 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:68 | releaseYear |
| S2199 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:69 | endYear |
| S2200 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:70 | episodeCount |
| S2201 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:71 | synopsis |
| S2202 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:72 | coverImageUrl |
| S2203 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:73 | bannerImageUrl |
| S2204 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:74 | genres |
| S2205 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:75 | airingStatus |
| S2206 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:76 | averageScore |
| S2207 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:77 | popularity |
| S2208 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:78 | detail |
| S2209 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:79 | provenance |
| S2210 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:87 | /// Episode numbering is provider-scoped and must not be treated as a /// cross-provider episode identity. final class ProviderEpisodeMetadata |
| S2211 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:90 | ProviderEpisodeMetadata({ required this.animeId, required this.externalEpisodeId, required this.episodeNumber, required this.provenance, this.seasonNumber, this.title, this.thumbnailUrl, this.site, }) |
| S2212 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:116 | animeId |
| S2213 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:117 | externalEpisodeId |
| S2214 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:118 | episodeNumber |
| S2215 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:119 | seasonNumber |
| S2216 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:120 | title |
| S2217 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:121 | thumbnailUrl |
| S2218 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:122 | site |
| S2219 | símbolo | app/lib/domain/catalog/provider_anime_metadata.dart:123 | provenance |
| S2220 | símbolo | app/lib/domain/catalog/provider_result.dart:1 | enum ProviderFailureKind |
| S2221 | símbolo | app/lib/domain/catalog/provider_result.dart:2 | network |
| S2222 | símbolo | app/lib/domain/catalog/provider_result.dart:3 | timeout |
| S2223 | símbolo | app/lib/domain/catalog/provider_result.dart:4 | rateLimited |
| S2224 | símbolo | app/lib/domain/catalog/provider_result.dart:5 | credentialsMissing |
| S2225 | símbolo | app/lib/domain/catalog/provider_result.dart:6 | authentication |
| S2226 | símbolo | app/lib/domain/catalog/provider_result.dart:7 | invalidResponse |
| S2227 | símbolo | app/lib/domain/catalog/provider_result.dart:8 | unavailable |
| S2228 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | enum ProviderHealth |
| S2229 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | healthy |
| S2230 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | degraded |
| S2231 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | offline |
| S2232 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | disabled |
| S2233 | símbolo | app/lib/domain/catalog/provider_result.dart:11 | unknown |
| S2234 | símbolo | app/lib/domain/catalog/provider_result.dart:13 | /// Typed provider outcome. Adapter exceptions and response bodies must not /// cross this boundary. sealed class ProviderResult<T> |
| S2235 | símbolo | app/lib/domain/catalog/provider_result.dart:16 | const ProviderResult() |
| S2236 | símbolo | app/lib/domain/catalog/provider_result.dart:19 | final class ProviderSuccess<T> extends ProviderResult<T> |
| S2237 | símbolo | app/lib/domain/catalog/provider_result.dart:20 | const ProviderSuccess(this.value) |
| S2238 | símbolo | app/lib/domain/catalog/provider_result.dart:22 | value |
| S2239 | símbolo | app/lib/domain/catalog/provider_result.dart:25 | final class ProviderNoResults<T> extends ProviderResult<T> |
| S2240 | símbolo | app/lib/domain/catalog/provider_result.dart:26 | const ProviderNoResults() |
| S2241 | símbolo | app/lib/domain/catalog/provider_result.dart:29 | final class ProviderUnsupported<T> extends ProviderResult<T> |
| S2242 | símbolo | app/lib/domain/catalog/provider_result.dart:30 | const ProviderUnsupported(this.capability) |
| S2243 | símbolo | app/lib/domain/catalog/provider_result.dart:32 | capability |
| S2244 | símbolo | app/lib/domain/catalog/provider_result.dart:35 | final class ProviderFailure<T> extends ProviderResult<T> |
| S2245 | símbolo | app/lib/domain/catalog/provider_result.dart:36 | const ProviderFailure(this.kind, {this.retryAfter}) |
| S2246 | símbolo | app/lib/domain/catalog/provider_result.dart:38 | kind |
| S2247 | símbolo | app/lib/domain/catalog/provider_result.dart:39 | retryAfter |
| S2248 | símbolo | app/lib/domain/catalog/provider_result.dart:41 | bool get isRetryable |
| S2249 | símbolo | app/lib/domain/player/audio_track_info.dart:1 | /// Audio metadata is scoped to the current source generation. final class AudioTrackInfo |
| S2250 | símbolo | app/lib/domain/player/audio_track_info.dart:3 | const AudioTrackInfo({ required this.id, this.title, this.language, this.codec, this.channels, this.sampleRate, this.bitrate, this.isDefault, }) |
| S2251 | símbolo | app/lib/domain/player/audio_track_info.dart:14 | id |
| S2252 | símbolo | app/lib/domain/player/audio_track_info.dart:15 | title |
| S2253 | símbolo | app/lib/domain/player/audio_track_info.dart:16 | language |
| S2254 | símbolo | app/lib/domain/player/audio_track_info.dart:17 | codec |
| S2255 | símbolo | app/lib/domain/player/audio_track_info.dart:18 | channels |
| S2256 | símbolo | app/lib/domain/player/audio_track_info.dart:19 | sampleRate |
| S2257 | símbolo | app/lib/domain/player/audio_track_info.dart:20 | bitrate |
| S2258 | símbolo | app/lib/domain/player/audio_track_info.dart:21 | isDefault |
| S2259 | símbolo | app/lib/domain/player/audio_track_info.dart:23 | String get label |
| S2260 | símbolo | app/lib/domain/player/audio_track_info.dart:34 | String playbackLanguageLabel(String? language) |
| S2261 | símbolo | app/lib/domain/player/providers/anime_identity.dart:4 | /// Stable local identity plus optional provider crosswalks and display aliases. /// It is safe to construct without a signed-in AniList account. final class AnimeIdentity |
| S2262 | símbolo | app/lib/domain/player/providers/anime_identity.dart:7 | AnimeIdentity({ required this.localId, Iterable<ExternalAnimeId> externalIds = const [], Iterable<String> titles = const [], }) : externalIds = List.unmodifiable(externalIds.toSet()), titles = List.unmodifiable( titles .map((String title) => title.trim()) .where((String title) => title.isNotEmpty) .toSet(), ) |
| S2263 | símbolo | app/lib/domain/player/providers/anime_identity.dart:26 | localId |
| S2264 | símbolo | app/lib/domain/player/providers/anime_identity.dart:27 | externalIds |
| S2265 | símbolo | app/lib/domain/player/providers/anime_identity.dart:28 | titles |
| S2266 | símbolo | app/lib/domain/player/providers/anime_identity.dart:30 | /// Deterministic key for bounded caches; contains no credentials or URLs. String get cacheKey |
| S2267 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | enum AnimeMatchEvidence |
| S2268 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | externalId |
| S2269 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | exactTitle |
| S2270 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | fuzzy |
| S2271 | símbolo | app/lib/domain/player/providers/episode_source.dart:6 | unknown |
| S2272 | símbolo | app/lib/domain/player/providers/episode_source.dart:8 | /// A provider-local anime record matched against one requested identity. final class SourceAnimeMatch |
| S2273 | símbolo | app/lib/domain/player/providers/episode_source.dart:10 | SourceAnimeMatch({ required this.providerId, required this.sourceAnimeId, required this.title, required this.requestedIdentity, required this.evidence, Iterable<ExternalAnimeId> externalIds = const [], this.adapterVersion = '1.0.0', }) : externalIds = List.unmodifiable(externalIds.toSet()) |
| S2274 | símbolo | app/lib/domain/player/providers/episode_source.dart:28 | providerId |
| S2275 | símbolo | app/lib/domain/player/providers/episode_source.dart:29 | sourceAnimeId |
| S2276 | símbolo | app/lib/domain/player/providers/episode_source.dart:30 | title |
| S2277 | símbolo | app/lib/domain/player/providers/episode_source.dart:31 | requestedIdentity |
| S2278 | símbolo | app/lib/domain/player/providers/episode_source.dart:32 | evidence |
| S2279 | símbolo | app/lib/domain/player/providers/episode_source.dart:33 | externalIds |
| S2280 | símbolo | app/lib/domain/player/providers/episode_source.dart:34 | adapterVersion |
| S2281 | símbolo | app/lib/domain/player/providers/episode_source.dart:36 | /// Accept only exact provider-ID crosswalks or exact normalized titles. /// Fuzzy matches are surfaced to the adapter for diagnostics but cannot /// silently select a different series for playback. bool isConservativeMatch() |
| S2282 | símbolo | app/lib/domain/player/providers/episode_source.dart:56 | /// Provider-specific episode record; distinct from the app's playback request. final class EpisodeRef |
| S2283 | símbolo | app/lib/domain/player/providers/episode_source.dart:58 | EpisodeRef({ required this.anime, required this.episodeId, required this.episodeNumber, this.declaredLanguage = 'unknown', this.mappingEvidence = 'provider episode index', }) |
| S2284 | símbolo | app/lib/domain/player/providers/episode_source.dart:75 | anime |
| S2285 | símbolo | app/lib/domain/player/providers/episode_source.dart:76 | episodeId |
| S2286 | símbolo | app/lib/domain/player/providers/episode_source.dart:77 | episodeNumber |
| S2287 | símbolo | app/lib/domain/player/providers/episode_source.dart:78 | declaredLanguage |
| S2288 | símbolo | app/lib/domain/player/providers/episode_source.dart:79 | mappingEvidence |
| S2289 | símbolo | app/lib/domain/player/providers/episode_source.dart:81 | PlaybackProviderId get providerId |
| S2290 | símbolo | app/lib/domain/player/providers/episode_source.dart:82 | String get sourceAnimeId |
| S2291 | símbolo | app/lib/domain/player/providers/episode_source.dart:84 | String get cacheKey |
| S2292 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:7 | enum PlaybackProviderCapability |
| S2293 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:8 | episodeSources |
| S2294 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:9 | sourceAlternatives |
| S2295 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:10 | resolveServer |
| S2296 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:13 | enum PlaybackProviderFailureKind |
| S2297 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:14 | unavailable |
| S2298 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:15 | network |
| S2299 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:16 | timeout |
| S2300 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:17 | rateLimited |
| S2301 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:18 | invalidResponse |
| S2302 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:19 | unauthorized |
| S2303 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:20 | unsupported |
| S2304 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:21 | cancelled |
| S2305 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:22 | circuitOpen |
| S2306 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:23 | missingId |
| S2307 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:24 | noEpisodes |
| S2308 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:25 | noSources |
| S2309 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:26 | forbidden |
| S2310 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:27 | challenge |
| S2311 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:28 | ipBlocked |
| S2312 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:29 | policyBlocked |
| S2313 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:30 | iframeDenied |
| S2314 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:31 | geoRestricted |
| S2315 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:32 | drm |
| S2316 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:33 | notFound |
| S2317 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:34 | unsupportedEmbed |
| S2318 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:35 | expired |
| S2319 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:36 | invalidManifest |
| S2320 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:37 | decoderFailure |
| S2321 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:38 | blocked |
| S2322 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:39 | unknown |
| S2323 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:42 | extension PlaybackProviderFailureKindPolicy on PlaybackProviderFailureKind |
| S2324 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:43 | /// Transient provider/service failures count toward the 3/60 breaker. bool get countsTowardCircuit |
| S2325 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | enum PlaybackHttpStage |
| S2326 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | catalog |
| S2327 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | anime |
| S2328 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | episode |
| S2329 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | embed |
| S2330 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:74 | media |
| S2331 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:76 | final class PlaybackProviderFailure |
| S2332 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:77 | const PlaybackProviderFailure( this.kind, { this.retryAfter, this.httpStatus, this.host, this.server, this.stage, this.contentType, }) |
| S2333 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:87 | httpStatus |
| S2334 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:88 | host |
| S2335 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:89 | server |
| S2336 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:90 | stage |
| S2337 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:91 | contentType |
| S2338 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:93 | kind |
| S2339 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:94 | retryAfter |
| S2340 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:96 | bool get countsTowardCircuit |
| S2341 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:101 | sealed class PlaybackProviderResult<T> |
| S2342 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:102 | const PlaybackProviderResult() |
| S2343 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:105 | final class PlaybackProviderSuccess<T> extends PlaybackProviderResult<T> |
| S2344 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:106 | const PlaybackProviderSuccess(this.value) |
| S2345 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:107 | value |
| S2346 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:110 | final class PlaybackProviderEmpty<T> extends PlaybackProviderResult<T> |
| S2347 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:111 | const PlaybackProviderEmpty() |
| S2348 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:114 | final class PlaybackProviderUnsupported<T> extends PlaybackProviderResult<T> |
| S2349 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:115 | const PlaybackProviderUnsupported(this.capability) |
| S2350 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:116 | capability |
| S2351 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:119 | final class PlaybackProviderFailed<T> extends PlaybackProviderResult<T> |
| S2352 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:120 | const PlaybackProviderFailed(this.failure) |
| S2353 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:121 | failure |
| S2354 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:124 | /// Cooperative cancellation. Providers must check it before expensive work. final class PlaybackCancellationToken |
| S2355 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:130 | bool get isCancelled |
| S2356 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:131 | Future<void> get whenCancelled |
| S2357 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:133 | void cancel() |
| S2358 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:149 | /// Registers a one-shot callback and returns an unregister function. /// Registering after cancellation invokes the callback immediately. void Function() addCancelListener(void Function() listener) |
| S2359 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:161 | abstract interface class PlaybackSourceProvider |
| S2360 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:162 | PlaybackProviderId get id |
| S2361 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:163 | Set<PlaybackProviderCapability> get capabilities |
| S2362 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:165 | Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode episode, { required PlaybackCancellationToken cancellation, }) |
| S2363 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:171 | /// Resolves an episode server independently from the anime catalog provider. /// /// Implementations own HTTP host protocols only; they never discover anime, /// create a playback engine, or own a native player. abstract interface class PlaybackVideoHostResolver |
| S2364 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:176 | String get resolverId |
| S2365 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:178 | /// Stable host identity for diagnostics and host-scoped health policy. String get hostId |
| S2366 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:181 | bool supports(SourceCandidate candidate) |
| S2367 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:183 | Future<PlaybackProviderResult<ResolvedPlaybackStream>> resolve( PlaybackSource source, SourceCandidate candidate, { required PlaybackCancellationToken cancellation, }) |
| S2368 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:190 | /// Three-phase provider adapter: identify a source anime, enumerate its /// episodes, then discover host candidates for one provider episode. The /// existing manager consumes the final `findSources` bridge, so it remains the /// only registry and fallback coordinator. abstract base class EpisodeSourceAdapter implements PlaybackSourceProvider |
| S2369 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:195 | String get adapterVersion |
| S2370 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:197 | Future<PlaybackProviderResult<List<SourceAnimeMatch>>> searchAnime( AnimeIdentity identity, { required PlaybackCancellationToken cancellation, }) |
| S2371 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:202 | Future<PlaybackProviderResult<List<EpisodeRef>>> listEpisodes( SourceAnimeMatch match, { required PlaybackCancellationToken cancellation, }) |
| S2372 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:207 | /// Finds a selected episode. The default scans [listEpisodes], while /// adapters with paginated catalogs can override it to stop at the requested /// episode instead of fetching every page. Future<PlaybackProviderResult<EpisodeRef>> findEpisode( SourceAnimeMatch match, { required int episodeNumber, required PlaybackCancellationToken cancellation, }) |
| S2373 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:238 | Future<PlaybackProviderResult<List<PlaybackSource>>> findEpisodeSources( EpisodeRef episode, { required PlaybackCancellationToken cancellation, }) |
| S2374 | símbolo | app/lib/domain/player/providers/playback_provider_contract.dart:243 | @override Future<PlaybackProviderResult<List<PlaybackSource>>> findSources( PlaybackEpisode requested, { required PlaybackCancellationToken cancellation, }) |
| S2375 | símbolo | app/lib/domain/player/providers/playback_source.dart:6 | /// Provider-independent identity of an episode requested for playback. final class PlaybackEpisode |
| S2376 | símbolo | app/lib/domain/player/providers/playback_source.dart:8 | PlaybackEpisode({ required this.animeId, required this.episodeNumber, ExternalAnimeId? externalAnimeId, Iterable<ExternalAnimeId> externalAnimeIds = const [], Iterable<String> animeTitles = const [], }) : externalAnimeIds = List.unmodifiable(<ExternalAnimeId>{ ...externalAnimeIds, ?externalAnimeId, }), animeTitles = List.unmodifiable( animeTitles .map((String title) => title.trim()) .where((String title) => title.isNotEmpty) .toSet(), ) |
| S2377 | símbolo | app/lib/domain/player/providers/playback_source.dart:32 | factory PlaybackEpisode.fromIdentity( AnimeIdentity identity, { required int episodeNumber, }) |
| S2378 | símbolo | app/lib/domain/player/providers/playback_source.dart:42 | animeId |
| S2379 | símbolo | app/lib/domain/player/providers/playback_source.dart:43 | episodeNumber |
| S2380 | símbolo | app/lib/domain/player/providers/playback_source.dart:44 | externalAnimeIds |
| S2381 | símbolo | app/lib/domain/player/providers/playback_source.dart:45 | ExternalAnimeId? get externalAnimeId |
| S2382 | símbolo | app/lib/domain/player/providers/playback_source.dart:47 | animeTitles |
| S2383 | símbolo | app/lib/domain/player/providers/playback_source.dart:49 | AnimeIdentity get identity |
| S2384 | símbolo | app/lib/domain/player/providers/playback_source.dart:55 | String get requestKey |
| S2385 | símbolo | app/lib/domain/player/providers/playback_source.dart:74 | /// Stable provider identifier, independent from a provider's JSON format. final class PlaybackProviderId |
| S2386 | símbolo | app/lib/domain/player/providers/playback_source.dart:76 | factory PlaybackProviderId(String value) |
| S2387 | símbolo | app/lib/domain/player/providers/playback_source.dart:90 | value |
| S2388 | símbolo | app/lib/domain/player/providers/playback_source.dart:92 | @override bool operator ==(Object other) |
| S2389 | símbolo | app/lib/domain/player/providers/playback_source.dart:96 | @override int get hashCode |
| S2390 | símbolo | app/lib/domain/player/providers/playback_source.dart:99 | @override String toString() |
| S2391 | símbolo | app/lib/domain/player/providers/playback_source.dart:103 | enum PlaybackDubbingType |
| S2392 | símbolo | app/lib/domain/player/providers/playback_source.dart:104 | unknown |
| S2393 | símbolo | app/lib/domain/player/providers/playback_source.dart:105 | originalAudio |
| S2394 | símbolo | app/lib/domain/player/providers/playback_source.dart:106 | latinSpanish |
| S2395 | símbolo | app/lib/domain/player/providers/playback_source.dart:107 | castilianSpanish |
| S2396 | símbolo | app/lib/domain/player/providers/playback_source.dart:108 | other |
| S2397 | símbolo | app/lib/domain/player/providers/playback_source.dart:111 | /// `listed` is intentionally weaker than a transport check or a visible frame. enum PlaybackAvailability |
| S2398 | símbolo | app/lib/domain/player/providers/playback_source.dart:112 | unknown |
| S2399 | símbolo | app/lib/domain/player/providers/playback_source.dart:112 | listed |
| S2400 | símbolo | app/lib/domain/player/providers/playback_source.dart:112 | transportResponded |
| S2401 | símbolo | app/lib/domain/player/providers/playback_source.dart:112 | playable |
| S2402 | símbolo | app/lib/domain/player/providers/playback_source.dart:114 | /// A caption published alongside a specific provider episode, never a search result. final class ProviderSubtitle |
| S2403 | símbolo | app/lib/domain/player/providers/playback_source.dart:116 | ProviderSubtitle({ required this.id, required this.uri, required this.label, this.language = 'unknown', this.isDefault = false, }) |
| S2404 | símbolo | app/lib/domain/player/providers/playback_source.dart:137 | id |
| S2405 | símbolo | app/lib/domain/player/providers/playback_source.dart:138 | uri |
| S2406 | símbolo | app/lib/domain/player/providers/playback_source.dart:139 | label |
| S2407 | símbolo | app/lib/domain/player/providers/playback_source.dart:140 | language |
| S2408 | símbolo | app/lib/domain/player/providers/playback_source.dart:141 | isDefault |
| S2409 | símbolo | app/lib/domain/player/providers/playback_source.dart:143 | @override bool operator ==(Object other) |
| S2410 | símbolo | app/lib/domain/player/providers/playback_source.dart:151 | @override int get hashCode |
| S2411 | símbolo | app/lib/domain/player/providers/playback_source.dart:166 | /// A concrete episode source returned by one provider. final class PlaybackSource |
| S2412 | símbolo | app/lib/domain/player/providers/playback_source.dart:168 | PlaybackSource({ required this.id, required this.providerId, required this.episode, required this.language, required this.quality, required Iterable<PlaybackServer> servers, this.priority = 0, this.audioLanguage = 'unknown', this.subtitleLanguage, this.dubbingType = PlaybackDubbingType.unknown, this.providerAnnouncedLanguage = 'unknown', this.displayName, Iterable<ProviderSubtitle> subtitles = const [], }) : subtitles = _validatedSubtitles(subtitles), servers = List.unmodifiable(servers) |
| S2413 | símbolo | app/lib/domain/player/providers/playback_source.dart:203 | id |
| S2414 | símbolo | app/lib/domain/player/providers/playback_source.dart:204 | providerId |
| S2415 | símbolo | app/lib/domain/player/providers/playback_source.dart:205 | episode |
| S2416 | símbolo | app/lib/domain/player/providers/playback_source.dart:206 | language |
| S2417 | símbolo | app/lib/domain/player/providers/playback_source.dart:207 | quality |
| S2418 | símbolo | app/lib/domain/player/providers/playback_source.dart:208 | priority |
| S2419 | símbolo | app/lib/domain/player/providers/playback_source.dart:211 | audioLanguage |
| S2420 | símbolo | app/lib/domain/player/providers/playback_source.dart:214 | subtitleLanguage |
| S2421 | símbolo | app/lib/domain/player/providers/playback_source.dart:215 | dubbingType |
| S2422 | símbolo | app/lib/domain/player/providers/playback_source.dart:218 | providerAnnouncedLanguage |
| S2423 | símbolo | app/lib/domain/player/providers/playback_source.dart:219 | displayName |
| S2424 | símbolo | app/lib/domain/player/providers/playback_source.dart:220 | servers |
| S2425 | símbolo | app/lib/domain/player/providers/playback_source.dart:221 | subtitles |
| S2426 | símbolo | app/lib/domain/player/providers/playback_source.dart:224 | enum PlaybackCandidateKind |
| S2427 | símbolo | app/lib/domain/player/providers/playback_source.dart:224 | media |
| S2428 | símbolo | app/lib/domain/player/providers/playback_source.dart:224 | embed |
| S2429 | símbolo | app/lib/domain/player/providers/playback_source.dart:224 | redirect |
| S2430 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | enum PlaybackMediaFormat |
| S2431 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | unknown |
| S2432 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | mp4 |
| S2433 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | hls |
| S2434 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | dash |
| S2435 | símbolo | app/lib/domain/player/providers/playback_source.dart:226 | webm |
| S2436 | símbolo | app/lib/domain/player/providers/playback_source.dart:228 | /// One provider-published endpoint candidate, including its host identity and /// presentation modality. `PlaybackServer` remains a source-compatible alias. final class SourceCandidate |
| S2437 | símbolo | app/lib/domain/player/providers/playback_source.dart:231 | SourceCandidate({ required this.id, required this.endpoint, String? hostId, this.priority = 0, this.kind = PlaybackCandidateKind.media, this.declaredLanguage = 'unknown', this.mediaFormat = PlaybackMediaFormat.unknown, this.quality, this.displayName, this.availability = PlaybackAvailability.listed, this.sourceEpisodeId, this.expiresAt, this.provenance = 'provider candidate', this.requestHeaders = const PlaybackRequestHeaders.empty(), }) : hostId = (hostId ?? _hostIdFor(endpoint)).trim().toLowerCase() |
| S2438 | símbolo | app/lib/domain/player/providers/playback_source.dart:265 | id |
| S2439 | símbolo | app/lib/domain/player/providers/playback_source.dart:266 | endpoint |
| S2440 | símbolo | app/lib/domain/player/providers/playback_source.dart:267 | hostId |
| S2441 | símbolo | app/lib/domain/player/providers/playback_source.dart:268 | priority |
| S2442 | símbolo | app/lib/domain/player/providers/playback_source.dart:269 | kind |
| S2443 | símbolo | app/lib/domain/player/providers/playback_source.dart:270 | declaredLanguage |
| S2444 | símbolo | app/lib/domain/player/providers/playback_source.dart:271 | mediaFormat |
| S2445 | símbolo | app/lib/domain/player/providers/playback_source.dart:272 | quality |
| S2446 | símbolo | app/lib/domain/player/providers/playback_source.dart:275 | displayName |
| S2447 | símbolo | app/lib/domain/player/providers/playback_source.dart:276 | availability |
| S2448 | símbolo | app/lib/domain/player/providers/playback_source.dart:277 | sourceEpisodeId |
| S2449 | símbolo | app/lib/domain/player/providers/playback_source.dart:278 | expiresAt |
| S2450 | símbolo | app/lib/domain/player/providers/playback_source.dart:279 | provenance |
| S2451 | símbolo | app/lib/domain/player/providers/playback_source.dart:280 | requestHeaders |
| S2452 | símbolo | app/lib/domain/player/providers/playback_source.dart:282 | /// Circuit key bound to the actual destination origin, not provider input. String get hostKey |
| S2453 | símbolo | app/lib/domain/player/providers/playback_source.dart:289 | typedef PlaybackServer = SourceCandidate; |
| S2454 | símbolo | app/lib/domain/player/providers/playback_source.dart:291 | /// Public, non-authentication HTTP context required by a media endpoint. /// /// Supports public `Referer`/`Origin`, a per-media `User-Agent`, `Sec-Fetch-Site` /// (the standard fetch-metadata header a browser sets on its own requests, with /// no credential content), and two non-secret protocol headers used by public /// catalog APIs (values are strictly validated; they never carry credentials or /// cookies). Cookies, authorization credentials, and arbitrary caller-supplied /// headers are rejected. final class PlaybackRequestHeaders |
| S2455 | símbolo | app/lib/domain/player/providers/playback_source.dart:300 | factory PlaybackRequestHeaders(Map<String, String> values) |
| S2456 | símbolo | app/lib/domain/player/providers/playback_source.dart:373 | const PlaybackRequestHeaders.empty() : values = const {} |
| S2457 | símbolo | app/lib/domain/player/providers/playback_source.dart:377 | values |
| S2458 | símbolo | app/lib/domain/player/providers/playback_source.dart:379 | bool get isEmpty |
| S2459 | símbolo | app/lib/domain/player/providers/playback_source.dart:408 | /// Normalized media ready for the existing playback coordinator; never owns a /// Player. Embeds and redirects are not valid playable sources. final class PlayableSource |
| S2460 | símbolo | app/lib/domain/player/providers/playback_source.dart:411 | PlayableSource({ required this.providerId, required this.sourceId, required this.serverId, required this.uri, this.format = PlaybackMediaFormat.unknown, this.sourceLabel, this.displayName, this.availability = PlaybackAvailability.listed, this.expiresAt, this.validatedAt, this.provenance = 'host resolver', this.httpHeaders = const PlaybackRequestHeaders.empty(), Iterable<ProviderSubtitle> subtitles = const [], }) : subtitles = _validatedSubtitles(subtitles) |
| S2461 | símbolo | app/lib/domain/player/providers/playback_source.dart:440 | providerId |
| S2462 | símbolo | app/lib/domain/player/providers/playback_source.dart:441 | sourceId |
| S2463 | símbolo | app/lib/domain/player/providers/playback_source.dart:442 | serverId |
| S2464 | símbolo | app/lib/domain/player/providers/playback_source.dart:443 | uri |
| S2465 | símbolo | app/lib/domain/player/providers/playback_source.dart:444 | format |
| S2466 | símbolo | app/lib/domain/player/providers/playback_source.dart:445 | sourceLabel |
| S2467 | símbolo | app/lib/domain/player/providers/playback_source.dart:446 | displayName |
| S2468 | símbolo | app/lib/domain/player/providers/playback_source.dart:447 | availability |
| S2469 | símbolo | app/lib/domain/player/providers/playback_source.dart:448 | expiresAt |
| S2470 | símbolo | app/lib/domain/player/providers/playback_source.dart:449 | validatedAt |
| S2471 | símbolo | app/lib/domain/player/providers/playback_source.dart:450 | provenance |
| S2472 | símbolo | app/lib/domain/player/providers/playback_source.dart:451 | httpHeaders |
| S2473 | símbolo | app/lib/domain/player/providers/playback_source.dart:452 | subtitles |
| S2474 | símbolo | app/lib/domain/player/providers/playback_source.dart:454 | bool isExpiredAt(DateTime now) |
| S2475 | símbolo | app/lib/domain/player/providers/playback_source.dart:458 | typedef ResolvedPlaybackStream = PlayableSource; |
| S2476 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:4 | /// Manual prompts are enabled; automatic seeks stay opt-in. final class SkipAutomationSettings |
| S2477 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:6 | const SkipAutomationSettings({ this.showManualPrompts = true, this.opening = false, this.ending = false, this.recap = false, this.filler = false, }) |
| S2478 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:14 | showManualPrompts |
| S2479 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:15 | opening |
| S2480 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:16 | ending |
| S2481 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:17 | recap |
| S2482 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:18 | filler |
| S2483 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:21 | enum FillerClassification |
| S2484 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:21 | unknown |
| S2485 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:21 | filler |
| S2486 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:21 | canon |
| S2487 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:23 | /// Filler facts need an explicit trusted source and an exact episode match. final class EpisodeFillerEvidence |
| S2488 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:25 | EpisodeFillerEvidence({ required this.episode, required this.classification, required this.sourceId, required this.verified, }) |
| S2489 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:36 | episode |
| S2490 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:37 | classification |
| S2491 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:38 | sourceId |
| S2492 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:39 | verified |
| S2493 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:42 | final class SkipAutomationPolicy |
| S2494 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:43 | const SkipAutomationPolicy() |
| S2495 | símbolo | app/lib/domain/player/skips/skip_automation_policy.dart:45 | bool allows({ required SkipAutomationSettings settings, required SkipSegment segment, required PlaybackEpisode episode, required Duration duration, EpisodeFillerEvidence? fillerEvidence, }) |
| S2496 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | enum SkipSegmentKind |
| S2497 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | opening |
| S2498 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | ending |
| S2499 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | recap |
| S2500 | símbolo | app/lib/domain/player/skips/skip_segment.dart:3 | filler |
| S2501 | símbolo | app/lib/domain/player/skips/skip_segment.dart:5 | enum SkipSegmentSource |
| S2502 | símbolo | app/lib/domain/player/skips/skip_segment.dart:5 | aniskip |
| S2503 | símbolo | app/lib/domain/player/skips/skip_segment.dart:5 | curated |
| S2504 | símbolo | app/lib/domain/player/skips/skip_segment.dart:7 | /// A community or curated time range tied to one exact episode identity. final class SkipSegment |
| S2505 | símbolo | app/lib/domain/player/skips/skip_segment.dart:9 | SkipSegment({ required this.episode, required this.kind, required this.start, required this.end, required this.source, required this.sourceId, this.votes, this.confirmations, }) |
| S2506 | símbolo | app/lib/domain/player/skips/skip_segment.dart:28 | episode |
| S2507 | símbolo | app/lib/domain/player/skips/skip_segment.dart:29 | kind |
| S2508 | símbolo | app/lib/domain/player/skips/skip_segment.dart:30 | start |
| S2509 | símbolo | app/lib/domain/player/skips/skip_segment.dart:31 | end |
| S2510 | símbolo | app/lib/domain/player/skips/skip_segment.dart:32 | source |
| S2511 | símbolo | app/lib/domain/player/skips/skip_segment.dart:33 | sourceId |
| S2512 | símbolo | app/lib/domain/player/skips/skip_segment.dart:34 | votes |
| S2513 | símbolo | app/lib/domain/player/skips/skip_segment.dart:35 | confirmations |
| S2514 | símbolo | app/lib/domain/player/skips/skip_segment.dart:37 | bool isValidFor(PlaybackEpisode currentEpisode, Duration duration) |
| S2515 | símbolo | app/lib/domain/player/skips/skip_segment.dart:44 | bool contains(Duration position) |
| S2516 | símbolo | app/lib/domain/player/skips/skip_segment.dart:46 | String get stableKey |
| S2517 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:4 | final class MyAnimeListAnimeId |
| S2518 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:5 | factory MyAnimeListAnimeId(int value) |
| S2519 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:11 | value |
| S2520 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:14 | enum SkipCatalogFailureKind |
| S2521 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:15 | network |
| S2522 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:16 | rateLimited |
| S2523 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:17 | server |
| S2524 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:18 | malformedResponse |
| S2525 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:19 | cache |
| S2526 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:22 | sealed class SkipCatalogResult |
| S2527 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:23 | const SkipCatalogResult() |
| S2528 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:26 | final class SkipCatalogSuccess extends SkipCatalogResult |
| S2529 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:27 | const SkipCatalogSuccess(this.segments) |
| S2530 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:28 | segments |
| S2531 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:31 | final class SkipCatalogUnavailable extends SkipCatalogResult |
| S2532 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:32 | const SkipCatalogUnavailable(this.reason) |
| S2533 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:33 | reason |
| S2534 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:36 | final class SkipCatalogFailure extends SkipCatalogResult |
| S2535 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:37 | const SkipCatalogFailure(this.kind) |
| S2536 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:38 | kind |
| S2537 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:41 | /// Source contract for episode-specific opening/ending skip segments. abstract interface class SkipSegmentCatalog |
| S2538 | símbolo | app/lib/domain/player/skips/skip_segment_catalog.dart:43 | Future<SkipCatalogResult> lookup({ required PlaybackEpisode episode, required MyAnimeListAnimeId malAnimeId, }) |
| S2539 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:3 | /// User-facing search request for a third-party subtitle catalogue. final class ExternalSubtitleQuery |
| S2540 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:5 | ExternalSubtitleQuery({ String? query, Iterable<String> languages = const [], this.imdbId, this.parentImdbId, this.tmdbId, this.season, this.episode, this.movieHash, this.fileName, }) : query = query, languages = List.unmodifiable(languages) |
| S2541 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:69 | query |
| S2542 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:70 | languages |
| S2543 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:71 | imdbId |
| S2544 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:72 | parentImdbId |
| S2545 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:73 | tmdbId |
| S2546 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:74 | season |
| S2547 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:75 | episode |
| S2548 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:76 | movieHash |
| S2549 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:77 | fileName |
| S2550 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:80 | final class ExternalSubtitleCandidate |
| S2551 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:81 | const ExternalSubtitleCandidate({ required this.subtitleId, required this.fileId, required this.fileName, required this.language, required this.format, this.release, this.downloadCount, this.movieHashMatch = false, this.hearingImpaired = false, this.fps, this.partNumber, this.partCount, }) |
| S2552 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:96 | subtitleId |
| S2553 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:97 | fileId |
| S2554 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:98 | fileName |
| S2555 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:99 | language |
| S2556 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:100 | format |
| S2557 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:101 | release |
| S2558 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:102 | downloadCount |
| S2559 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:103 | movieHashMatch |
| S2560 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:104 | hearingImpaired |
| S2561 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:105 | fps |
| S2562 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:106 | partNumber |
| S2563 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:107 | partCount |
| S2564 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:110 | final class ExternalSubtitleDownload |
| S2565 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:111 | const ExternalSubtitleDownload({ required this.uri, required this.format, required this.language, required this.remainingDownloads, required this.resetAt, }) |
| S2566 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:120 | uri |
| S2567 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:121 | format |
| S2568 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:122 | language |
| S2569 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:123 | remainingDownloads |
| S2570 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:124 | resetAt |
| S2571 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:127 | sealed class ExternalSubtitleResult<T> |
| S2572 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:128 | const ExternalSubtitleResult() |
| S2573 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:131 | final class ExternalSubtitleSuccess<T> extends ExternalSubtitleResult<T> |
| S2574 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:132 | const ExternalSubtitleSuccess(this.value) |
| S2575 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:133 | value |
| S2576 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:136 | final class ExternalSubtitleFailure<T> extends ExternalSubtitleResult<T> |
| S2577 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:137 | const ExternalSubtitleFailure(this.kind, {this.retryAfter}) |
| S2578 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:138 | kind |
| S2579 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:139 | retryAfter |
| S2580 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:142 | enum ExternalSubtitleFailureKind |
| S2581 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:143 | missingApiKey |
| S2582 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:144 | unauthorized |
| S2583 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:145 | forbidden |
| S2584 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:146 | notFound |
| S2585 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:147 | rateLimited |
| S2586 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:148 | quotaExhausted |
| S2587 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:149 | timeout |
| S2588 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:150 | network |
| S2589 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:151 | malformedResponse |
| S2590 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:152 | unsupportedFormat |
| S2591 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:153 | invalidDownloadUrl |
| S2592 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:154 | invalidApiRedirect |
| S2593 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:155 | tooLarge |
| S2594 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:156 | corruptFile |
| S2595 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:157 | storageFailure |
| S2596 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:158 | blockedByHardsub |
| S2597 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:159 | unknown |
| S2598 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:162 | abstract interface class ExternalSubtitleCatalog |
| S2599 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:163 | Future<ExternalSubtitleResult<List<ExternalSubtitleCandidate>>> search( ExternalSubtitleQuery query, ) |
| S2600 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:167 | Future<ExternalSubtitleResult<ExternalSubtitleDownload>> download( ExternalSubtitleCandidate candidate, ) |
| S2601 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:172 | /// Engine capability used by application to attach a downloaded local subtitle. abstract interface class ExternalSubtitleLoader |
| S2602 | símbolo | app/lib/domain/player/subtitles/external_subtitle_catalog.dart:174 | Future<ExternalSubtitleDecision> loadExternalSubtitle( Uri source, { required HardsubStatus hardsubStatus, String? title, String? language, int? sourceGeneration, }) |
| S2603 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:1 | enum HardsubStatus |
| S2604 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:1 | confirmedPresent |
| S2605 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:1 | confirmedAbsent |
| S2606 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:1 | unknown |
| S2607 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:3 | enum ExternalSubtitleDecision |
| S2608 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:3 | allowed |
| S2609 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:3 | allowedWithUncertainty |
| S2610 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:3 | blocked |
| S2611 | símbolo | app/lib/domain/player/subtitles/hardsub_policy.dart:5 | /// External subtitles may be attached only when a trusted source has not /// explicitly confirmed that subtitles are already burned into video frames. ExternalSubtitleDecision externalSubtitleDecision(HardsubStatus status) |
| S2612 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:1 | /// User style mapped to mpv's documented `sub-*` options. final class SubtitleStyle |
| S2613 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:3 | SubtitleStyle({ this.fontFamily = 'sans-serif', this.fontSize = 38, this.color = '#FFFFFFFF', this.outlineColor = '#FF000000', this.outlineSize = 1.65, this.bold = false, this.position = 95, this.overrideAssStyles = false, }) |
| S2614 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:37 | fontFamily |
| S2615 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:38 | fontSize |
| S2616 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:39 | color |
| S2617 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:40 | outlineColor |
| S2618 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:41 | outlineSize |
| S2619 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:42 | bold |
| S2620 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:43 | position |
| S2621 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:47 | overrideAssStyles |
| S2622 | símbolo | app/lib/domain/player/subtitles/subtitle_style.dart:49 | SubtitleStyle copyWith({ String? fontFamily, double? fontSize, String? color, String? outlineColor, double? outlineSize, bool? bold, int? position, bool? overrideAssStyles, }) |
| S2623 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:1 | /// Normalized subtitle-track metadata exposed to application and presentation. final class SubtitleTrackInfo |
| S2624 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:3 | const SubtitleTrackInfo({ required this.id, required this.label, required this.kind, this.language, this.codec, this.isDefault = false, this.isSelected = false, }) |
| S2625 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:13 | id |
| S2626 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:14 | label |
| S2627 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:15 | kind |
| S2628 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:16 | language |
| S2629 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:17 | codec |
| S2630 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:18 | isDefault |
| S2631 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:19 | isSelected |
| S2632 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | enum SubtitleTrackKind |
| S2633 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | automatic |
| S2634 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | disabled |
| S2635 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | embedded |
| S2636 | símbolo | app/lib/domain/player/subtitles/subtitle_track_info.dart:22 | external |
| S2637 | símbolo | app/lib/domain/player/video_track_info.dart:1 | /// Native video-track metadata valid only for the currently opened source. /// The dimensions and bitrate are demuxer hints; they are not an ABR ladder. final class VideoTrackInfo |
| S2638 | símbolo | app/lib/domain/player/video_track_info.dart:4 | const VideoTrackInfo({ required this.id, this.title, this.codec, this.width, this.height, this.fps, this.bitrate, this.isDefault, }) |
| S2639 | símbolo | app/lib/domain/player/video_track_info.dart:15 | id |
| S2640 | símbolo | app/lib/domain/player/video_track_info.dart:16 | title |
| S2641 | símbolo | app/lib/domain/player/video_track_info.dart:17 | codec |
| S2642 | símbolo | app/lib/domain/player/video_track_info.dart:18 | width |
| S2643 | símbolo | app/lib/domain/player/video_track_info.dart:19 | height |
| S2644 | símbolo | app/lib/domain/player/video_track_info.dart:20 | fps |
| S2645 | símbolo | app/lib/domain/player/video_track_info.dart:21 | bitrate |
| S2646 | símbolo | app/lib/domain/player/video_track_info.dart:22 | isDefault |
| S2647 | símbolo | app/lib/domain/player/video_track_info.dart:24 | String get label |
| S2648 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | enum PlaybackEventKind |
| S2649 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | playing |
| S2650 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | paused |
| S2651 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | seeked |
| S2652 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | closing |
| S2653 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:7 | completed |
| S2654 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:9 | /// Event-driven policy: caller supplies active playback ticks; no timer/task is /// owned here. A checkpoint is considered saved only after writer success. final class CheckpointCoordinator |
| S2655 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:12 | CheckpointCoordinator({ required this.write, DateTime Function()? clock, this.interval = const Duration(seconds: 10), this.seekThresholdMs = 30000, }) : _clock = clock ?? DateTime.now |
| S2656 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:19 | write |
| S2657 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:21 | interval |
| S2658 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:22 | seekThresholdMs |
| S2659 | símbolo | app/lib/domain/progress/checkpoint_coordinator.dart:27 | Future<bool> handle({ required PlaybackEventKind event, required ProgressKey key, required int positionMs, required int? durationMs, int revision = 0, }) |
| S2660 | símbolo | app/lib/domain/progress/content_identity.dart:1 | /// Stable AnimeApp-owned identity, independent of catalog or stream provider. final class ContentId |
| S2661 | símbolo | app/lib/domain/progress/content_identity.dart:3 | ContentId(String value) : value = _normalize(value, 'contentId') |
| S2662 | símbolo | app/lib/domain/progress/content_identity.dart:4 | value |
| S2663 | símbolo | app/lib/domain/progress/content_identity.dart:5 | @override bool operator ==(Object other) |
| S2664 | símbolo | app/lib/domain/progress/content_identity.dart:7 | @override int get hashCode |
| S2665 | símbolo | app/lib/domain/progress/content_identity.dart:11 | final class EpisodeId |
| S2666 | símbolo | app/lib/domain/progress/content_identity.dart:12 | EpisodeId(String value) : value = _normalize(value, 'episodeId') |
| S2667 | símbolo | app/lib/domain/progress/content_identity.dart:13 | value |
| S2668 | símbolo | app/lib/domain/progress/content_identity.dart:14 | @override bool operator ==(Object other) |
| S2669 | símbolo | app/lib/domain/progress/content_identity.dart:16 | @override int get hashCode |
| S2670 | símbolo | app/lib/domain/progress/content_identity.dart:20 | final class ProgressKey |
| S2671 | símbolo | app/lib/domain/progress/content_identity.dart:21 | const ProgressKey({required this.contentId, required this.episodeId}) |
| S2672 | símbolo | app/lib/domain/progress/content_identity.dart:22 | contentId |
| S2673 | símbolo | app/lib/domain/progress/content_identity.dart:23 | episodeId |
| S2674 | símbolo | app/lib/domain/progress/content_identity.dart:24 | String get storageKey |
| S2675 | símbolo | app/lib/domain/progress/content_identity.dart:26 | @override bool operator ==(Object other) |
| S2676 | símbolo | app/lib/domain/progress/content_identity.dart:31 | @override int get hashCode |
| S2677 | símbolo | app/lib/domain/progress/playback_progress.dart:3 | enum CompletionState |
| S2678 | símbolo | app/lib/domain/progress/playback_progress.dart:3 | inProgress |
| S2679 | símbolo | app/lib/domain/progress/playback_progress.dart:3 | completed |
| S2680 | símbolo | app/lib/domain/progress/playback_progress.dart:5 | /// Position and duration are integer milliseconds; updatedAtUtc is the local /// persistence instant and is not a cross-device ordering authority. final class PlaybackProgress |
| S2681 | símbolo | app/lib/domain/progress/playback_progress.dart:8 | const PlaybackProgress({ required this.key, required this.positionMs, required this.durationMs, required this.updatedAtUtc, this.completion = CompletionState.inProgress, this.revision = 0, }) |
| S2682 | símbolo | app/lib/domain/progress/playback_progress.dart:16 | key |
| S2683 | símbolo | app/lib/domain/progress/playback_progress.dart:17 | positionMs |
| S2684 | símbolo | app/lib/domain/progress/playback_progress.dart:18 | durationMs |
| S2685 | símbolo | app/lib/domain/progress/playback_progress.dart:19 | updatedAtUtc |
| S2686 | símbolo | app/lib/domain/progress/playback_progress.dart:20 | completion |
| S2687 | símbolo | app/lib/domain/progress/playback_progress.dart:21 | revision |
| S2688 | símbolo | app/lib/domain/progress/playback_progress.dart:23 | String? validate() |
| S2689 | símbolo | app/lib/domain/progress/playback_progress.dart:38 | int get resumePositionMs |
| S2690 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:5 | abstract interface class PlaybackProgressRepository |
| S2691 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:6 | Future<Result<void>> upsert(PlaybackProgress progress) |
| S2692 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:7 | Future<Result<PlaybackProgress?>> get(ProgressKey key) |
| S2693 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:8 | Future<Result<List<PlaybackProgress>>> list(ContentIdFilter filter) |
| S2694 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:9 | Future<Result<void>> delete(ProgressKey key) |
| S2695 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:12 | final class ContentIdFilter |
| S2696 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:13 | const ContentIdFilter(this.value) |
| S2697 | símbolo | app/lib/domain/progress/playback_progress_repository.dart:14 | value |
| S2698 | símbolo | app/lib/domain/progress/progress_document.dart:1 | /// A caller-identified, JSON-compatible persisted progress document. /// /// Its payload is intentionally opaque until the owner defines the actual /// progress fields and temporal/business semantics. final class ProgressDocument |
| S2699 | símbolo | app/lib/domain/progress/progress_document.dart:6 | const ProgressDocument({ required this.identity, required this.payload, required this.updatedAtUtc, }) |
| S2700 | símbolo | app/lib/domain/progress/progress_document.dart:12 | identity |
| S2701 | símbolo | app/lib/domain/progress/progress_document.dart:13 | payload |
| S2702 | símbolo | app/lib/domain/progress/progress_document.dart:16 | updatedAtUtc |
| S2703 | símbolo | app/lib/domain/progress/progress_document.dart:19 | /// Input for a local progress write. The persistence adapter supplies the /// technical write timestamp so callers cannot imply business-time meaning. final class ProgressDraft |
| S2704 | símbolo | app/lib/domain/progress/progress_document.dart:22 | const ProgressDraft({required this.identity, required this.payload}) |
| S2705 | símbolo | app/lib/domain/progress/progress_document.dart:24 | identity |
| S2706 | símbolo | app/lib/domain/progress/progress_document.dart:25 | payload |
| S2707 | símbolo | app/lib/domain/progress/progress_repository.dart:4 | /// Local-first contract for storing opaque progress documents by caller-owned /// stable identity. It has no remote synchronization or conflict policy. abstract interface class ProgressRepository |
| S2708 | símbolo | app/lib/domain/progress/progress_repository.dart:7 | Future<Result<void>> save(ProgressDraft draft) |
| S2709 | símbolo | app/lib/domain/progress/progress_repository.dart:9 | Future<Result<ProgressDocument?>> getByIdentity(String identity) |
| S2710 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:1 | /// Opaque application-owned payload offered to a remote adapter. /// /// Identity and payload semantics remain caller-owned until the sync policy is /// approved; this contract does not merge or order changes. final class SyncEnvelope |
| S2711 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:6 | const SyncEnvelope({required this.requestId, required this.payload}) |
| S2712 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:8 | requestId |
| S2713 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:9 | payload |
| S2714 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:12 | /// Acknowledgment that the remote adapter accepted this request identifier. final class SyncReceipt |
| S2715 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:14 | const SyncReceipt({required this.requestId}) |
| S2716 | símbolo | app/lib/domain/synchronization/sync_envelope.dart:16 | requestId |
| S2717 | símbolo | app/lib/domain/synchronization/sync_remote.dart:4 | /// Remote boundary only. It intentionally leaves retries, conflict handling, /// ordering, deletion, and idempotency policy to a future approved protocol. abstract interface class SyncRemote |
| S2718 | símbolo | app/lib/domain/synchronization/sync_remote.dart:7 | Future<Result<SyncReceipt>> submit(SyncEnvelope envelope) |
| S2719 | símbolo | app/lib/main.dart:18 | Future<void> main() |
| S2720 | símbolo | app/lib/main_player_spike.dart:16 | Future<void> main() |
| S2721 | símbolo | app/lib/main_player_spike.dart:134 | final class SpikePlayerApp extends StatefulWidget |
| S2722 | símbolo | app/lib/main_player_spike.dart:135 | const SpikePlayerApp({ required this.moduleFuture, this.demo, this.retryPendingCleanup = MediaKitSpikeEngine.retryPendingDispose, this.closeWatchdog = const Duration(seconds: 15), super.key, }) |
| S2723 | símbolo | app/lib/main_player_spike.dart:143 | moduleFuture |
| S2724 | símbolo | app/lib/main_player_spike.dart:144 | demo |
| S2725 | símbolo | app/lib/main_player_spike.dart:145 | retryPendingCleanup |
| S2726 | símbolo | app/lib/main_player_spike.dart:147 | closeWatchdog |
| S2727 | símbolo | app/lib/main_player_spike.dart:149 | @override State<SpikePlayerApp> createState() |
| S2728 | símbolo | app/lib/settings/registry/setting_definition.dart:3 | typedef SettingEncoder<T> = Object? Function(T value); |
| S2729 | símbolo | app/lib/settings/registry/setting_definition.dart:4 | typedef SettingDecoder<T> = T Function(Object? jsonValue); |
| S2730 | símbolo | app/lib/settings/registry/setting_definition.dart:5 | typedef SettingValidator<T> = bool Function(T value); |
| S2731 | símbolo | app/lib/settings/registry/setting_definition.dart:7 | /// Typed contract for one explicitly registered, non-secret preference. class SettingDefinition<T> |
| S2732 | símbolo | app/lib/settings/registry/setting_definition.dart:9 | SettingDefinition({ required this.key, required this.owner, required this.defaultValue, required this.encode, required this.decode, required this.isValid, }) |
| S2733 | símbolo | app/lib/settings/registry/setting_definition.dart:25 | key |
| S2734 | símbolo | app/lib/settings/registry/setting_definition.dart:26 | owner |
| S2735 | símbolo | app/lib/settings/registry/setting_definition.dart:27 | defaultValue |
| S2736 | símbolo | app/lib/settings/registry/setting_definition.dart:28 | encode |
| S2737 | símbolo | app/lib/settings/registry/setting_definition.dart:29 | decode |
| S2738 | símbolo | app/lib/settings/registry/setting_definition.dart:30 | isValid |
| S2739 | símbolo | app/lib/settings/registry/setting_definition.dart:32 | String encodeJson(T value) |
| S2740 | símbolo | app/lib/settings/registry/setting_definition.dart:39 | T decodeJson(String json) |
| S2741 | símbolo | app/lib/settings/registry/settings_registry.dart:5 | /// Validates unique definitions and resolves them without exposing storage. class SettingsRegistry |
| S2742 | símbolo | app/lib/settings/registry/settings_registry.dart:7 | SettingsRegistry() |
| S2743 | símbolo | app/lib/settings/registry/settings_registry.dart:10 | void register<T>(SettingDefinition<T> definition) |
| S2744 | símbolo | app/lib/settings/registry/settings_registry.dart:17 | Result<SettingDefinition<T>> resolve<T>(SettingDefinition<T> definition) |
| S2745 | símbolo | app/lib/settings/store/settings_store.dart:7 | /// Local-first settings persistence. Secrets must use a secure-store adapter. class SettingsStore |
| S2746 | símbolo | app/lib/settings/store/settings_store.dart:9 | SettingsStore({ required this.database, required this.registry, DateTime Function()? clock, }) : _clock = clock ?? DateTime.now |
| S2747 | símbolo | app/lib/settings/store/settings_store.dart:15 | database |
| S2748 | símbolo | app/lib/settings/store/settings_store.dart:16 | registry |
| S2749 | símbolo | app/lib/settings/store/settings_store.dart:19 | Future<Result<T>> get<T>(SettingDefinition<T> definition) |
| S2750 | símbolo | app/lib/settings/store/settings_store.dart:39 | Future<Result<void>> set<T>(SettingDefinition<T> definition, T value) |
| S2751 | símbolo | app/lib/settings/store/settings_store.dart:66 | Stream<Result<T>> watch<T>(SettingDefinition<T> definition) |
| C0001 | endpoint/cabecera/parámetro | app/lib/app/anime_app.dart:40 | data: ThemeData( |
| C0002 | ruta/pantalla | app/lib/app/catalog/anime_detail_page.dart:18 | final class AnimeDetailPage extends StatefulWidget { |
| C0003 | endpoint/cabecera/parámetro | app/lib/app/catalog/anime_detail_page.dart:110 | /// The index is separate from AniList metadata: it lists episodes only and |
| C0004 | endpoint/cabecera/parámetro | app/lib/app/catalog/anime_detail_page.dart:354 | body: Column( |
| C0005 | endpoint/cabecera/parámetro | app/lib/app/catalog/anime_detail_page.dart:359 | metadata: metadata, |
| C0006 | endpoint/cabecera/parámetro | app/lib/app/catalog/anime_detail_page.dart:402 | metadata: metadata, |
| C0007 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:34 | final class CatalogHomePage extends StatefulWidget { |
| C0008 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:95 | initialMetadata: anime.metadata, |
| C0009 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:103 | initialMetadata: metadata, |
| C0010 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:112 | initialMetadata: item.metadata, |
| C0011 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:204 | await Navigator.of(context).push<void>( |
| C0012 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:205 | MaterialPageRoute<void>( |
| C0013 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:330 | body: Row( |
| C0014 | persistencia | app/lib/app/catalog/catalog_home_page.dart:374 | key: ValueKey('anime-detail-$index'), |
| C0015 | endpoint/cabecera/parámetro | app/lib/app/catalog/catalog_home_page.dart:380 | initialMetadata: |
| C0016 | persistencia | app/lib/app/catalog/catalog_home_page.dart:451 | key: ValueKey<String>( |
| C0017 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:457 | onTap: () => Navigator.of(context).pop(stream), |
| C0018 | ruta/pantalla | app/lib/app/catalog/catalog_home_page.dart:465 | onPressed: () => Navigator.of(context).pop(), |
| C0019 | persistencia | app/lib/app/catalog/catalog_home_page.dart:620 | key: const ValueKey('home-search-field'), |
| C0020 | persistencia | app/lib/app/catalog/catalog_home_page.dart:687 | final String? key = Platform.environment['OPENSUBTITLES_API_KEY']?.trim(); |
| C0021 | configuración | app/lib/app/catalog/catalog_home_page.dart:687 | final String? key = Platform.environment['OPENSUBTITLES_API_KEY']?.trim(); |
| C0022 | persistencia | app/lib/app/catalog/catalog_home_page.dart:688 | if (key == null \|\| key.isEmpty) return null; |
| C0023 | ruta/pantalla | app/lib/app/catalog/catalog_search_page.dart:6 | final class CatalogSearchPage extends StatefulWidget { |
| C0024 | persistencia | app/lib/app/catalog/catalog_search_page.dart:67 | key: const ValueKey('catalog-search-field'), |
| C0025 | persistencia | app/lib/app/catalog/catalog_search_page.dart:73 | key: const ValueKey('catalog-search-button'), |
| C0026 | persistencia | app/lib/app/catalog/catalog_search_page.dart:110 | key: ValueKey( |
| C0027 | ruta/pantalla | app/lib/app/catalog/confirm_completed_status.dart:16 | onPressed: () => Navigator.pop(dialogContext, false), |
| C0028 | ruta/pantalla | app/lib/app/catalog/confirm_completed_status.dart:20 | onPressed: () => Navigator.pop(dialogContext, true), |
| C0029 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:32 | key: const ValueKey('detail-cinematic-header'), |
| C0030 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:84 | key: const ValueKey('detail-back'), |
| C0031 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_header.dart:94 | metadata: metadata, |
| C0032 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_header.dart:103 | metadata: metadata, |
| C0033 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:142 | key: const ValueKey('detail-poster'), |
| C0034 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:152 | key: const ValueKey('detail-header-info'), |
| C0035 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_header.dart:154 | metadata: metadata, |
| C0036 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:195 | key: const ValueKey('detail-more-actions'), |
| C0037 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:208 | key: const ValueKey('detail-poster'), |
| C0038 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:225 | key: const ValueKey('detail-header-info'), |
| C0039 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_header.dart:227 | metadata: metadata, |
| C0040 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:246 | key: const ValueKey('detail-header-synopsis'), |
| C0041 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:378 | key: const ValueKey('detail-play-disabled'), |
| C0042 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:388 | key: const ValueKey('add-to-library'), |
| C0043 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:414 | key: const ValueKey('detail-more-actions'), |
| C0044 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:429 | key: const ValueKey('detail-header-synopsis'), |
| C0045 | persistencia | app/lib/app/catalog/detail/anime_detail_header.dart:565 | key: const ValueKey('detail-library-status'), |
| C0046 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_tab_content.dart:46 | metadata: metadata, |
| C0047 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_tab_content.dart:60 | AnimeDetailTab.information => _InformationTab(metadata: metadata), |
| C0048 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:62 | storageKey: 'detail-cast', |
| C0049 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_tab_content.dart:73 | AnimeDetailTab.gallery => _GalleryTab(metadata: metadata), |
| C0050 | endpoint/cabecera/parámetro | app/lib/app/catalog/detail/anime_detail_tab_content.dart:74 | AnimeDetailTab.titles => _AlternativeTitlesTab(metadata: metadata), |
| C0051 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:76 | storageKey: 'detail-relations', |
| C0052 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:89 | required this.storageKey, |
| C0053 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:94 | final String storageKey; |
| C0054 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:102 | key: PageStorageKey<String>(storageKey), |
| C0055 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:167 | key: const PageStorageKey<String>('detail-episodes-scroll'), |
| C0056 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:331 | key: ValueKey<String>('external-streaming-link-$index'), |
| C0057 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:336 | key: ValueKey<String>('copy-external-streaming-link-$index'), |
| C0058 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:393 | key: ValueKey<String>('episode-card-$number'), |
| C0059 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:515 | key: const ValueKey('progress-seconds'), |
| C0060 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:525 | key: const ValueKey('save-progress'), |
| C0061 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:534 | key: const ValueKey('saved-progress-summary'), |
| C0062 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:568 | key: const PageStorageKey<String>('detail-information-scroll'), |
| C0063 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:646 | key: ValueKey('detail-gallery-empty'), |
| C0064 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:654 | key: const PageStorageKey<String>('detail-gallery-grid'), |
| C0065 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:691 | key: ValueKey('detail-titles-empty'), |
| C0066 | persistencia | app/lib/app/catalog/detail/anime_detail_tab_content.dart:696 | key: const PageStorageKey<String>('detail-titles-scroll'), |
| C0067 | persistencia | app/lib/app/catalog/detail/anime_detail_tabs.dart:42 | key: ValueKey('detail-tab-${tab.name}'), |
| C0068 | ruta/pantalla | app/lib/app/catalog/local_library_page.dart:8 | final class LocalLibraryPage extends StatefulWidget { |
| C0069 | persistencia | app/lib/app/catalog/local_library_page.dart:108 | key: ValueKey('library-item-${item.entry.animeId.value}'), |
| C0070 | persistencia | app/lib/app/catalog/local_library_page.dart:118 | key: ValueKey('library-status-${item.entry.animeId.value}'), |
| C0071 | endpoint/cabecera/parámetro | app/lib/app/home/README.md:42 | - `HomeArtwork` registra fallos de imagen sin URL ni query: solo tipo (`http_403`, `socket`, `decode`…) y host (`HomeArtworkDiagnostics`). |
| C0072 | persistencia | app/lib/app/home/home_artwork_diagnostics.dart:24 | final String key = '$kind@$host'; |
| C0073 | endpoint/cabecera/parámetro | app/lib/app/home/home_card_actions.dart:82 | return Uri.https('anilist.co', '/anime/${id.value}'); |
| C0074 | ruta/pantalla | app/lib/app/home/home_card_actions.dart:210 | Navigator.of(dialogContext).pop(), |
| C0075 | ruta/pantalla | app/lib/app/home/home_card_actions.dart:364 | onTap: () => Navigator.of(context).pop(command), |
| C0076 | ruta/pantalla | app/lib/app/home/home_card_actions.dart:452 | onTap: () => Navigator.pop(context, command), |
| C0077 | endpoint/cabecera/parámetro | app/lib/app/home/home_data.dart:271 | metadata: item, |
| C0078 | persistencia | app/lib/app/home/home_hero.dart:159 | key: ValueKey(anime.externalId ?? anime.title), |
| C0079 | persistencia | app/lib/app/home/home_hero.dart:245 | key: ValueKey(anime.externalId ?? anime.title), |
| C0080 | ruta/pantalla | app/lib/app/home/home_screen.dart:11 | final class HomeScreen extends StatefulWidget { |
| C0081 | persistencia | app/lib/app/home/home_screen.dart:149 | key: const PageStorageKey('home-scroll'), |
| C0082 | persistencia | app/lib/app/home/home_screen.dart:177 | key: _heroVisibilityKey, |
| C0083 | persistencia | app/lib/app/home/home_sections.dart:215 | key: PageStorageKey(widget.id), |
| C0084 | persistencia | app/lib/app/home/home_sections.dart:503 | key: ValueKey( |
| C0085 | persistencia | app/lib/app/home/home_sections.dart:609 | key: anchorKey, |
| C0086 | persistencia | app/lib/app/player/audio_track_selector.dart:37 | key: const ValueKey('player-audio'), |
| C0087 | persistencia | app/lib/app/player/audio_track_selector.dart:44 | key: ValueKey('audio-track-${track.id}'), |
| C0088 | endpoint/cabecera/parámetro | app/lib/app/player/external_subtitle_search_panel.dart:54 | ExternalSubtitleQuery(query: query, languages: const ['en']), |
| C0089 | persistencia | app/lib/app/player/external_subtitle_search_panel.dart:128 | key: const ValueKey<String>('external-subtitle-query'), |
| C0090 | persistencia | app/lib/app/player/external_subtitle_search_panel.dart:140 | key: const ValueKey<String>('external-subtitle-search'), |
| C0091 | persistencia | app/lib/app/player/external_subtitle_search_panel.dart:151 | key: const ValueKey<String>('external-subtitle-status'), |
| C0092 | persistencia | app/lib/app/player/external_subtitle_search_panel.dart:162 | key: ValueKey<String>( |
| C0093 | persistencia | app/lib/app/player/player_demo_panel.dart:54 | key: ValueKey('demo-server-$index'), |
| C0094 | ruta/pantalla | app/lib/app/player/player_demo_panel.dart:70 | onTap: () => Navigator.pop(dialog, index), |
| C0095 | persistencia | app/lib/app/player/player_demo_panel.dart:75 | key: ValueKey('demo-episode-$slot'), |
| C0096 | ruta/pantalla | app/lib/app/player/player_demo_panel.dart:82 | onTap: () => Navigator.pop(dialog, slot), |
| C0097 | ruta/pantalla | app/lib/app/player/player_demo_panel.dart:89 | onPressed: () => Navigator.pop(dialog), |
| C0098 | persistencia | app/lib/app/player/player_demo_panel.dart:109 | key: const ValueKey('episode-previous'), |
| C0099 | persistencia | app/lib/app/player/player_demo_panel.dart:117 | key: const ValueKey('episode-next'), |
| C0100 | persistencia | app/lib/app/player/player_demo_panel.dart:125 | key: const ValueKey('player-episodes'), |
| C0101 | persistencia | app/lib/app/player/player_demo_panel.dart:133 | key: const ValueKey('player-servers'), |
| C0102 | persistencia | app/lib/app/player/player_demo_panel.dart:147 | Text(message, key: const ValueKey('demo-result')), |
| C0103 | persistencia | app/lib/app/player/player_nerd_panel.dart:23 | key: const ValueKey('player-nerd-overlay'), |
| C0104 | persistencia | app/lib/app/player/player_quality_panel.dart:28 | key: ValueKey('player-quality'), |
| C0105 | persistencia | app/lib/app/player/player_quality_panel.dart:40 | key: const ValueKey('player-quality'), |
| C0106 | persistencia | app/lib/app/player/player_quality_panel.dart:54 | key: const ValueKey('video-track-auto'), |
| C0107 | persistencia | app/lib/app/player/player_quality_panel.dart:61 | key: ValueKey('video-track-${track.id}'), |
| C0108 | persistencia | app/lib/app/player/player_subtitle_panel.dart:14 | /// Session preferences survive dismissing the subtitle dialog. |
| C0109 | persistencia | app/lib/app/player/player_subtitle_panel.dart:23 | required this.preferences, |
| C0110 | persistencia | app/lib/app/player/player_subtitle_panel.dart:29 | final PlayerSubtitlePreferences preferences; |
| C0111 | persistencia | app/lib/app/player/player_subtitle_panel.dart:37 | SubtitleStyle get _subtitleStyle => widget.preferences.style; |
| C0112 | persistencia | app/lib/app/player/player_subtitle_panel.dart:38 | set _subtitleStyle(SubtitleStyle value) => widget.preferences.style = value; |
| C0113 | persistencia | app/lib/app/player/player_subtitle_panel.dart:39 | Duration get _subtitleDelay => widget.preferences.delay; |
| C0114 | persistencia | app/lib/app/player/player_subtitle_panel.dart:40 | set _subtitleDelay(Duration value) => widget.preferences.delay = value; |
| C0115 | ruta/pantalla | app/lib/app/player/player_subtitle_panel.dart:83 | onPressed: () => Navigator.of(context).pop(), |
| C0116 | persistencia | app/lib/app/player/player_subtitle_panel.dart:137 | key: const ValueKey<String>('subtitle-track-selector'), |
| C0117 | persistencia | app/lib/app/player/player_subtitle_panel.dart:165 | key: const ValueKey<String>('subtitle-size-selector'), |
| C0118 | persistencia | app/lib/app/player/player_subtitle_panel.dart:182 | key: const ValueKey<String>('subtitle-font-selector'), |
| C0119 | persistencia | app/lib/app/player/player_subtitle_panel.dart:197 | key: const ValueKey<String>('subtitle-color-selector'), |
| C0120 | persistencia | app/lib/app/player/player_subtitle_panel.dart:219 | key: const ValueKey<String>('subtitle-outline-selector'), |
| C0121 | persistencia | app/lib/app/player/player_subtitle_panel.dart:238 | key: const ValueKey<String>('subtitle-outline-color-selector'), |
| C0122 | persistencia | app/lib/app/player/player_subtitle_panel.dart:261 | key: const ValueKey<String>('subtitle-position-selector'), |
| C0123 | persistencia | app/lib/app/player/player_subtitle_panel.dart:280 | key: const ValueKey<String>('subtitle-bold-toggle'), |
| C0124 | persistencia | app/lib/app/player/player_subtitle_panel.dart:287 | key: const ValueKey<String>('subtitle-ass-override-toggle'), |
| C0125 | persistencia | app/lib/app/player/player_subtitle_panel.dart:295 | key: const ValueKey<String>('subtitle-delay-decrease'), |
| C0126 | persistencia | app/lib/app/player/player_subtitle_panel.dart:302 | key: const ValueKey<String>('subtitle-delay-increase'), |
| C0127 | persistencia | app/lib/app/player/player_video_display_panel.dart:15 | key: const ValueKey('player-display-settings'), |
| C0128 | persistencia | app/lib/app/player/player_video_display_panel.dart:40 | key: ValueKey('video-fit-${fit.name}'), |
| C0129 | persistencia | app/lib/app/player/player_video_display_panel.dart:56 | key: ValueKey('video-aspect-${aspect.name}'), |
| C0130 | ruta/pantalla | app/lib/app/player/player_video_display_panel.dart:86 | onPressed: () => Navigator.pop(context), |
| C0131 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:21 | final class ProviderPlaybackRoute extends StatefulWidget { |
| C0132 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:118 | if (mounted && !_disposed) Navigator.of(context).pop(); |
| C0133 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:132 | if (mounted && !_disposed) Navigator.of(context).pop(); |
| C0134 | endpoint/cabecera/parámetro | app/lib/app/player/provider_playback_route.dart:178 | body: Center( |
| C0135 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:212 | onPressed: () => Navigator.of(context).pop(), |
| C0136 | ruta/pantalla | app/lib/app/player/provider_playback_route.dart:269 | ? () => Navigator.of(context).pop() |
| C0137 | persistencia | app/lib/app/player/skip_segment_panel.dart:43 | key: const ValueKey<String>('skip-segment-panel'), |
| C0138 | persistencia | app/lib/app/player/skip_segment_panel.dart:59 | key: const ValueKey<String>('skip-current-segment'), |
| C0139 | persistencia | app/lib/app/player/skip_segment_panel.dart:69 | key: const ValueKey<String>('skip-segment-status'), |
| C0140 | persistencia | app/lib/app/player/skip_segment_panel.dart:74 | key: ValueKey<String>('skip-confirmed'), |
| C0141 | persistencia | app/lib/app/player/source_switch_panel.dart:40 | key: const ValueKey<String>('source-switch-panel'), |
| C0142 | persistencia | app/lib/app/player/source_switch_panel.dart:57 | Text(error, key: const ValueKey<String>('source-switch-error')), |
| C0143 | persistencia | app/lib/app/player/source_switch_panel.dart:66 | key: const ValueKey<String>('switch-source-button'), |
| C0144 | configuración | app/lib/app/player/spike_player_module.dart:266 | SpikePlayerPageOptions.fromEnvironment(Platform.environment), |
| C0145 | ruta/pantalla | app/lib/app/player/spike_player_page.dart:30 | final class SpikePlayerPage extends StatefulWidget { |
| C0146 | ruta/pantalla | app/lib/app/player/spike_player_page.dart:424 | onPressed: () => Navigator.of(context).pop(), |
| C0147 | persistencia | app/lib/app/player/spike_player_page.dart:438 | preferences: _subtitlePreferences, |
| C0148 | endpoint/cabecera/parámetro | app/lib/app/player/spike_player_page.dart:467 | data: ThemeData.dark(useMaterial3: true).copyWith( |
| C0149 | endpoint/cabecera/parámetro | app/lib/app/player/spike_player_page.dart:485 | body: PlayerVideoLayout( |
| C0150 | persistencia | app/lib/app/player/spike_player_page.dart:592 | key: const ValueKey('rewind-10'), |
| C0151 | persistencia | app/lib/app/player/spike_player_page.dart:602 | key: const ValueKey<String>('playback-toggle'), |
| C0152 | persistencia | app/lib/app/player/spike_player_page.dart:621 | key: const ValueKey('forward-10'), |
| C0153 | persistencia | app/lib/app/player/spike_player_page.dart:631 | key: const ValueKey('player-stop'), |
| C0154 | persistencia | app/lib/app/player/spike_player_page.dart:639 | key: const ValueKey('player-mute'), |
| C0155 | persistencia | app/lib/app/player/spike_player_page.dart:732 | key: const ValueKey('player-subtitles'), |
| C0156 | persistencia | app/lib/app/player/spike_player_page.dart:738 | key: const ValueKey('player-nerd'), |
| C0157 | persistencia | app/lib/app/player/spike_player_page.dart:751 | key: const ValueKey<String>('fullscreen-toggle'), |
| C0158 | endpoint/cabecera/parámetro | app/lib/application/catalog/catalog_service.dart:189 | metadata: metadata, |
| C0159 | persistencia | app/lib/application/catalog/catalog_service.dart:281 | key: _progressKey(animeId), |
| C0160 | persistencia | app/lib/application/catalog/catalog_service.dart:303 | ProviderFailureKind.credentialsMissing \|\| |
| C0161 | persistencia | app/lib/application/player/playback_progress_session.dart:78 | key: _key, |
| C0162 | endpoint/cabecera/parámetro | app/lib/application/player/player_demo_session.dart:25 | : Uri.http('127.0.0.1:${ports[server - 1]}', '/episode-$episode.mkv'); |
| C0163 | persistencia | app/lib/application/player/providers/playback_provider_manager.dart:261 | // Dedup key: provider identifier + host id + track language |
| C0164 | persistencia | app/lib/application/player/providers/playback_provider_manager.dart:575 | final String key = '${provider.id.value}:${episode.requestKey}'; |
| C0165 | persistencia | app/lib/application/player/skips/automatic_skip_controller.dart:96 | final String key = '${snapshot.sourceGeneration}:${segment.stableKey}'; |
| C0166 | persistencia | app/lib/core/logger/safe_logger.dart:106 | 'credential', |
| C0167 | persistencia | app/lib/core/logger/safe_logger.dart:121 | final key = entry.key; |
| C0168 | endpoint/cabecera/parámetro | app/lib/data/anilist/README.md:14 | subsequent `X-RateLimit-Limit` headers adjust spacing across client |
| C0169 | endpoint/cabecera/parámetro | app/lib/data/anilist/README.md:39 | during outages ([rate limiting](https://docs.anilist.co/guide/rate-limiting), |
| C0170 | endpoint/cabecera/parámetro | app/lib/data/anilist/README.md:40 | [API considerations](https://docs.anilist.co/guide/considerations)). The API |
| C0171 | endpoint/cabecera/parámetro | app/lib/data/anilist/README.md:43 | ([terms](https://docs.anilist.co/guide/terms-of-use)). AnimeApp's exact |
| C0172 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:12 | const _graphqlEndpoint = 'https://graphql.anilist.co'; |
| C0173 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:139 | data: { |
| C0174 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:149 | _rateLimiter.updateRateLimit(response.headers); |
| C0175 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:178 | data: { |
| C0176 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:192 | _rateLimiter.updateRateLimit(response.headers); |
| C0177 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:221 | data: { |
| C0178 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:239 | _rateLimiter.updateRateLimit(response.headers); |
| C0179 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:260 | headers: const {'Accept': 'application/json'}, |
| C0180 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:272 | return Failure(_rateLimiter.rateLimitError(response.headers)); |
| C0181 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:303 | return Failure(_rateLimiter.rateLimitError(response.headers)); |
| C0182 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:499 | static Duration? _retryAfter(Headers headers) { |
| C0183 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:500 | final String? retryAfter = headers.value('retry-after'); |
| C0184 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:550 | void updateRateLimit(Headers headers) { |
| C0185 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:551 | final String? limitHeader = headers.value('x-ratelimit-limit'); |
| C0186 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:562 | final Duration? retryAfter = AniListClient._retryAfter(headers); |
| C0187 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:568 | RateLimitError rateLimitError(Headers headers) { |
| C0188 | endpoint/cabecera/parámetro | app/lib/data/anilist/anilist_client.dart:570 | AniListClient._retryAfter(headers) ?? const Duration(minutes: 1); |
| C0189 | persistencia | app/lib/data/anilist/drift_anilist_browse_cache.dart:18 | 'SELECT payload, fetched_at FROM anilist_browse_cache WHERE feed_key = ?', |
| C0190 | endpoint/cabecera/parámetro | app/lib/data/aniskip/README.md:3 | El adaptador traduce respuestas de [AniSkip v1](https://api.aniskip.com/api-docs) a rangos del dominio. Se compone con un ID MAL comprobado para el episodio. El identificador local de anime y el de AniList no se usan como sustituto. |
| C0191 | endpoint/cabecera/parámetro | app/lib/data/aniskip/aniskip_client.dart:26 | static const String _baseUrl = 'https://api.aniskip.com/v1'; |
| C0192 | endpoint/cabecera/parámetro | app/lib/data/aniskip/aniskip_client.dart:41 | headers: const {'User-Agent': 'Kongroo/0.1'}, |
| C0193 | persistencia | app/lib/data/aniskip/aniskip_client.dart:49 | String cacheKey(MyAnimeListAnimeId id, PlaybackEpisode episode) => |
| C0194 | persistencia | app/lib/data/aniskip/aniskip_client.dart:57 | final String key = cacheKey(malAnimeId, episode); |
| C0195 | endpoint/cabecera/parámetro | app/lib/data/aniskip/aniskip_client.dart:100 | body: body, |
| C0196 | endpoint/cabecera/parámetro | app/lib/data/aniskip/aniskip_response_cache.dart:77 | body: decoded['body']! as String, |
| C0197 | endpoint/cabecera/parámetro | app/lib/data/kitsu/README.md:12 | - Miniaturas `http://` se descartan; entradas sin número válido (<1) se omiten sin invalidar la página. |
| C0198 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:23 | baseUrl: 'https://kitsu.io/api/edge', |
| C0199 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:26 | headers: const {'Accept': 'application/vnd.api+json'}, |
| C0200 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:68 | queryParameters: { |
| C0201 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:95 | queryParameters: { |
| C0202 | endpoint/cabecera/parámetro | app/lib/data/kitsu/kitsu_episode_index.dart:176 | thumbnailUrl: thumbnail is String && thumbnail.startsWith('https://') |
| C0203 | persistencia | app/lib/data/local_db/app_database.dart:40 | int get schemaVersion => 9; |
| C0204 | persistencia | app/lib/data/local_db/app_database.dart:43 | CREATE TABLE anilist_detail_cache ( |
| C0205 | persistencia | app/lib/data/local_db/app_database.dart:44 | media_id INTEGER PRIMARY KEY, |
| C0206 | persistencia | app/lib/data/local_db/app_database.dart:51 | CREATE TABLE anilist_browse_cache ( |
| C0207 | persistencia | app/lib/data/local_db/app_database.dart:52 | feed_key TEXT PRIMARY KEY, |
| C0208 | persistencia | app/lib/data/local_db/app_database.dart:90 | CREATE TABLE library_entries_new ( |
| C0209 | persistencia | app/lib/data/local_db/app_database.dart:91 | anime_id TEXT NOT NULL PRIMARY KEY |
| C0210 | persistencia | app/lib/data/local_db/drift_playback_progress_repository.dart:59 | key: ProgressKey( |
| C0211 | persistencia | app/lib/data/local_db/drift_playback_progress_repository.dart:95 | key: ProgressKey( |
| C0212 | persistencia | app/lib/data/local_db/tables/anime_identity_entries.dart:5 | TextColumn get animeId => text().named('anime_id')(); |
| C0213 | persistencia | app/lib/data/local_db/tables/anime_identity_entries.dart:7 | DateTimeColumn get createdAtUtc => dateTime().named('created_at_utc')(); |
| C0214 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:9 | TextColumn get sourceAnimeId => text() |
| C0215 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:18 | TextColumn get targetAnimeId => text() |
| C0216 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:26 | TextColumn get relationshipKind => text().named('relationship_kind')(); |
| C0217 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:28 | TextColumn get evidence => text().named('evidence')(); |
| C0218 | persistencia | app/lib/data/local_db/tables/anime_identity_relationships.dart:30 | DateTimeColumn get linkedAtUtc => dateTime().named('linked_at_utc')(); |
| C0219 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:8 | TextColumn get providerId => text().named('provider_id')(); |
| C0220 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:10 | TextColumn get externalId => text().named('external_id')(); |
| C0221 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:12 | TextColumn get animeId => text() |
| C0222 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:20 | TextColumn get evidence => text().named('evidence')(); |
| C0223 | persistencia | app/lib/data/local_db/tables/external_anime_identifiers.dart:22 | DateTimeColumn get linkedAtUtc => dateTime().named('linked_at_utc')(); |
| C0224 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:5 | TextColumn get slot => text().named('slot')(); |
| C0225 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:7 | TextColumn get searchQuery => text().named('search_query')(); |
| C0226 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:9 | IntColumn get page => integer().named('page')(); |
| C0227 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:11 | IntColumn get perPage => integer().named('per_page')(); |
| C0228 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:13 | TextColumn get resultJson => text().named('result_json')(); |
| C0229 | persistencia | app/lib/data/local_db/tables/latest_anime_search.dart:15 | DateTimeColumn get cachedAt => dateTime().named('cached_at')(); |
| C0230 | persistencia | app/lib/data/local_db/tables/library_entries.dart:8 | TextColumn get animeId => text() |
| C0231 | persistencia | app/lib/data/local_db/tables/library_entries.dart:16 | DateTimeColumn get addedAtUtc => dateTime().named('added_at_utc')(); |
| C0232 | persistencia | app/lib/data/local_db/tables/library_entries.dart:18 | TextColumn get status => |
| C0233 | persistencia | app/lib/data/local_db/tables/library_entries.dart:25 | String get tableName => 'library_entries'; |
| C0234 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:4 | TextColumn get contentId => text().named('content_id')(); |
| C0235 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:5 | TextColumn get episodeId => text().named('episode_id')(); |
| C0236 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:6 | IntColumn get positionMs => integer().named('position_ms')(); |
| C0237 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:7 | IntColumn get durationMs => integer().named('duration_ms').nullable()(); |
| C0238 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:8 | DateTimeColumn get updatedAtUtc => dateTime().named('updated_at_utc')(); |
| C0239 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:9 | TextColumn get completion => text().named('completion')(); |
| C0240 | persistencia | app/lib/data/local_db/tables/playback_progress_entries.dart:10 | IntColumn get revision => |
| C0241 | persistencia | app/lib/data/local_db/tables/progress_documents.dart:5 | TextColumn get documentKey => text().named('document_key')(); |
| C0242 | persistencia | app/lib/data/local_db/tables/progress_documents.dart:7 | TextColumn get payloadJson => text().named('payload_json')(); |
| C0243 | persistencia | app/lib/data/local_db/tables/progress_documents.dart:9 | DateTimeColumn get updatedAt => dateTime().named('updated_at')(); |
| C0244 | persistencia | app/lib/data/local_db/tables/settings_entries.dart:5 | TextColumn get settingKey => text().named('setting_key')(); |
| C0245 | persistencia | app/lib/data/local_db/tables/settings_entries.dart:7 | TextColumn get valueJson => text().named('value_json')(); |
| C0246 | persistencia | app/lib/data/local_db/tables/settings_entries.dart:9 | DateTimeColumn get updatedAt => dateTime().named('updated_at')(); |
| C0247 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:31 | ninguno de esos headers. Las pruebas usan placeholders que nunca salen del |
| C0248 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:44 | `search` forma `GET /api/v1/subtitles`, omite filtros vacíos, normaliza texto, |
| C0249 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:48 | si conservan HTTPS, puerto 443, la ruta `/api/v1/subtitles` y uno de los hosts |
| C0250 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:58 | `vtt`. Solicita `POST /api/v1/download`; la cuota puede consumirse al solicitar |
| C0251 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:112 | permitidos/rechazados, multipart, descarga SRT, aislamiento de headers, URL |
| C0252 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:130 | Consultadas el 2026-11-11: [referencia API OpenSubtitles v1](https://ai.opensubtitles.com/api-docs). |
| C0253 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/README.md:133 | cuota y muestra enlaces `https://www.opensubtitles.com/download/...`. Esto |
| C0254 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:16 | /// validated separately; credentials are sent only to the API origin. |
| C0255 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:47 | static const String _apiBase = 'https://api.opensubtitles.com/api/v1'; |
| C0256 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:78 | key = await _readApiKey(); |
| C0257 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:82 | if (key == null) { |
| C0258 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:124 | .replace(queryParameters: stringParams); |
| C0259 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:129 | headers: _headers(key), |
| C0260 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:136 | final String? location = response.headers.value( |
| C0261 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:190 | key = await _readApiKey(); |
| C0262 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:194 | if (key == null) { |
| C0263 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:202 | data: <String, Object>{ |
| C0264 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:207 | headers: await _downloadHeaders(key), |
| C0265 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:325 | final String? location = response.headers.value( |
| C0266 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:346 | retryAfter: _parseRetryAfter(response.headers.value('retry-after')), |
| C0267 | persistencia | app/lib/data/opensubtitles/opensubtitles_client.dart:436 | final String? key = await _apiKey(); |
| C0268 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:442 | final Map<String, String> headers = _headers(key); |
| C0269 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:445 | headers['Authorization'] = 'Bearer ${token.trim()}'; |
| C0270 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:447 | return headers; |
| C0271 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:450 | Map<String, String> _headers(String key) => <String, String>{ |
| C0272 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:452 | 'User-Agent': _userAgent, |
| C0273 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:461 | headers: const {'Accept': 'application/json'}, |
| C0274 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:543 | uri.path == '/api/v1/subtitles'; |
| C0275 | endpoint/cabecera/parámetro | app/lib/data/opensubtitles/opensubtitles_client.dart:580 | final String? retry = response.headers.value('retry-after'); |
| C0276 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:30 | `play`, `pause`, `seek` y `stop` traducen operaciones nativas. `stop` descarga el medio y deja reusable el Player; el adaptador conserva la URI que se abrió correctamente y marca el snapshot `stopped`, sin destruir Player ni VideoController. El siguiente `play` revalida el archivo y lo abre de nuevo en el mismo Player con reproducción desde el inicio. Si la validación/reapertura falla, la operación propaga el error y mantiene la fuente y el estado stopped para permitir reintentar. Play tras Pause solo llama a `Player.play()` y conserva la posición. La prueba libmpv cubre ambos contratos, ciclos Stop→Play repetidos, archivo retenido ausente y recuperación. La reapertura de la misma URI en Linux aún requiere confirmación de imagen en compositor: upstream mantiene abierta la issue [#957](https://github.com/media-kit/media-kit/issues/957), que informa pantalla negra para una secuencia similar; el test nativo comprueba estado/avance, no píxeles presentados. `dispose` hace el engine no utilizable y delega a `ActivePlayerLease`: llamadas concurrentes comparten Future. El lease representa solo la propiedad del Player nativo: se libera cuando `Player.dispose()` termina, aunque luego falle una limpieza auxiliar Dart. El engine reintenta de forma idempotente la cancelación de subscriptions/cierre del stream mediante su propio `dispose()`; no libera un Player nativo incierto. El dispose nativo es un intento único porque media_kit 1.2.6 cambia su indicador `disposed` antes de completar todo el teardown. Si ese Future falla, se conserva el lease y no se repite la operación. El error tipado `MediaKitSpikeEngineDisposeFailure` informa `nativePlayerStillOwned`; los fallos de subscriptions o del stream se marcan como auxiliares y no conservan el lease si el dispose nativo terminó. Un error de `Player.dispose()` también cierra el stream de snapshots; una prueba con fallo inyectado confirma `onDone`, aunque no simula internamente un fallo parcial de libmpv. Esta cuarentena requiere reiniciar el proceso antes de crear otro Player tras fallo nativo. `retryPendingDispose()` atiende exclusivamente un lease nativo huérfano o retenido y propaga su fallo. Si el Player ya se liberó y solo falló una etapa auxiliar, se reintenta llamando `dispose()` sobre el mismo engine mientras siga accesible. No desplaza un engine activo antes de dispose. `Player.stream.error` se publica como texto fijo sin rutas/detalles arbitrarios. Los errores de reproducción persisten a través de cambios no relacionados y solo se limpian en una recuperación de `open` sin un nuevo error. |
| C0277 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:210 | Consultadas el 2026-11-10: [media_kit 1.2.6](https://pub.dev/packages/media_kit/versions/1.2.6) |
| C0278 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:213 | de estilo. La [referencia oficial de opciones mpv](https://github.com/mpv-player/mpv/blob/master/DOCS/man/options.rst) |
| C0279 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:300 | - [`media-kit#1450`](https://github.com/media-kit/media-kit/issues/1450): en HLS, |
| C0280 | endpoint/cabecera/parámetro | app/lib/data/player/engine/README.md:303 | - [`mpv#13120`](https://github.com/mpv-player/mpv/issues/13120): un `.vtt` |
| C0281 | configuración | app/lib/data/player/engine/media_codec_support_linux.dart:37 | }) : _environment = environment ?? Platform.environment, |
| C0282 | persistencia | app/lib/data/player/engine/media_kit_spike_engine.dart:184 | entry.key: List<ProviderSubtitle>.unmodifiable(entry.value), |
| C0283 | endpoint/cabecera/parámetro | app/lib/data/player/providers/README.md:69 | \| miruro-catalog \| 100 \| 403 Cloudflare \| Frontend actual identificado; `/health` responde, pero catálogo `/api/config` devuelve 403 con UA propio \| **N1 externo** \| La interfaz de catálogo/playback no entregó respuesta; health no prueba catálogo \| Solo `.cx`; hace falta contrato de API externa o habilitación del operador \| |
| C0284 | endpoint/cabecera/parámetro | app/lib/data/player/providers/README.md:121 | rutas same-origin. `GET /health` devuelve JSON de salud/versionado. La ruta |
| C0285 | endpoint/cabecera/parámetro | app/lib/data/player/providers/README.md:122 | conocida `GET /api/config` devuelve 403 incluso con UA propio, por lo que no |
| C0286 | persistencia | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:30 | /// 2. request key = partB XOR mask (32 bytes). |
| C0287 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:36 | ///    `x-aa-boot` headers. |
| C0288 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:78 | }) : apiOrigin = apiOrigin ?? Uri.https('api.mkissa.net'), |
| C0289 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:123 | 'Referer': 'https://mkissa.to/', |
| C0290 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:124 | 'Origin': 'https://mkissa.to', |
| C0291 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:130 | 'Referer': 'https://mkissa.to/', |
| C0292 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:131 | 'User-Agent': _http.userAgent, |
| C0293 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:241 | headers: _apiHeaders, |
| C0294 | persistencia | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:375 | /// Bootstraps the per-epoch key: HMAC boot token over the current epoch |
| C0295 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:393 | queryParameters: { |
| C0296 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:400 | headers: PlaybackRequestHeaders({ |
| C0297 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:401 | 'Referer': 'https://mkissa.to/', |
| C0298 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:402 | 'Origin': 'https://mkissa.to', |
| C0299 | persistencia | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:438 | final Uint8List key = Uint8List(32); |
| C0300 | persistencia | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:442 | return (epoch: epochValue, key: key); |
| C0301 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:478 | queryParameters: {'variables': variables, 'extensions': extensions}, |
| C0302 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:484 | headers: PlaybackRequestHeaders({ |
| C0303 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:485 | 'Referer': 'https://mkissa.to/', |
| C0304 | endpoint/cabecera/parámetro | app/lib/data/player/providers/allanime/allanime_playback_provider.dart:486 | 'Origin': 'https://mkissa.to', |
| C0305 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/README.md:6 | [fuente](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnimeAv1Provider.kt), |
| C0306 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/README.md:7 | [licencia](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/LICENSE). |
| C0307 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:18 | : origin = origin ?? Uri.https('animeav1.com') { |
| C0308 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:77 | .replace(queryParameters: search == null ? null : {'search': search}); |
| C0309 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:82 | headers: PlaybackRequestHeaders({ |
| C0310 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:83 | 'Referer': origin.resolve('/').toString(), |
| C0311 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart:321 | 'Referer': origin.resolve('/').toString(), |
| C0312 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:26 | }) : origin = origin ?? Uri.https('www.animegg.org') { |
| C0313 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:81 | PlaybackRequestHeaders({'Referer': origin.resolve('/').toString()}); |
| C0314 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:86 | 'Referer': origin.resolve('/').toString(), |
| C0315 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:87 | 'User-Agent': _http.userAgent, |
| C0316 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:122 | origin.resolve('/search/').replace(queryParameters: {'q': title}), |
| C0317 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:200 | headers: _referer, |
| C0318 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:214 | headers: _referer, |
| C0319 | endpoint/cabecera/parámetro | app/lib/data/player/providers/animegg/animegg_playback_provider.dart:271 | headers: _referer, |
| C0320 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:23 | }) : origin = origin ?? Uri.https('anizone.to') { |
| C0321 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:41 | r'"src":"(https://[^"\\]+?\.m3u8[^"\\]*)"', |
| C0322 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:50 | r'"language":"([a-z-]{2,8})"[^{}]*?"file":"(https://[^"\\]+?\.vtt)"', |
| C0323 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:54 | r'"file":"(https://[^"\\]+?\.vtt)"', |
| C0324 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:96 | origin.resolve('/anime').replace(queryParameters: {'search': title}), |
| C0325 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:168 | headers: PlaybackRequestHeaders({ |
| C0326 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:169 | 'Referer': origin.resolve('/anime/${episode.sourceAnimeId}').toString(), |
| C0327 | endpoint/cabecera/parámetro | app/lib/data/player/providers/anizone/anizone_playback_provider.dart:214 | 'Referer': origin.resolve('/').toString(), |
| C0328 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:25 | if (_http.allowedHosts.contains(uri.host)) return _http; |
| C0329 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:67 | final headers = candidate.requestHeaders; |
| C0330 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:71 | headers: headers, |
| C0331 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:89 | headers: headers, |
| C0332 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:105 | 'User-Agent': _http.userAgent, |
| C0333 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:110 | headers: mediaHeaders, |
| C0334 | endpoint/cabecera/parámetro | app/lib/data/player/providers/hosts/voe_video_host_resolver.dart:143 | r'''window\.location\.href\s*=\s*["'](https://[^"'<>]{1,2048})["']''', |
| C0335 | endpoint/cabecera/parámetro | app/lib/data/player/providers/html_playback_parsers.dart:91 | if (value.startsWith('http://') \|\| value.startsWith('https://')) { |
| C0336 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:230 | scheme: 'https', host: hostKey, path: '/placeholder'), |
| C0337 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:364 | // Per OC-07.8: https://jkanime.net/<slug>/<n>/ |
| C0338 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:370 | 'https://jkanime.net/$slug/$episodeNumber'; |
| C0339 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:378 | headers: { |
| C0340 | endpoint/cabecera/parámetro | app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart:379 | 'User-Agent': |
| C0341 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/README.md:33 | [sanilili/desktoprepo1](https://github.com/sanilili/desktoprepo1), commit |
| C0342 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:36 | static final Uri defaultOrigin = Uri.https('megaplay.buzz'); |
| C0343 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:240 | final headers = PlaybackRequestHeaders({'Referer': 'https://hianimes.re/'}); |
| C0344 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:244 | headers: headers, |
| C0345 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:268 | headers: headers, |
| C0346 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:283 | headers: PlaybackRequestHeaders({'Referer': embed.toString()}), |
| C0347 | persistencia | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:329 | final key = List<int>.filled(32, 0); |
| C0348 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:405 | final headers = PlaybackRequestHeaders({ |
| C0349 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:406 | 'Referer': origin.resolve('/').toString(), |
| C0350 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:407 | 'Origin': origin.origin, |
| C0351 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:408 | 'User-Agent': _http.userAgent, |
| C0352 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:415 | origin.resolve('/$route').replace(query: 'id=$fileId&id=$fileId'), |
| C0353 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:417 | headers: PlaybackRequestHeaders({ |
| C0354 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:418 | 'Referer': origin.resolve('/').toString(), |
| C0355 | endpoint/cabecera/parámetro | app/lib/data/player/providers/megaplay/megaplay_playback_provider.dart:468 | requestHeaders: headers, |
| C0356 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:12 | \| `/api/config` \| `200 application/json`, 6.798 B \| |
| C0357 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:18 | \| Proxy loopback \| `http://127.0.0.1:<port>/media/<id>`; libmpv `0:24:09.629955`, `PLAYING`, `SEEK 0:00:40.166171` \| |
| C0358 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:31 | ella, `/api/config` responde `403` con block page de Cloudflare; `same-site` |
| C0359 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:36 | (`.to`, `.bz`, `.cx`, `.tv`). Por HTTP/1.1 devuelve `403`; `/health` responde |
| C0360 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:42 | [`stepbrobd/miruro`](https://github.com/stepbrobd/miruro/tree/408259661cc7335bafc99ef6e9b7f4a588192a04) |
| C0361 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:61 | \| `miruro_catalog_api.dart` \| Rutas `/api/…`, cabeceras de contexto, mapeo de estado a `PlaybackProviderFailureKind`, `probeHealth()` por `/health` (HTTP/1.1 basta). \| |
| C0362 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:63 | \| `miruro_media_proxy.dart` \| Proxy loopback: publica cada fuente como `http://127.0.0.1:<port>/media/<id>`, aplica cabeceras, reenvía `Range`, preserva `206`/`Content-Range` y reescribe playlists HLS. \| |
| C0363 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:82 | \| `GET /health` \| 200 \| JSON, `version` 1.15.9 \| |
| C0364 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:84 | \| `GET /api/config` \| 200 \| JSON \| |
| C0365 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:85 | \| `GET /api/v1/anime?q=…&limit=…&sort=-popularity` \| 200 \| XOR+gzip \| |
| C0366 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:86 | \| `GET /api/v1/anime/<title-id>/episodes?limit=10000` \| 200 \| XOR+gzip \| |
| C0367 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:87 | \| `GET /api/v1/anime/<title-id>/episodes/<n>/play` \| 200 \| XOR+gzip \| |
| C0368 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/README.md:165 | - 2026-11-19: investigación del frontend/backend; `/api/config` devolvía 403 y |
| C0369 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:17 | /// because the backend serves it only over HTTP/2, and `/health` through |
| C0370 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:60 | final Uri uri = Uri.https(host, '/api/$path', query); |
| C0371 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:68 | headers: <String, String>{ |
| C0372 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:72 | 'referer': 'https://$host/', |
| C0373 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:73 | 'origin': 'https://$host', |
| C0374 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:116 | contentType: response.headers['content-type'], |
| C0375 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:124 | /// `/health` is served by the same host over HTTP/1.1, so it exercises the |
| C0376 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_api.dart:139 | Uri.https(host, '/health'), |
| C0377 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:83 | key: entry.key, |
| C0378 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:180 | provider.key: provider, |
| C0379 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:193 | final String? key = _text(provider?['provider']); |
| C0380 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:194 | if (provider == null \|\| key == null \|\| !_validKey(key)) continue; |
| C0381 | persistencia | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:216 | id: 'miruro:$titleId:${episode.episodeNumber}:$key:$trackName', |
| C0382 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:294 | final String? referer = _safeReferer(server['headers']); |
| C0383 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:311 | : PlaybackRequestHeaders({'Referer': referer}), |
| C0384 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:320 | final Map<String, dynamic>? headers = _object(rawHeaders); |
| C0385 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:321 | if (headers == null) return null; |
| C0386 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_parser.dart:322 | for (final MapEntry<String, dynamic> entry in headers.entries) { |
| C0387 | configuración | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:94 | 'flag=${Platform.environment['KONGROO_ENABLE_MIRURO_BACKEND'] ?? 'not-set'}'); |
| C0388 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:194 | body: body, |
| C0389 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:266 | query: <String, String>{'anilist_id_in': '$anilistId', 'limit': '100'}, |
| C0390 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_catalog_playback_provider.dart:323 | query: <String, String>{ |
| C0391 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:12 | required this.headers, |
| C0392 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:17 | final Map<String, String> headers; |
| C0393 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:25 | required Map<String, String> headers, |
| C0394 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:34 | /// The same host answers `/health` over HTTP/1.1, so this is not a network, |
| C0395 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:60 | required Map<String, String> headers, |
| C0396 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:71 | headers: headers, |
| C0397 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:144 | required Map<String, String> headers, |
| C0398 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:157 | for (final MapEntry<String, String> entry in headers.entries) |
| C0399 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:183 | case HeadersStreamMessage(:final List<Header> headers): |
| C0400 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:184 | for (final Header header in headers) { |
| C0401 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:217 | headers: Map<String, String>.unmodifiable(responseHeaders), |
| C0402 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_http2_client.dart:218 | body: body.takeBytes(), |
| C0403 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:11 | /// Every resolved stream is published as `http://127.0.0.1:<port>/media/<id>`, |
| C0404 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:45 | /// Origin the engine must allowlist, e.g. `http://127.0.0.1:45123`. |
| C0405 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:46 | String get origin => 'http://127.0.0.1:${_server.port}'; |
| C0406 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:49 | Uri expose(Uri upstream, {PlaybackRequestHeaders? headers}) { |
| C0407 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:51 | _entries[id] = _MiruroMediaEntry(upstream, headers); |
| C0408 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:102 | final Map<String, String> headers = |
| C0409 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:103 | entry.headers?.values ?? const <String, String>{}; |
| C0410 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:104 | headers.forEach(upstream.headers.set); |
| C0411 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:105 | upstream.headers.set(HttpHeaders.acceptEncodingHeader, 'identity'); |
| C0412 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:106 | final String? range = request.headers.value(HttpHeaders.rangeHeader); |
| C0413 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:107 | if (range != null) upstream.headers.set(HttpHeaders.rangeHeader, range); |
| C0414 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:112 | final String? contentType = response.headers.value( |
| C0415 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:126 | final String? value = response.headers.value(name); |
| C0416 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:127 | if (value != null) request.response.headers.set(name, value); |
| C0417 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:131 | request.response.headers.set(HttpHeaders.contentTypeHeader, contentType); |
| C0418 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:133 | request.response.headers.set( |
| C0419 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:150 | request.response.headers.contentType = ContentType( |
| C0420 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:175 | // `#EXT-X-KEY:...URI="https://..."` and `#EXT-X-MAP:URI="..."` |
| C0421 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:216 | request.response.headers.contentType = ContentType.text; |
| C0422 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:222 | _MiruroMediaEntry(this.upstream, this.headers) |
| C0423 | endpoint/cabecera/parámetro | app/lib/data/player/providers/miruro/miruro_media_proxy.dart:226 | final PlaybackRequestHeaders? headers; |
| C0424 | endpoint/cabecera/parámetro | app/lib/data/player/providers/mock/mock_playback_provider.dart:232 | Uri.https('${id.value}.mock.invalid', '/stream/$serverId'), |
| C0425 | persistencia | app/lib/data/player/providers/public_episode_provider.dart:35 | for (final MapEntry(key: slug, value: title) in titlesBySlug.entries) |
| C0426 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:24 | this.allowedHosts, { |
| C0427 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:31 | final Set<String> allowedHosts; |
| C0428 | persistencia | app/lib/data/player/providers/public_playback_http.dart:38 | /// Cloudflare's `cf-ray` is a diagnostic identifier (not a credential) that |
| C0429 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:70 | PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(), |
| C0430 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:77 | headers: headers, |
| C0431 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:80 | target.port == 443 && allowedHosts.contains(target.host), |
| C0432 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:92 | PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(), |
| C0433 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:102 | headers: headers, |
| C0434 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:105 | target.port == 443 && allowedHosts.contains(target.host), |
| C0435 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:117 | PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(), |
| C0436 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:123 | headers: headers, |
| C0437 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:126 | target.port == 443 && allowedHosts.contains(target.host), |
| C0438 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:129 | /// Verifies the selected host's public response headers before offering it. |
| C0439 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:135 | required PlaybackRequestHeaders headers, |
| C0440 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:142 | headers: headers, |
| C0441 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:151 | PlaybackRequestHeaders headers = const PlaybackRequestHeaders.empty(), |
| C0442 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:216 | data: jsonBody, |
| C0443 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:222 | headers: { |
| C0444 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:228 | 'User-Agent': userAgent, |
| C0445 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:230 | ...headers.values, |
| C0446 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:236 | final String? location = response.headers['location']?.firstOrNull; |
| C0447 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:240 | response.headers['cf-mitigated']?.firstOrNull != 'challenge') { |
| C0448 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:258 | final String? declaredServer = response.headers['server']?.firstOrNull; |
| C0449 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:264 | final String? mime = response.headers['content-type']?.firstOrNull |
| C0450 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:277 | response.headers['cf-mitigated']?.firstOrNull == 'challenge'; |
| C0451 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:281 | ? _retryAfter(response.headers['retry-after']?.firstOrNull, now) ?? |
| C0452 | endpoint/cabecera/parámetro | app/lib/data/player/providers/public_playback_http.dart:387 | 'cf_ray=${_cloudflareRayId(response.headers['cf-ray']?.firstOrNull) ?? "unknown"}', |
| C0453 | persistencia | app/lib/data/player/providers/registry/provider_spec.dart:70 | _specs.firstWhere((spec) => spec.key == k, orElse: () => null); |
| C0454 | endpoint/cabecera/parámetro | app/lib/data/player/providers/user_sources/README.md:13 | {"anime":"anilist:21","episode":1,"url":"https://ejemplo.org/video.m3u8","language":"ja","quality":"720p"} |
| C0455 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/README.md:14 | Fuentes [AniList](https://anilist.co/anime/6654), |
| C0456 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/README.md:15 | [Wikidata](https://www.wikidata.org/wiki/Q2054133), |
| C0457 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/README.md:16 | [archivo y licencia](https://commons.wikimedia.org/wiki/File:Kouichi_Jun%27ichi_-_Namakura_Gatana_%281917%29_-_4-minute_restored_version.webm) |
| C0458 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/README.md:17 | y [MediaWiki Action API](https://www.mediawiki.org/wiki/API:Query). |
| C0459 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:97 | final Uri request = Uri.https('commons.wikimedia.org', '/w/api.php', { |
| C0460 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/wikimedia_anime_provider.dart:151 | 'User-Agent': wikimediaUserAgent, |
| C0461 | endpoint/cabecera/parámetro | app/lib/data/player/providers/wikimedia/wikimedia_identity.dart:3 | 'Kongroo/1.0.0 (https://github.com/kurogamishuen15/AnimeApp-Dev/issues)'; |
| C0462 | persistencia | app/lib/data/secure_storage/README.md:1 | # Secure credential storage |
| C0463 | persistencia | app/lib/data/secure_storage/README.md:7 | database are not used for credentials. |
| C0464 | persistencia | app/lib/data/secure_storage/README.md:19 | platform validation items. No credentials, OAuth callback flow, account |
| C0465 | persistencia | app/lib/data/secure_storage/flutter_secure_credential_store.dart:3 | import '../../domain/auth/secure_credential_store.dart'; |
| C0466 | persistencia | app/lib/data/secure_storage/flutter_secure_credential_store.dart:22 | return Success(await _storage.read(key: _accessTokenKey)); |
| C0467 | persistencia | app/lib/data/secure_storage/flutter_secure_credential_store.dart:34 | await _storage.write(key: _accessTokenKey, value: accessToken); |
| C0468 | persistencia | app/lib/data/secure_storage/flutter_secure_credential_store.dart:44 | await _storage.delete(key: _accessTokenKey); |
| C0469 | persistencia | app/lib/data/secure_storage/flutter_secure_storage_api.dart:12 | Future<String?> read({required String key}) => _storage.read(key: key); |
| C0470 | persistencia | app/lib/data/secure_storage/flutter_secure_storage_api.dart:16 | _storage.write(key: key, value: value); |
| C0471 | persistencia | app/lib/data/secure_storage/flutter_secure_storage_api.dart:19 | Future<void> delete({required String key}) => _storage.delete(key: key); |
| C0472 | persistencia | app/lib/data/secure_storage/secure_storage_api.dart:4 | /// failure behavior to be exercised without accessing user credentials. |
| C0473 | persistencia | app/lib/domain/README.md:20 | \| `auth/secure_credential_store.dart` \| Puerto para CRUD de credenciales; adaptador concreto en `data/secure_storage`. \| |
| C0474 | persistencia | app/lib/domain/auth/README.md:8 | The contract supports the local credential lifecycle required by FR-06, but |
| C0475 | persistencia | app/lib/domain/auth/secure_credential_store.dart:6 | /// fall back to ordinary preferences, files, or the settings database. |
| C0476 | ruta/pantalla | app/lib/domain/catalog/episode_index_provider.dart:9 | final class EpisodeIndexPage { |
| C0477 | persistencia | app/lib/domain/catalog/provider_result.dart:5 | credentialsMissing, |
| C0478 | persistencia | app/lib/domain/catalog/provider_result.dart:46 | ProviderFailureKind.credentialsMissing \|\| |
| C0479 | persistencia | app/lib/domain/player/providers/anime_identity.dart:30 | /// Deterministic key for bounded caches; contains no credentials or URLs. |
| C0480 | persistencia | app/lib/domain/player/providers/anime_identity.dart:31 | String get cacheKey { |
| C0481 | persistencia | app/lib/domain/player/providers/episode_source.dart:84 | String get cacheKey => |
| C0482 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:295 | /// no credential content), and two non-secret protocol headers used by public |
| C0483 | persistencia | app/lib/domain/player/providers/playback_source.dart:295 | /// no credential content), and two non-secret protocol headers used by public |
| C0484 | persistencia | app/lib/domain/player/providers/playback_source.dart:296 | /// catalog APIs (values are strictly validated; they never carry credentials or |
| C0485 | persistencia | app/lib/domain/player/providers/playback_source.dart:297 | /// cookies). Cookies, authorization credentials, and arbitrary caller-supplied |
| C0486 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:298 | /// headers are rejected. |
| C0487 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:304 | 'referer' => 'Referer', |
| C0488 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:305 | 'origin' => 'Origin', |
| C0489 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:306 | 'user-agent' => 'User-Agent', |
| C0490 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:307 | 'sec-fetch-site' => 'Sec-Fetch-Site', |
| C0491 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:319 | if (name == 'User-Agent') { |
| C0492 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:326 | if (name == 'Sec-Fetch-Site') { |
| C0493 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:365 | if (name == 'Origin' && uri.path.isNotEmpty && uri.path != '/') { |
| C0494 | endpoint/cabecera/parámetro | app/lib/domain/player/providers/playback_source.dart:368 | validated[name] = name == 'Origin' ? uri.origin : uri.toString(); |
| C0495 | persistencia | app/lib/domain/progress/checkpoint_coordinator.dart:54 | key: key, |
| C0496 | persistencia | app/lib/domain/progress/content_identity.dart:24 | String get storageKey => |
| C0497 | configuración | app/lib/main.dart:29 | Platform.environment['KONGROO_ENABLE_MIRURO_BACKEND'] != '0'; |
| C0498 | configuración | app/lib/main.dart:37 | enableMegaPlay: Platform.environment['KONGROO_ENABLE_MEGAPLAY'] != '0', |
| C0499 | configuración | app/lib/main.dart:38 | enableAnimeAv1: Platform.environment['KONGROO_ENABLE_ANIMEAV1'] != '0', |
| C0500 | configuración | app/lib/main.dart:39 | enableAllAnime: Platform.environment['KONGROO_ENABLE_ALLANIME'] != '0', |
| C0501 | configuración | app/lib/main.dart:40 | enableAniZone: Platform.environment['KONGROO_ENABLE_ANIZONE'] != '0', |
| C0502 | configuración | app/lib/main.dart:41 | enableAnimeGg: Platform.environment['KONGROO_ENABLE_ANIMEGG'] != '0', |
| C0503 | configuración | app/lib/main.dart:42 | enableWikimedia: Platform.environment['KONGROO_ENABLE_WIKIMEDIA'] == '1', |
| C0504 | configuración | app/lib/main.dart:61 | final markerPath = Platform.environment['ANIMEAPP_FIRST_FRAME_MARKER']; |
| C0505 | endpoint/cabecera/parámetro | app/lib/main.dart:109 | /// Entrypoint for the health-probe isolate. Each iteration probes /health |
| C0506 | configuración | app/lib/main.dart:131 | final String? path = Platform.environment['KONGROO_USER_SOURCES']; |
| C0507 | configuración | app/lib/main.dart:150 | final String? requestedPath = Platform.environment['KONGROO_DATABASE_PATH']; |
| C0508 | configuración | app/lib/main.dart.bak:21 | Platform.environment['KONGROO_ENABLE_MIRURO'] != '0' && |
| C0509 | configuración | app/lib/main.dart.bak:22 | Platform.environment['KONGROO_ENABLE_MIRURO_BACKEND'] != '0'; |
| C0510 | configuración | app/lib/main.dart.bak:30 | enableMegaPlay: Platform.environment['KONGROO_ENABLE_MEGAPLAY'] != '0', |
| C0511 | configuración | app/lib/main.dart.bak:31 | enableAnimeAv1: Platform.environment['KONGROO_ENABLE_ANIMEAV1'] != '0', |
| C0512 | configuración | app/lib/main.dart.bak:32 | enableAllAnime: Platform.environment['KONGROO_ENABLE_ALLANIME'] != '0', |
| C0513 | configuración | app/lib/main.dart.bak:33 | enableAniZone: Platform.environment['KONGROO_ENABLE_ANIZONE'] != '0', |
| C0514 | configuración | app/lib/main.dart.bak:34 | enableAnimeGg: Platform.environment['KONGROO_ENABLE_ANIMEGG'] != '0', |
| C0515 | configuración | app/lib/main.dart.bak:35 | enableWikimedia: Platform.environment['KONGROO_ENABLE_WIKIMEDIA'] == '1', |
| C0516 | configuración | app/lib/main.dart.bak:44 | final markerPath = Platform.environment['ANIMEAPP_FIRST_FRAME_MARKER']; |
| C0517 | configuración | app/lib/main.dart.bak:64 | final String? path = Platform.environment['KONGROO_USER_SOURCES']; |
| C0518 | configuración | app/lib/main.dart.bak:83 | final String? requestedPath = Platform.environment['KONGROO_DATABASE_PATH']; |
| C0519 | configuración | app/lib/main_player_spike.dart:18 | if (Platform.environment['KONGROO_F2_2_SPIKE'] != '1') { |
| C0520 | configuración | app/lib/main_player_spike.dart:23 | final String? rootPath = Platform.environment['KONGROO_PROJECT_ROOT']; |
| C0521 | configuración | app/lib/main_player_spike.dart:36 | Platform.environment['KONGROO_F2_6_SUBTITLE_FIXTURE'] == '1'; |
| C0522 | configuración | app/lib/main_player_spike.dart:37 | final String? demoPorts = Platform.environment['KONGROO_DEMO_PORTS']; |
| C0523 | configuración | app/lib/main_player_spike.dart:38 | final bool realMedia = Platform.environment['KONGROO_DEMO_REAL_MEDIA'] == '1'; |
| C0524 | configuración | app/lib/main_player_spike.dart:74 | apiKey: () async => Platform.environment['OPENSUBTITLES_API_KEY'], |
| C0525 | configuración | app/lib/main_player_spike.dart:90 | Platform.environment['KONGROO_DEMO_SUBTITLES']; |
| C0526 | configuración | app/lib/main_player_spike.dart:93 | Platform.environment['KONGROO_DEMO_START'] ?? '', |
| C0527 | configuración | app/lib/main_player_spike.dart:119 | if (Platform.environment['KONGROO_DEMO_AUTOPLAY'] == '1') { |
| C0528 | endpoint/cabecera/parámetro | app/lib/main_player_spike.dart:242 | Scaffold(body: Center(child: Text(message))), |
| C0529 | persistencia | app/lib/settings/registry/README.md:4 | plugins. Cada `SettingDefinition<T>` declara clave estable, propietario, |
| C0530 | persistencia | app/lib/settings/registry/setting_definition.dart:8 | class SettingDefinition<T> { |
| C0531 | persistencia | app/lib/settings/registry/setting_definition.dart:9 | SettingDefinition({ |
| C0532 | persistencia | app/lib/settings/registry/settings_registry.dart:10 | void register<T>(SettingDefinition<T> definition) { |
| C0533 | persistencia | app/lib/settings/registry/settings_registry.dart:17 | Result<SettingDefinition<T>> resolve<T>(SettingDefinition<T> definition) { |
| C0534 | persistencia | app/lib/settings/registry/settings_registry.dart:19 | if (registered is! SettingDefinition<T> \|\| |
| C0535 | persistencia | app/lib/settings/store/settings_store.dart:19 | Future<Result<T>> get<T>(SettingDefinition<T> definition) async { |
| C0536 | persistencia | app/lib/settings/store/settings_store.dart:20 | final Result<SettingDefinition<T>> resolved = registry.resolve(definition); |
| C0537 | persistencia | app/lib/settings/store/settings_store.dart:21 | if (resolved case Failure<SettingDefinition<T>>(:final error)) { |
| C0538 | persistencia | app/lib/settings/store/settings_store.dart:39 | Future<Result<void>> set<T>(SettingDefinition<T> definition, T value) async { |
| C0539 | persistencia | app/lib/settings/store/settings_store.dart:40 | final Result<SettingDefinition<T>> resolved = registry.resolve(definition); |
| C0540 | persistencia | app/lib/settings/store/settings_store.dart:41 | if (resolved case Failure<SettingDefinition<T>>(:final error)) { |
| C0541 | persistencia | app/lib/settings/store/settings_store.dart:66 | Stream<Result<T>> watch<T>(SettingDefinition<T> definition) { |
| C0542 | persistencia | app/lib/settings/store/settings_store.dart:67 | final Result<SettingDefinition<T>> resolved = registry.resolve(definition); |
| C0543 | persistencia | app/lib/settings/store/settings_store.dart:68 | if (resolved case Failure<SettingDefinition<T>>(:final error)) { |
| C0544 | persistencia | app/lib/settings/store/settings_store.dart:76 | SettingDefinition<T> definition, |
