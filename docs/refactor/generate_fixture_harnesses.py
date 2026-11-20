"""Copy existing synthetic test fixtures into isolated characterization harnesses."""
from pathlib import Path
base=Path('app/test/data/player/providers')
configs={
'animegg':('_Pages(searchBody: _searchPage, seriesBody: _seriesPage, watchBody: _watchPage, embedBody: _embedPage)','AnimeGgPlaybackProvider(client)','_episode()'),
'anizone':('_Pages(searchBody: _searchPage, episodeBody: _assEpisodePage)','AniZonePlaybackProvider(client)','_episode()'),
'animeav1':('_Pages()','AnimeAv1PlaybackProvider(client)','_request()'),
'megaplay':("_Pages(answer: jsonEncode({'sources': {'file': 'https://fetch.nexabloom.top/a/master.m3u8?token=fixture'}}))",'MegaPlayPlaybackProvider(client)','_episode()'),
'allanime':("_Api(searchBody: {'data': {'shows': {'edges': [{'_id': 'show-1', 'name': 'Tokyo Ghoul:re', 'malId': '21199', 'englishName': 'Tokyo Ghoul:re'}]}}}, bootstrapBody: {'epoch': 2967, 'epochMs': 604800000, 'graceMs': 86400000, 'switchAt': 1795132800000, 'partB': _testPartB, 'k': 'k7'}, sourcesBody: jsonEncode({'data': {'tobeparsed': await _encryptTobeparsed({'episode': {'sourceUrls': [{'sourceUrl': 'https://tools.fast4speed.rsvp/media/sub/9', 'type': 'player', 'sourceName': 'Yt-mp4', 'fileExtenstion': 'mp4'}]}})}}))",'AllAnimePlaybackProvider(client, materials: _testMaterials)','_episode()'),
}
for key,(fixture,provider,request) in configs.items():
 text=(base/f'{key}_playback_provider_test.dart').read_text()
 before=text[:text.index('void main()')]
 after=text[text.index('\nfinal class _',text.index('void main()')):]
 # Drop a resolver used only by the original integrated main, preserve fixture adapter.
 if key=='animeav1':after=after[after.index('\nfinal class _Pages'):]
 before='\n'.join(line for line in before.splitlines() if 'playback_provider_manager.dart' not in line and 'flutter_test.dart' not in line and 'direct_media_host_resolver.dart' not in line and 'public_playback_http.dart' not in line)
 code="import '../../refactor/source_snapshot.dart';\n"+before+after+f'''
Future<Map<String, Object?>> snapshot() async {{
  final pages = {fixture};
  final client = Dio()..httpClientAdapter = pages;
  try {{
    final provider = {provider};
    final result = await provider.findSources({request}, cancellation: PlaybackCancellationToken());
    if (result is! PlaybackProviderSuccess<List<PlaybackSource>> || result.value.isEmpty) {{
      throw StateError('Fixture did not resolve nonempty sources: $result');
    }}
    return {{
      'sources': result.value.map(snapshotSource).toList(),
      'requests': pages.requests.map((r) => {{'method': r.method, 'uri': r.uri.toString(), 'headers': r.headers, 'data': r.data}}).toList(),
    }};
  }} finally {{ client.close(force: true); }}
}}
'''
 destination=Path(f'app/test/fixtures/refactor/{key}_harness.dart')
 if destination.exists(): raise SystemExit(f'Refusing to overwrite fixture: {destination}')
 destination.write_text(code)
