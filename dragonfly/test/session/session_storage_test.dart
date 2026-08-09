import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemorySessionStorage', () {
    late InMemorySessionStorage storage;

    setUp(() {
      storage = InMemorySessionStorage();
    });

    test('stores and retrieves string values', () async {
      await storage.setString('key', 'hello');
      final value = await storage.getString('key');
      expect(value, 'hello');
    });

    test('stores and retrieves different types (cast to correct type)', () async {
      await storage.setString('name', 'Alice');
      await storage.setInt('age', 42);
      await storage.setStringList('tags', ['dart', 'flutter']);

      expect(await storage.getString('name'), 'Alice');
      expect(await storage.getInt('age'), 42);
      expect(await storage.getStringList('tags'), ['dart', 'flutter']);
    });

    test('remove() deletes a key', () async {
      await storage.setString('key', 'value');
      expect(await storage.getString('key'), 'value');

      await storage.remove('key');
      expect(await storage.getString('key'), isNull);
    });

    test('clear() removes all keys', () async {
      await storage.setString('a', '1');
      await storage.setString('b', '2');
      await storage.setInt('c', 3);

      await storage.clear();

      expect(await storage.getString('a'), isNull);
      expect(await storage.getString('b'), isNull);
      expect(await storage.getInt('c'), isNull);
    });

    test('containsKey returns true/false correctly', () async {
      await storage.setString('exists', 'yes');

      expect(await storage.getString('exists'), isNotNull);
      expect(await storage.getString('missing'), isNull);
    });

    test('get non-existent key returns null', () async {
      expect(await storage.getString('nope'), isNull);
      expect(await storage.getInt('nope'), isNull);
      expect(await storage.getStringList('nope'), isNull);
    });

    test('overwrite existing key', () async {
      await storage.setString('key', 'first');
      expect(await storage.getString('key'), 'first');

      await storage.setString('key', 'second');
      expect(await storage.getString('key'), 'second');
    });
  });
}
