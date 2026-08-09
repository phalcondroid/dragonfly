import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflyLogFormatter.format', () {
    test('formats a basic info entry', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'App started',
        timestamp: DateTime(2024, 1, 15, 10, 30, 45, 123),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('INFO'));
      expect(formatted, contains('App started'));
      expect(formatted, contains('10:30:45'));
      expect(formatted, isNotEmpty);
    });

    test('formats a debug entry', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.debug,
        message: 'Debug info',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('DEBUG'));
    });

    test('formats a success entry', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.success,
        message: 'Operation succeeded',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('SUCCESS'));
    });

    test('formats a warning entry', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.warning,
        message: 'Low memory',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('WARNING'));
    });

    test('formats an error entry', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.error,
        message: 'Something failed',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('ERROR'));
    });

    test('formats a danger entry', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.danger,
        message: 'Critical failure',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('DANGER'));
    });

    test('formats a request entry', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.request,
        message: 'GET /api/data',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('REQUEST'));
    });

    test('formats a response entry', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.response,
        message: '200 OK',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('RESPONSE'));
    });

    test('includes source when provided', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'Test',
        source: 'MyService',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('[MyService]'));
    });

    test('does not include source bracket when not provided', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'Test',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, isNot(contains('[')));
    });

    test('includes data section when data is present', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'Test',
        data: {'key': 'value'},
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('Data:'));
      expect(formatted, contains('key: value'));
    });

    test('does not include data section when data is empty', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'Test',
        data: <String, dynamic>{},
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, isNot(contains('Data:')));
    });

    test('does not include data section when data is null', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'Test',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, isNot(contains('Data:')));
    });

    test('includes error section when error is present', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.error,
        message: 'Failed',
        error: 'connection refused',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('Error:'));
      expect(formatted, contains('connection refused'));
    });

    test('does not include error section when error is null', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.error,
        message: 'Failed',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, isNot(contains('Error:')));
    });

    test('includes stack trace section when stackTrace is present', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.error,
        message: 'Failed',
        stackTrace: StackTrace.current,
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('Stack trace:'));
    });

    test('includes level emoji', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.error,
        message: 'Error',
        timestamp: DateTime(2024),
      );
      final formatted = DragonflyLogFormatter.format(entry);
      expect(formatted, contains('❌'));
    });

    test('does not throw on any valid input', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'Hello',
        tag: 'test',
        data: {'a': 'b'},
        error: Exception('err'),
        stackTrace: StackTrace.current,
        source: 'Test',
        timestamp: DateTime.now(),
      );
      expect(() => DragonflyLogFormatter.format(entry), returnsNormally);
    });
  });

  group('DragonflyLogFormatter.formatRequest', () {
    test('formats a request log entry', () {
      final entry = DragonflyNetworkRequestLog(
        method: 'GET',
        url: 'https://api.example.com/characters',
        requestId: 'req-123',
        headers: {'Authorization': 'Bearer ***'},
        body: {'page': 1},
        queryParams: {'limit': '10'},
        source: 'CharacterRepository',
      );
      final formatted = DragonflyLogFormatter.formatRequest(entry);
      expect(formatted, contains('REQUEST'));
      expect(formatted, contains('req-123'));
      expect(formatted, contains('GET'));
      expect(formatted, contains('https://api.example.com/characters'));
      expect(formatted, contains('Authorization'));
      expect(formatted, contains('limit'));
      expect(formatted, contains('page'));
      expect(formatted, contains('Query Parameters'));
      expect(formatted, contains('Headers'));
      expect(formatted, contains('Body'));
    });

    test('formats a request without optional fields', () {
      final entry = DragonflyNetworkRequestLog(
        method: 'POST',
        url: 'https://api.example.com/data',
        requestId: 'req-456',
      );
      final formatted = DragonflyLogFormatter.formatRequest(entry);
      expect(formatted, contains('REQUEST'));
      expect(formatted, contains('req-456'));
      expect(formatted, contains('POST'));
      expect(formatted, contains('https://api.example.com/data'));
      expect(formatted, isNot(contains('Headers')));
      expect(formatted, isNot(contains('Body')));
    });

    test('does not throw on any valid input', () {
      final entry = DragonflyNetworkRequestLog(
        method: 'GET',
        url: 'https://example.com',
        requestId: 'r1',
      );
      expect(
            () => DragonflyLogFormatter.formatRequest(entry),
        returnsNormally,
      );
    });
  });

  group('DragonflyLogFormatter.formatResponse', () {
    test('formats a successful response', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 200,
        durationMs: 150,
        requestId: 'req-123',
        url: 'https://api.example.com/characters',
        method: 'GET',
        statusMessage: 'OK',
        headers: {'Content-Type': 'application/json'},
        body: {'results': [1, 2, 3]},
      );
      final formatted = DragonflyLogFormatter.formatResponse(entry);
      expect(formatted, contains('RESPONSE'));
      expect(formatted, contains('req-123'));
      expect(formatted, contains('200'));
      expect(formatted, contains('150ms'));
      expect(formatted, contains('Content-Type'));
      expect(formatted, contains('Response Headers'));
      expect(formatted, contains('Response Body'));
    });

    test('formats a client error response', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 404,
        durationMs: 50,
        requestId: 'req-789',
        url: 'https://api.example.com/missing',
        method: 'GET',
      );
      final formatted = DragonflyLogFormatter.formatResponse(entry);
      expect(formatted, contains('RESPONSE'));
      expect(formatted, contains('404'));
    });

    test('formats a server error response', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 500,
        durationMs: 200,
        requestId: 'req-err',
        url: 'https://api.example.com/error',
        method: 'GET',
      );
      final formatted = DragonflyLogFormatter.formatResponse(entry);
      expect(formatted, contains('RESPONSE'));
      expect(formatted, contains('500'));
    });

    test('shows "... and N more headers" when >5 headers', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 200,
        durationMs: 100,
        requestId: 'req-h',
        url: 'https://example.com',
        method: 'GET',
        headers: {
          for (var i = 0; i < 10; i++) 'Header$i': 'Value$i',
        },
      );
      final formatted = DragonflyLogFormatter.formatResponse(entry);
      expect(formatted, contains('more headers'));
    });

    test('does not throw on minimal response', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 204,
        durationMs: 10,
        requestId: 'r1',
        url: 'https://example.com',
        method: 'DELETE',
      );
      expect(
            () => DragonflyLogFormatter.formatResponse(entry),
        returnsNormally,
      );
    });
  });

  group('DragonflyLogFormatter.formatRepository', () {
    test('formats a repository log entry', () {
      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.info,
        repository: 'CharacterRepository',
        methodName: 'getCharacters',
        message: 'Fetching characters',
        params: {'page': '1'},
        durationMs: 45,
      );
      final formatted = DragonflyLogFormatter.formatRepository(entry);
      expect(formatted, contains('INFO'));
      expect(formatted, contains('Repository'));
      expect(formatted, contains('CharacterRepository.getCharacters()'));
      expect(formatted, contains('page: 1'));
      expect(formatted, contains('45ms'));
      expect(formatted, contains('Fetching characters'));
    });

    test('formats repository log with error', () {
      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.error,
        repository: 'AuthRepository',
        methodName: 'login',
        message: 'Login failed',
        error: 'Invalid credentials',
        stackTrace: StackTrace.current,
      );
      final formatted = DragonflyLogFormatter.formatRepository(entry);
      expect(formatted, contains('ERROR'));
      expect(formatted, contains('Repository'));
      expect(formatted, contains('AuthRepository.login()'));
      expect(formatted, contains('Invalid credentials'));
      expect(formatted, contains('Stack Trace'));
    });

    test('formats repository log without optional fields', () {
      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.success,
        repository: 'Repo',
        methodName: 'save',
        message: 'Saved',
      );
      final formatted = DragonflyLogFormatter.formatRepository(entry);
      expect(formatted, contains('SUCCESS'));
      expect(formatted, contains('Repo.save()'));
      expect(formatted, contains('Saved'));
      expect(formatted, isNot(contains('Parameters')));
      expect(formatted, isNot(contains('Error')));
    });

    test('does not throw on minimal repository log', () {
      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.debug,
        repository: 'R',
        methodName: 'm',
        message: 'x',
      );
      expect(
            () => DragonflyLogFormatter.formatRepository(entry),
        returnsNormally,
      );
    });
  });

  group('DragonflyLogFormatter.useColors', () {
    test('defaults to false', () {
      expect(DragonflyLogFormatter.useColors, isFalse);
    });

    test('can be toggled', () {
      DragonflyLogFormatter.useColors = true;
      expect(DragonflyLogFormatter.useColors, isTrue);
      DragonflyLogFormatter.useColors = false;
      expect(DragonflyLogFormatter.useColors, isFalse);
    });
  });
}
