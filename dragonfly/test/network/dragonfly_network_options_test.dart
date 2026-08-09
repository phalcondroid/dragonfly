import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflyNetworkOptions', () {
    test('constructor stores headers', () {
      const options = DragonflyNetworkOptions(headers: {'key': 'value'});
      expect(options.headers, {'key': 'value'});
    });

    test('constructor stores empty headers', () {
      const options = DragonflyNetworkOptions(headers: {});
      expect(options.headers, isEmpty);
    });

    test('constructor stores multiple headers', () {
      const options = DragonflyNetworkOptions(headers: {
        'Authorization': 'Bearer token',
        'Content-Type': 'application/json',
      });
      expect(options.headers['Authorization'], 'Bearer token');
      expect(options.headers['Content-Type'], 'application/json');
      expect(options.headers.length, 2);
    });
  });

  group('Network name constants', () {
    test('defaultHttpNetwork constant equals "defaultHttpNetwork"', () {
      expect(defaultHttpNetwork, 'defaultHttpNetwork');
    });

    test('defaultRealtimeNetwork constant equals "defaultRealtimeNetwork"', () {
      expect(defaultRealtimeNetwork, 'defaultRealtimeNetwork');
    });
  });
}
