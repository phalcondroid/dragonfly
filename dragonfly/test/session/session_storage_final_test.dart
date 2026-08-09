// ignore_for_file: strict_raw_type, inference_failure_on_function_invocation

import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/session/session_storage.dart'
    show SessionStorageJson;
import 'package:flutter_test/flutter_test.dart';

class _CustomSessionStorage implements SessionStorage {
  final Map<String, dynamic> _store = {};

  @override
  Future<String?> getString(String key) async => _store[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  Future<List<String>?> getStringList(String key) async =>
      _store[key] as List<String>?;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _store[key] = value;

  @override
  Future<int?> getInt(String key) async => _store[key] as int?;

  @override
  Future<void> setInt(String key, int value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();
}

class _MockHiveBox {
  final Map<String, dynamic> _data = {};

  dynamic get(String key, {dynamic defaultValue}) =>
      _data.containsKey(key) ? _data[key] : defaultValue;

  Future<void> put(String key, dynamic value) async => _data[key] = value;

  Future<void> delete(String key) async => _data.remove(key);

  Future<int> clear() async {
    final count = _data.length;
    _data.clear();
    return count;
  }
}

void main() {
  // ── InMemorySessionStorage edge cases ───────────────────────────────

  group('InMemorySessionStorage edge cases', () {
    late InMemorySessionStorage storage;

    setUp(() {
      storage = InMemorySessionStorage();
    });

    test('get on non-existent key returns null', () async {
      expect(await storage.getString('neverSet'), null);
      expect(await storage.getInt('neverSet'), null);
      expect(await storage.getStringList('neverSet'), null);
    });

    test('same key put twice, last value wins', () async {
      await storage.setString('key', 'first');
      await storage.setString('key', 'second');
      expect(await storage.getString('key'), 'second');
    });

    test('same int key put twice, last value wins', () async {
      await storage.setInt('x', 1);
      await storage.setInt('x', 99);
      expect(await storage.getInt('x'), 99);
    });

    test('same stringList key put twice, last value wins', () async {
      await storage.setStringList('tags', ['a']);
      await storage.setStringList('tags', ['b', 'c']);
      expect(await storage.getStringList('tags'), ['b', 'c']);
    });

    test('after clear, all keys gone', () async {
      await storage.setString('a', '1');
      await storage.setString('b', '2');
      await storage.setInt('c', 3);
      await storage.setStringList('d', ['x']);

      await storage.clear();

      expect(await storage.getString('a'), isNull);
      expect(await storage.getString('b'), isNull);
      expect(await storage.getInt('c'), isNull);
      expect(await storage.getStringList('d'), isNull);
    });

    test('put after clear works', () async {
      await storage.setString('k', 'before');
      await storage.clear();
      await storage.setString('k', 'after');
      expect(await storage.getString('k'), 'after');
    });

    test('getString on different types per key', () async {
      await storage.setString('s', 'hello');
      await storage.setInt('i', 42);
      await storage.setStringList('l', ['a']);

      expect(await storage.getString('s'), 'hello');
      expect(await storage.getInt('i'), 42);
      expect(await storage.getStringList('l'), ['a']);
    });

    test('remove then re-add same key', () async {
      await storage.setString('key', 'original');
      await storage.remove('key');
      await storage.setString('key', 'new');
      expect(await storage.getString('key'), 'new');
    });
  });

  // ── Custom SessionStorage implementation ────────────────────────────

  group('Custom SessionStorage', () {
    late _CustomSessionStorage storage;

    setUp(() {
      storage = _CustomSessionStorage();
    });

    test('implements SessionStorage interface', () {
      expect(storage, isA<SessionStorage>());
    });

    test('setString and getString', () async {
      await storage.setString('name', 'Dragonfly');
      expect(await storage.getString('name'), 'Dragonfly');
    });

    test('setInt and getInt', () async {
      await storage.setInt('count', 100);
      expect(await storage.getInt('count'), 100);
    });

    test('setStringList and getStringList', () async {
      await storage.setStringList('items', ['one', 'two']);
      expect(await storage.getStringList('items'), ['one', 'two']);
    });

    test('remove deletes key', () async {
      await storage.setString('key', 'val');
      expect(await storage.getString('key'), 'val');
      await storage.remove('key');
      expect(await storage.getString('key'), isNull);
    });

    test('clear removes all', () async {
      await storage.setString('a', '1');
      await storage.setInt('b', 2);
      await storage.clear();
      expect(await storage.getString('a'), isNull);
      expect(await storage.getInt('b'), isNull);
    });

    test('json extension works on custom implementation', () async {
      await storage.setJson('data', {'x': 1, 'y': 2});
      expect(await storage.getJson('data'), {'x': 1, 'y': 2});
    });
  });

  // ── HiveSessionStorage with mock box ────────────────────────────────

  group('HiveSessionStorage', () {
    late _MockHiveBox box;
    late HiveSessionStorage storage;

    setUp(() {
      box = _MockHiveBox();
      storage = HiveSessionStorage(box);
    });

    test('constructor accepts dynamic box', () {
      expect(storage, isA<HiveSessionStorage>());
      expect(storage, isA<SessionStorage>());
    });

    test('setString stores via box.put', () async {
      await storage.setString('key', 'value');
      expect(box.get('key'), 'value');
    });

    test('getString returns null for missing key', () async {
      expect(await storage.getString('missing'), isNull);
    });

    test('getString returns stored value', () async {
      await storage.setString('key', 'hello');
      expect(await storage.getString('key'), 'hello');
    });

    test('setInt stores via box.put', () async {
      await storage.setInt('age', 25);
      expect(box.get('age'), 25);
    });

    test('getInt returns stored int', () async {
      await storage.setInt('age', 30);
      expect(await storage.getInt('age'), 30);
    });

    test('getInt returns null for missing key', () async {
      expect(await storage.getInt('missingInt'), isNull);
    });

    test('setStringList stores via box.put', () async {
      await storage.setStringList('tags', ['dart', 'flutter']);
      final stored = box.get('tags');
      expect(stored, ['dart', 'flutter']);
    });

    test('getStringList returns stored list', () async {
      await storage.setStringList('tags', ['a', 'b']);
      expect(await storage.getStringList('tags'), ['a', 'b']);
    });

    test('getStringList returns null for missing key', () async {
      expect(await storage.getStringList('missing'), isNull);
    });

    test('getStringList casts List to List<String>', () async {
      await box.put('list', <String>['x', 'y', 'z']);
      final result = await storage.getStringList('list');
      expect(result, ['x', 'y', 'z']);
    });

    test('getStringList returns null on non-list value', () async {
      await box.put('notList', 'just a string');
      final result = await storage.getStringList('notList');
      expect(result, isNull);
    });

    test('remove deletes via box.delete', () async {
      await storage.setString('key', 'value');
      expect(box.get('key'), 'value');
      await storage.remove('key');
      expect(box.get('key'), null);
    });

    test('remove on missing key does not throw', () async {
      await storage.remove('neverThere');
    });

    test('clear deletes all via box.clear', () async {
      await storage.setString('a', '1');
      await storage.setString('b', '2');
      await storage.setInt('c', 3);
      await storage.clear();

      expect(box.get('a'), null);
      expect(box.get('b'), null);
      expect(box.get('c'), null);
    });

    test('clear on empty storage does not throw', () async {
      await storage.clear();
    });

    test('json extension works on HiveSessionStorage', () async {
      await storage.setJson('config', {'theme': 'dark'});
      final stored = box.get('config');
      expect(stored, isA<String>());
      expect(await storage.getJson('config'), {'theme': 'dark'});
    });
  });

  // ── SessionStorageJson extension ────────────────────────────────────

  group('SessionStorageJson extension', () {
    late InMemorySessionStorage storage;

    setUp(() {
      storage = InMemorySessionStorage();
    });

    test('setJson stores a JSON-encoded string', () async {
      await storage.setJson('settings', {'notifications': true, 'volume': 0.8});
      final raw = await storage.getString('settings');
      expect(raw, contains('"notifications"'));
      expect(raw, contains('true'));
    });

    test('getJson decodes a JSON string back to map', () async {
      await storage.setJson('data', {'id': 1, 'name': 'test'});
      final result = await storage.getJson('data');
      expect(result, {'id': 1, 'name': 'test'});
    });

    test('setJson then getJson round-trip with nested maps', () async {
      final nested = {
        'user': {
          'name': 'Alice',
          'profile': {'age': 30, 'active': true}
        }
      };
      await storage.setJson('nested', nested);
      final result = await storage.getJson('nested');
      expect(result, nested);
    });

    test('getJson on missing key returns null', () async {
      expect(await storage.getJson('nothing'), isNull);
    });

    test('getJson on non-JSON string returns null', () async {
      await storage.setString('plain', 'not json at all');
      expect(await storage.getJson('plain'), isNull);
    });

    test('getJson on empty string returns null', () async {
      await storage.setString('empty', '');
      expect(await storage.getJson('empty'), isNull);
    });

    test('setJson with empty map round-trips', () async {
      await storage.setJson('emptyMap', {});
      expect(await storage.getJson('emptyMap'), <String, dynamic>{});
    });

    test('setJson with list value produces null on getJson', () async {
      await storage.setString('listJson', '[1,2,3]');
      expect(await storage.getJson('listJson'), isNull);
    });
  });
}
