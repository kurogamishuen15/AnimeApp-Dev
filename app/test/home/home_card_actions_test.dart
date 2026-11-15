import 'package:anime_app/app/home/home_card_actions.dart';
import 'package:anime_app/app/home/home_data.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('library action policy exposes all six persisted states', () {
    final commands = HomeCardActionPolicy.libraryCommands(
      HomeTitle(title: 'Local', animeId: AnimeId('anime:local')),
    );

    expect(commands, hasLength(6));
    expect(commands.map((command) => command.status), [
      LibraryStatus.watching,
      LibraryStatus.planned,
      LibraryStatus.rewatching,
      LibraryStatus.paused,
      LibraryStatus.completed,
      LibraryStatus.abandoned,
    ]);
    expect(commands.map(HomeCardActionPolicy.commandLabel), [
      'Watching',
      'Plan to watch',
      'Rewatching',
      'Paused',
      'Completed',
      'Dropped',
    ]);
  });

  test('unlinked public title only offers a confirmed library add', () {
    final commands = HomeCardActionPolicy.libraryCommands(
      HomeTitle(
        title: 'Público',
        externalId: ExternalAnimeId(
          providerId: MetadataProviderId('anilist'),
          value: 'public-id',
        ),
      ),
    );

    expect(commands, hasLength(1));
    expect(commands.single.add, isTrue);
    expect(commands.single.status, isNull);
    expect(
      HomeCardActionPolicy.linkFor(
        HomeTitle(
          title: 'Público',
          externalId: ExternalAnimeId(
            providerId: MetadataProviderId('anilist'),
            value: '42',
          ),
        ),
      ),
      Uri.https('anilist.co', '/anime/42'),
    );
  });
}
