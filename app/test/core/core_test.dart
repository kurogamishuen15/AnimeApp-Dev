import 'package:anime_app/core/errors/app_error.dart';
import 'package:anime_app/core/logger/safe_logger.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('maps successful values and propagates typed failures', () {
      const success = Success<int>(4);
      expect(success.map((value) => value * 2), isA<Success<int>>());
      expect(
        success.map((value) => value * 2).fold((value) => value, (_) => 0),
        8,
      );

      const failure = Failure<int>(NetworkError());
      expect(failure.map((value) => value * 2), isA<Failure<int>>());
      expect(failure.flatMap((value) => Success(value)), isA<Failure<int>>());
      expect(
        failure.fold((_) => false, (error) => error is NetworkError),
        isTrue,
      );
    });
  });

  group('SafeLogger', () {
    test('redacts sensitive keys and values recursively', () {
      final sink = MemoryLogSink();
      final logger = SafeLogger(sink: sink.call);
      logger.log(
        LogLevel.info,
        'request',
        fields: {
          'Authorization': 'Bearer abc.def.ghi',
          'nested': {
            'access_token': 'secret-token-value',
            'url': Uri.parse(
              'https://example.test/callback?code=secret#access_token=secret',
            ),
          },
          'exception': Exception('token=secret-token-value'),
        },
      );

      final output = sink.records.single.fields.toString();
      expect(output.toLowerCase(), isNot(contains('secret-token-value')));
      expect(output, isNot(contains('code=secret')));
      expect(output, isNot(contains('access_token=secret')));
      expect(output, contains('[REDACTED]'));
      expect(output, contains('Exception'));
      logger.dispose();
      logger.log(LogLevel.info, 'ignored', fields: {'token': 'still-secret'});
      expect(sink.records, hasLength(1));
      sink.dispose();
    });

    test('redacts URI query credentials and is case insensitive', () {
      final sink = MemoryLogSink();
      final logger = SafeLogger(sink: sink.call);
      logger.log(
        LogLevel.warning,
        'uri',
        fields: {
          'url': Uri.parse(
            'https://example.test/?AUTHORIZATION=secret&x=ok#token=also-secret',
          ),
        },
      );
      final output = sink.records.single.fields.toString();
      expect(output, isNot(contains('secret')));
      expect(output, isNot(contains('also-secret')));
      expect(output, isNot(contains('AUTHORIZATION=secret')));
      expect(output, contains('[PATH REDACTED]'));
    });

    test('does not throw when sanitizing a malformed URL-like value', () {
      final sink = MemoryLogSink();
      final logger = SafeLogger(sink: sink.call);

      expect(
        () => logger.log(
          LogLevel.warning,
          'malformed url: https://[',
          fields: const {'message': 'see https://[ for details'},
        ),
        returnsNormally,
      );
      expect(sink.records, hasLength(1));
      expect(sink.records.single.fields['message'], contains('[INVALID URL]'));
      logger.dispose();
      sink.dispose();
    });

    test('redacts URI user info and multiple sinks stop receiving records', () {
      final first = MemoryLogSink();
      final second = MemoryLogSink();
      final logger = SafeLogger(sink: first.call)..addSink(second.call);
      logger.log(
        LogLevel.info,
        'callback',
        fields: {
          'uri': Uri.parse(
            'https://user:password@example.test/oauth?code=secret#token=secret',
          ),
        },
      );
      expect(
        first.records.single.fields.toString(),
        isNot(contains('password')),
      );
      expect(first.records.single.fields.toString(), isNot(contains('secret')));
      expect(second.records, hasLength(1));

      logger.dispose();
      logger.log(LogLevel.info, 'ignored');
      expect(first.records, hasLength(1));
      expect(second.records, hasLength(1));
      first.dispose();
      second.dispose();
      expect(first.records, isEmpty);
      expect(second.records, isEmpty);
    });
  });
}
