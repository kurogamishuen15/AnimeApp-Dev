import 'package:anime_app/app/catalog/detail/anime_detail_tab_content.dart';
import 'package:anime_app/app/catalog/detail/anime_detail_tabs.dart';
import 'package:anime_app/domain/catalog/anime_detail_metadata.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/metadata_provenance.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('copies AniList external episode links through its callback', (
    WidgetTester tester,
  ) async {
    final ExternalAnimeId id = ExternalAnimeId(
      providerId: MetadataProviderId('anilist'),
      value: '21',
    );
    final Uri externalUri = Uri.parse(
      'https://service.example/watch/episode-1',
    );
    final TextEditingController controller = TextEditingController();
    final List<Uri> copied = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimeDetailTabContent(
            tab: AnimeDetailTab.episodes,
            metadata: ProviderAnimeMetadata(
              externalId: id,
              preferredTitle: 'Example anime',
              provenance: MetadataProvenance(
                externalId: id,
                retrievedAtUtc: DateTime.utc(2026),
              ),
              detail: AnimeDetailMetadata(
                episodes: [
                  AnimeEpisodeMetadata(
                    number: 1,
                    title: 'Episode 1',
                    site: 'Official service',
                    externalWatchUri: externalUri,
                  ),
                ],
              ),
            ),
            progress: null,
            canSaveProgress: false,
            positionController: controller,
            saving: false,
            error: null,
            onSaveProgress: () {},
            onCopyExternalEpisodeLink: copied.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver en servicio externo'), findsOneWidget);
    expect(find.text('Official service'), findsOneWidget);
    final Finder copyButton = find.byKey(
      const ValueKey<String>('copy-external-streaming-link-0'),
    );
    expect(copyButton, findsOneWidget);
    await tester.tap(copyButton);
    expect(copied, [externalUri]);

    controller.dispose();
  });
}
