import 'package:material_ui/material_ui.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import 'home_appearance.dart';
import 'home_card_actions.dart';
import 'home_data.dart';
import 'home_hero.dart';
import 'home_sections.dart';

final class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.load,
    required this.onDetails,
    required this.onLibraryAction,
    this.refreshRevision = 0,
    super.key,
  });

  final HomeLoader load;
  final ValueChanged<HomeTitle> onDetails;
  final Future<void> Function(HomeTitle, HomeCardLibraryCommand)
  onLibraryAction;
  final int refreshRevision;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  late Future<Result<HomeContent>> _result;
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey _heroVisibilityKey = GlobalKey();
  bool _heroVisible = true;
  bool _heroVisibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(_scheduleHeroVisibilityCheck);
    _reload();
  }

  @override
  void dispose() {
    _homeScrollController
      ..removeListener(_scheduleHeroVisibilityCheck)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshRevision != widget.refreshRevision) _reload();
  }

  void _reload() {
    _result = Future<Result<HomeContent>>.sync(() async => await widget.load())
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => const Failure(TimeoutAppError()),
        );
  }

  void _scheduleHeroVisibilityCheck() {
    if (_heroVisibilityCheckScheduled) return;
    _heroVisibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heroVisibilityCheckScheduled = false;
      if (!mounted) return;
      final heroContext = _heroVisibilityKey.currentContext;
      final renderObject = heroContext?.findRenderObject();
      if (heroContext == null || renderObject is! RenderBox) {
        if (!_heroVisible) setState(() => _heroVisible = true);
        return;
      }
      final heroBounds =
          renderObject.localToGlobal(Offset.zero) & renderObject.size;
      final windowBounds = Offset.zero & MediaQuery.sizeOf(heroContext);
      final visible = heroBounds.overlaps(windowBounds);
      if (visible != _heroVisible) setState(() => _heroVisible = visible);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HomeAppearance.background,
      child: FutureBuilder<Result<HomeContent>>(
        future: _result,
        builder: (context, snapshot) {
          if (snapshot.data case Success<HomeContent>(:final value)) {
            if (!value.isEmpty || value.offline) {
              return _content(
                value,
                refreshing: snapshot.connectionState != ConnectionState.done,
              );
            }
            return _status(Icons.video_library_outlined, 'Inicio está vacío');
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando Inicio',
              ),
            );
          }
          if (snapshot.data case Failure<HomeContent>(error: NetworkError())) {
            return _status(Icons.cloud_off_outlined, 'Sin conexión');
          }
          return _status(Icons.error_outline, 'No se pudo cargar Inicio');
        },
      ),
    );
  }

  Widget _status(IconData icon, String label) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 12),
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => setState(_reload),
            child: const Text('Volver a cargar'),
          ),
        ],
      ),
    ),
  );

  Widget _content(HomeContent value, {required bool refreshing}) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final inset = constraints.maxWidth >= 720 ? 32.0 : 16.0;
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false),
            child: CustomScrollView(
              key: const PageStorageKey('home-scroll'),
              restorationId: 'home-scroll',
              controller: _homeScrollController,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 12, inset, 36),
                  sliver: SliverList.list(
                    children: [
                      if (value.offline)
                        Row(
                          children: [
                            const Icon(Icons.cloud_off_outlined),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Sin conexión · Contenido local'),
                            ),
                            TextButton(
                              onPressed: refreshing
                                  ? null
                                  : () => setState(_reload),
                              child: Text(
                                refreshing ? 'Actualizando…' : 'Reintentar',
                              ),
                            ),
                          ],
                        ),
                      if (value.featured case final anime?)
                        HomeHero(
                          key: _heroVisibilityKey,
                          anime: anime,
                          highlights: value.highlights,
                          visible: _heroVisible,
                          onDetails: widget.onDetails,
                        ),
                      ...HomeSections.buildSections(
                        value,
                        widget.onDetails,
                        onLibraryAction: widget.onLibraryAction,
                        wide: constraints.maxWidth - 2 * inset >= 720,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}
