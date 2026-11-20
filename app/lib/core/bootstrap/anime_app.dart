import 'package:anime_app/application/catalog/catalog_service.dart';
import 'package:anime_app/domain/app_identity.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/catalog/catalog_home_page.dart';
import '../../app/home/home_appearance.dart';
import '../../data/player/providers/playback_providers_module.dart';

class AnimeApp extends StatefulWidget {
  const AnimeApp({
    required this.catalogService,
    this.playbackModule,
    super.key,
  });

  final CatalogService catalogService;
  final PlaybackProvidersModule? playbackModule;

  @override
  State<AnimeApp> createState() => _AnimeAppState();
}

final class _AnimeAppState extends State<AnimeApp> {
  @override
  void dispose() {
    widget.playbackModule?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppIdentity.name,
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'kongroo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: Theme(
        data: ThemeData(
          scaffoldBackgroundColor: HomeAppearance.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffa69aff),
            brightness: Brightness.dark,
          ),
          extensions: const [HomeAppearance()],
          appBarTheme: const AppBarThemeData(
            backgroundColor: HomeAppearance.background,
          ),
        ),
        child: CatalogHomePage(
          service: widget.catalogService,
          playbackProviders: widget.playbackModule?.manager,
        ),
      ),
    );
  }
}
