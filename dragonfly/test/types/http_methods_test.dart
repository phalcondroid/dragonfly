import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpMethods', () {
    test('values contains all methods', () {
      final values = HttpMethods.values;

      expect(values, containsAll([
        HttpMethods.get,
        HttpMethods.post,
        HttpMethods.put,
        HttpMethods.patch,
        HttpMethods.delete,
        HttpMethods.unknown,
      ]));
      expect(values.length, 6);
    });

    test('get.name returns "get"', () {
      expect(HttpMethods.get.name, 'get');
    });

    test('enum comparison works', () {
      expect(HttpMethods.get, HttpMethods.get);
      expect(HttpMethods.get, isNot(HttpMethods.post));
    });
  });
}
