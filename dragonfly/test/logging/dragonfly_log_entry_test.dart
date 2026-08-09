import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────
  // DragonflyLogEntry
  // ─────────────────────────────────────────────────────────────────

  group('DragonflyLogEntry', () {
    test('stores all required fields', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'Test message',
        source: 'TestClass.method',
      );

      expect(entry.level, DragonflyLogLevel.info);
      expect(entry.message, 'Test message');
      expect(entry.source, 'TestClass.method');
    });

    test('defaults tag, data, error, stackTrace to null', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.debug,
        message: 'msg',
      );

      expect(entry.tag, isNull);
      expect(entry.data, isNull);
      expect(entry.error, isNull);
      expect(entry.stackTrace, isNull);
      expect(entry.source, isNull);
    });

    test('stores optional fields: tag, data', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.warning,
        message: 'Warning with data',
        tag: 'AUTH',
        data: {'userId': '42', 'action': 'login'},
      );

      expect(entry.tag, 'AUTH');
      expect(entry.data, {'userId': '42', 'action': 'login'});
    });

    test('stores optional fields: error and stackTrace', () {
      final exception = Exception('test exception');
      final stack = StackTrace.current;

      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.error,
        message: 'Error occurred',
        error: exception,
        stackTrace: stack,
      );

      expect(entry.error, exception);
      expect(entry.stackTrace, stack);
    });

    test('stores all fields simultaneously', () {
      const exception = FormatException('bad format');
      final stack = StackTrace.current;
      final now = DateTime(2026, 8, 7, 12, 0);

      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.danger,
        message: 'Critical failure',
        tag: 'DATABASE',
        data: {'table': 'users'},
        error: exception,
        stackTrace: stack,
        source: 'DatabaseService.save',
        timestamp: now,
      );

      expect(entry.level, DragonflyLogLevel.danger);
      expect(entry.message, 'Critical failure');
      expect(entry.tag, 'DATABASE');
      expect(entry.data, {'table': 'users'});
      expect(entry.error, exception);
      expect(entry.stackTrace, stack);
      expect(entry.source, 'DatabaseService.save');
      expect(entry.timestamp, now);
    });

    test('timestamp defaults to current time when not provided', () {
      final before = DateTime.now();
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'msg',
      );
      final after = DateTime.now();

      expect(
        entry.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        entry.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('toString() returns formatted string', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.error,
        message: 'Something broke',
      );

      expect(entry.toString(), contains('Something broke'));
      expect(entry.toString(), isNotEmpty);
    });

    test('toString() includes the level', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.warning,
        message: 'Disk space low',
      );

      expect(entry.toString(), contains('warning'));
      expect(entry.toString(), contains('Disk space low'));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // DragonflyNetworkRequestLog
  // ─────────────────────────────────────────────────────────────────

  group('DragonflyNetworkRequestLog', () {
    test('stores required fields', () {
      final entry = DragonflyNetworkRequestLog(
        method: 'GET',
        url: 'https://api.example.com/users',
        requestId: 'REQ001',
      );

      expect(entry.method, 'GET');
      expect(entry.url, 'https://api.example.com/users');
      expect(entry.requestId, 'REQ001');
      expect(entry.level, DragonflyLogLevel.request);
      expect(entry.tag, 'HTTP');
    });

    test('message is constructed from method and url', () {
      final entry = DragonflyNetworkRequestLog(
        method: 'POST',
        url: 'https://api.example.com/data',
        requestId: 'REQ002',
      );

      expect(entry.message, 'POST https://api.example.com/data');
    });

    test('stores optional fields: headers, body, queryParams, source', () {
      final entry = DragonflyNetworkRequestLog(
        method: 'POST',
        url: 'https://api.example.com/data',
        requestId: 'REQ003',
        headers: {'Content-Type': 'application/json'},
        body: {'name': 'Test'},
        queryParams: {'page': '1', 'limit': '10'},
        source: 'UserRepository.fetchUsers',
      );

      expect(entry.headers, {'Content-Type': 'application/json'});
      expect(entry.body, {'name': 'Test'});
      expect(entry.queryParams, {'page': '1', 'limit': '10'});
      expect(entry.source, 'UserRepository.fetchUsers');
    });

    test('inherits from DragonflyLogEntry', () {
      final entry = DragonflyNetworkRequestLog(
        method: 'DELETE',
        url: 'https://api.example.com/users/1',
        requestId: 'REQ004',
      );

      expect(entry, isA<DragonflyLogEntry>());
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // DragonflyNetworkResponseLog
  // ─────────────────────────────────────────────────────────────────

  group('DragonflyNetworkResponseLog', () {
    test('stores required fields', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 200,
        durationMs: 150,
        requestId: 'REQ001',
        url: 'https://api.example.com/users',
        method: 'GET',
      );

      expect(entry.statusCode, 200);
      expect(entry.durationMs, 150);
      expect(entry.requestId, 'REQ001');
      expect(entry.url, 'https://api.example.com/users');
      expect(entry.method, 'GET');
      expect(entry.level, DragonflyLogLevel.response);
      expect(entry.tag, 'HTTP');
    });

    test('stores optional fields: statusMessage, headers, body, source', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 201,
        durationMs: 75,
        requestId: 'REQ002',
        url: 'https://api.example.com/users',
        method: 'POST',
        statusMessage: 'Created',
        headers: {'Content-Type': 'application/json'},
        body: {'id': 1, 'name': 'Test'},
        source: 'UserRepository.createUser',
      );

      expect(entry.statusMessage, 'Created');
      expect(entry.headers, {'Content-Type': 'application/json'});
      expect(entry.body, {'id': 1, 'name': 'Test'});
      expect(entry.source, 'UserRepository.createUser');
    });

    test('message includes status code and duration', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 404,
        durationMs: 200,
        requestId: 'REQ003',
        url: 'https://api.example.com/missing',
        method: 'GET',
        statusMessage: 'Not Found',
      );

      expect(entry.message, contains('404'));
      expect(entry.message, contains('200 ms'));
    });

    test('isSuccess returns true for 2xx status codes', () {
      DragonflyNetworkResponseLog entry(int code) =>
          DragonflyNetworkResponseLog(
            statusCode: code,
            durationMs: 10,
            requestId: 'ID',
            url: 'https://example.com',
            method: 'GET',
          );

      expect(entry(200).isSuccess, isTrue);
      expect(entry(201).isSuccess, isTrue);
      expect(entry(299).isSuccess, isTrue);
      expect(entry(300).isSuccess, isFalse);
      expect(entry(400).isSuccess, isFalse);
      expect(entry(500).isSuccess, isFalse);
    });

    test('isClientError returns true for 4xx status codes', () {
      DragonflyNetworkResponseLog entry(int code) =>
          DragonflyNetworkResponseLog(
            statusCode: code,
            durationMs: 10,
            requestId: 'ID',
            url: 'https://example.com',
            method: 'GET',
          );

      expect(entry(400).isClientError, isTrue);
      expect(entry(404).isClientError, isTrue);
      expect(entry(499).isClientError, isTrue);
      expect(entry(200).isClientError, isFalse);
      expect(entry(500).isClientError, isFalse);
    });

    test('isServerError returns true for 5xx status codes', () {
      DragonflyNetworkResponseLog entry(int code) =>
          DragonflyNetworkResponseLog(
            statusCode: code,
            durationMs: 10,
            requestId: 'ID',
            url: 'https://example.com',
            method: 'GET',
          );

      expect(entry(500).isServerError, isTrue);
      expect(entry(503).isServerError, isTrue);
      expect(entry(200).isServerError, isFalse);
      expect(entry(404).isServerError, isFalse);
    });

    test('inherits from DragonflyLogEntry', () {
      final entry = DragonflyNetworkResponseLog(
        statusCode: 200,
        durationMs: 100,
        requestId: 'REQ005',
        url: 'https://api.example.com',
        method: 'GET',
      );

      expect(entry, isA<DragonflyLogEntry>());
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // DragonflyRepositoryLog
  // ─────────────────────────────────────────────────────────────────

  group('DragonflyRepositoryLog', () {
    test('stores required fields', () {
      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.success,
        repository: 'UserRepository',
        methodName: 'getUsers',
        message: 'Fetched 10 users',
      );

      expect(entry.level, DragonflyLogLevel.success);
      expect(entry.repository, 'UserRepository');
      expect(entry.methodName, 'getUsers');
      expect(entry.message, 'Fetched 10 users');
      expect(entry.tag, 'Repository');
      expect(entry.source, 'UserRepository.getUsers');
    });

    test('stores optional fields: params, result, durationMs', () {
      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.info,
        repository: 'ProductRepository',
        methodName: 'search',
        message: 'Search complete',
        params: {'query': 'phone', 'category': 'electronics'},
        result: ['Product A', 'Product B'],
        durationMs: 340,
      );

      expect(entry.params, {'query': 'phone', 'category': 'electronics'});
      expect(entry.result, ['Product A', 'Product B']);
      expect(entry.durationMs, 340);
    });

    test('stores optional fields: error and stackTrace', () {
      final exception = Exception('Database timeout');
      final stack = StackTrace.current;

      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.error,
        repository: 'OrderRepository',
        methodName: 'createOrder',
        message: 'Failed to create order',
        error: exception,
        stackTrace: stack,
        durationMs: 5000,
      );

      expect(entry.error, exception);
      expect(entry.stackTrace, stack);
      expect(entry.durationMs, 5000);
    });

    test('inherits from DragonflyLogEntry', () {
      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.warning,
        repository: 'CacheRepository',
        methodName: 'get',
        message: 'Cache miss',
      );

      expect(entry, isA<DragonflyLogEntry>());
    });

    test('source combines repository and methodName', () {
      final entry = DragonflyRepositoryLog(
        level: DragonflyLogLevel.info,
        repository: 'AuthRepository',
        methodName: 'login',
        message: 'User logged in',
      );

      expect(entry.source, 'AuthRepository.login');
    });

    test('level can be any DragonflyLogLevel', () {
      for (final level in DragonflyLogLevel.values) {
        final entry = DragonflyRepositoryLog(
          level: level,
          repository: 'TestRepo',
          methodName: 'test',
          message: 'test message',
        );

        expect(entry.level, level);
      }
    });
  });
}
