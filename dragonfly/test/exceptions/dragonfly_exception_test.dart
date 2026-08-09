import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/network/exceptions/dragonfly_http_exception.dart';
import 'package:dragonfly/framework/network/exceptions/dragonfly_network_invalid_method_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflyException', () {
    test('stores message and includes it in toString', () {
      final exception = DragonflyException(message: 'test error');

      expect(exception.message, 'test error');
      expect(exception.toString(), contains('test error'));
    });

    test('default message is empty string', () {
      final exception = DragonflyException();

      expect(exception.message, '');
    });
  });

  group('DragonflyHttpException', () {
    test('stores all fields and toString includes message', () {
      final exception = DragonflyHttpException(
        'Not Found',
        404,
        '{"error": "missing"}',
      );

      expect(exception.message, 'Not Found');
      expect(exception.statusCode, 404);
      expect(exception.body, '{"error": "missing"}');
      expect(exception.toString(), contains('Not Found'));
    });

    test('toString includes class name', () {
      final exception = DragonflyHttpException('Server Error', 500, '');

      expect(exception.toString(), contains('DragonflyHttpException'));
    });
  });

  group('DragonflyRealtimeException', () {
    test('stores all fields and toString includes channel and cause', () {
      final exception = DragonflyRealtimeException(
        'Connection failed',
        channel: 'events',
        cause: TimeoutException('timed out'),
      );

      expect(exception.message, 'Connection failed');
      expect(exception.channel, 'events');
      expect(exception.cause, isNotNull);
      expect(exception.toString(), contains('events'));
      expect(exception.toString(), contains('timed out'));
      expect(exception.toString(), contains('Connection failed'));
    });

    test('toString works without optional channel and cause', () {
      final exception = DragonflyRealtimeException('Disconnected');

      expect(exception.channel, isNull);
      expect(exception.cause, isNull);
      expect(exception.toString(), contains('Disconnected'));
    });
  });

  group('DragonflyNetworkInvalidMethodException', () {
    test('stores message', () {
      final exception = DragonflyNetworkInvalidMethodException(
        'Invalid HTTP method: FOO',
      );

      expect(exception.message, 'Invalid HTTP method: FOO');
    });

    test('stores empty message', () {
      final exception = DragonflyNetworkInvalidMethodException('');

      expect(exception.message, '');
    });
  });
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
