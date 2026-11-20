import 'package:anime_app/data/player/providers/episode_source_support.dart';
import 'package:anime_app/data/player/providers/public_playback_http.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:flutter_test/flutter_test.dart';

/// Characterization of the shared adapter helpers. Every migrated provider
/// delegates here, so these tests protect the exact result mapping the six
/// provider suites exercised implicitly until now.
void main() {
  test('null load becomes empty and values pass through', () async {
    final empty = await EpisodeSourceSupport.read<int>(() async => null);
    expect(empty, isA<PlaybackProviderEmpty<int>>());

    final value = await EpisodeSourceSupport.read<int>(() async => 7);
    expect((value as PlaybackProviderSuccess<int>).value, 7);
  });

  test('transport failures map to their own result', () async {
    for (final kind in [
      PlaybackProviderFailureKind.forbidden,
      PlaybackProviderFailureKind.timeout,
      PlaybackProviderFailureKind.rateLimited,
    ]) {
      final result = await EpisodeSourceSupport.read<int>(
        () async => throw PublicPlaybackFailure(kind),
      );
      expect((result as PlaybackProviderFailed<int>).failure.kind, kind);
    }
  });

  test('malformed payloads map to invalidResponse', () async {
    final format = await EpisodeSourceSupport.read<int>(
      () async => throw const FormatException('bad'),
    );
    expect(
      (format as PlaybackProviderFailed<int>).failure.kind,
      PlaybackProviderFailureKind.invalidResponse,
    );

    final argument = await EpisodeSourceSupport.read<int>(
      () async => throw ArgumentError.value(null, 'payload'),
    );
    expect(
      (argument as PlaybackProviderFailed<int>).failure.kind,
      PlaybackProviderFailureKind.invalidResponse,
    );
  });

  test('check throws cancelled exactly once per cancelled token', () {
    final token = PlaybackCancellationToken();
    EpisodeSourceSupport.check(token); // no throw
    token.cancel();
    expect(
      () => EpisodeSourceSupport.check(token),
      throwsA(
        isA<PublicPlaybackFailure>().having(
          (PublicPlaybackFailure failure) => failure.kind,
          'kind',
          PlaybackProviderFailureKind.cancelled,
        ),
      ),
    );
  });

  test('contractTitle normalizes case and whitespace only', () {
    expect(
      EpisodeSourceSupport.contractTitle('  Tokyo    Ghoul:re '),
      'tokyo ghoul:re',
    );
    expect(
      EpisodeSourceSupport.contractTitle('Tokyo　Ghoul'), // full-width space
      'tokyo ghoul',
    );
  });
}
