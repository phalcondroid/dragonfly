// ---------------------------------------------------------------------------
// Extended InMemorySessionStorage tests — type casting, edge cases for
// remove/clear, bulk operations, empty-state safety.
// ---------------------------------------------------------------------------

// ignore_for_file: strict_raw_type, inference_failure_on_function_invocation

import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/session/session_storage.dart'
    show SessionStorageJson;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySessionStorage storage;

  setUp(() {
    storage = InMemorySessionStorage();
  });

  group('type casting edge cases', () {
    test('getString on an int value throws TypeError', () async {
      await storage.setInt('age', 42);
      expect(
        () async => await storage.getString('age'),
        throwsA(isA<TypeError>()),
      );
    });

    test('getInt on a string value throws TypeError', () async {
      await storage.setString('name', 'Alice');
      expect(
        () async => await storage.getInt('name'),
        throwsA(isA<TypeError>()),
      );
    });

    test('getStringList on a string value throws TypeError', () async {
      await storage.setString('tags', 'dart');
      expect(
        () async => await storage.getStringList('tags'),
        throwsA(isA<TypeError>()),
      );
    });

    test('getStringList on an int value throws TypeError', () async {
      await storage.setInt('count', 5);
      expect(
        () async => await storage.getStringList('count'),
        throwsA(isA<TypeError>()),
      );
    });

    test('getInt on a stringList value throws TypeError', () async {
      await storage.setStringList('ids', ['a', 'b']);
      expect(
        () async => await storage.getInt('ids'),
        throwsA(isA<TypeError>()),
      );
    });

    test('getString on a stringList value throws TypeError', () async {
      await storage.setStringList('items', ['x', 'y']);
      expect(
        () async => await storage.getString('items'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('remove edge cases', () {
    test('remove on non-existent key does not throw', () async {
      await storage.remove('nonExistent');
    });

    test('remove on already-removed key does not throw', () async {
      await storage.setString('key', 'value');
      await storage.remove('key');
      await storage.remove('key');
    });

    test('remove then get returns null', () async {
      await storage.setString('name', 'Alice');
      expect(await storage.getString('name'), 'Alice');

      await storage.remove('name');
      expect(await storage.getString('name'), isNull);
    });
  });

  group('clear edge cases', () {
    test('clear on empty storage does not throw', () async {
      await storage.clear();
    });

    test('clear twice does not throw', () async {
      await storage.setString('a', '1');
      await storage.clear();
      await storage.clear();
    });

    test('clear then put works correctly', () async {
      await storage.setString('a', '1');
      await storage.clear();

      await storage.setString('b', '2');
      expect(await storage.getString('b'), '2');
      expect(await storage.getString('a'), isNull);
    });
  });

  group('put then get round-trip', () {
    test('put string then get same key returns correct value', () async {
      await storage.setString('greeting', 'hello world');

      expect(await storage.getString('greeting'), 'hello world');
    });

    test('put int then get same key returns correct value', () async {
      await storage.setInt('count', 99);

      expect(await storage.getInt('count'), 99);
    });

    test('put stringList then get same key returns correct value', () async {
      await storage.setStringList('colors', ['red', 'green', 'blue']);

      expect(await storage.getStringList('colors'), ['red', 'green', 'blue']);
    });
  });

  group('multiple keys', () {
    test('put multiple keys of different types and retrieve all', () async {
      await storage.setString('username', 'john_doe');
      await storage.setInt('age', 30);
      await storage.setStringList('roles', ['admin', 'user']);
      await storage.setString('email', 'john@example.com');
      await storage.setInt('score', 100);

      expect(await storage.getString('username'), 'john_doe');
      expect(await storage.getInt('age'), 30);
      expect(await storage.getStringList('roles'), ['admin', 'user']);
      expect(await storage.getString('email'), 'john@example.com');
      expect(await storage.getInt('score'), 100);
    });

    test('put many keys then overwrite and verify others unchanged', () async {
      await storage.setString('a', '1');
      await storage.setString('b', '2');
      await storage.setString('c', '3');

      await storage.setString('b', 'updated');

      expect(await storage.getString('a'), '1');
      expect(await storage.getString('b'), 'updated');
      expect(await storage.getString('c'), '3');
    });
  });

  group('different types', () {
    test('store and retrieve various types', () async {
      await storage.setString('title', 'Dragonfly');
      await storage.setInt('version', 1);
      await storage.setInt('zero', 0);
      await storage.setInt('negative', -5);
      await storage.setStringList('empty', []);
      await storage.setStringList('single', ['one']);
      await storage.setStringList('multiple', ['a', 'b', 'c']);

      expect(await storage.getString('title'), 'Dragonfly');
      expect(await storage.getInt('version'), 1);
      expect(await storage.getInt('zero'), 0);
      expect(await storage.getInt('negative'), -5);
      expect(await storage.getStringList('empty'), isEmpty);
      expect(await storage.getStringList('single'), ['one']);
      expect(await storage.getStringList('multiple'), ['a', 'b', 'c']);
    });

    test('store empty string', () async {
      await storage.setString('blank', '');

      expect(await storage.getString('blank'), '');
    });

    test('store long string', () async {
      final longString = 'x' * 10000;
      await storage.setString('long', longString);

      expect(await storage.getString('long'), longString);
    });

    test('store stringList with duplicates', () async {
      await storage.setStringList('tags', ['a', 'b', 'a', 'b']);

      expect(await storage.getStringList('tags'), ['a', 'b', 'a', 'b']);
    });
  });

  group('contains-like behavior', () {
    test('getString returns non-null after setString', () async {
      await storage.setString('key', 'value');
      expect(await storage.getString('key'), isNotNull);
    });

    test('getString returns null after remove', () async {
      await storage.setString('key', 'value');
      await storage.remove('key');
      expect(await storage.getString('key'), isNull);
    });

    test('getInt returns non-null after setInt', () async {
      await storage.setInt('key', 1);
      expect(await storage.getInt('key'), isNotNull);
    });

    test('getInt returns null after remove', () async {
      await storage.setInt('key', 1);
      await storage.remove('key');
      expect(await storage.getInt('key'), isNull);
    });

    test('getStringList returns non-null after setStringList', () async {
      await storage.setStringList('key', ['a']);
      expect(await storage.getStringList('key'), isNotNull);
    });

    test('getStringList returns null after remove', () async {
      await storage.setStringList('key', ['a']);
      await storage.remove('key');
      expect(await storage.getStringList('key'), isNull);
    });
  });

  group('json extension on storage', () {
    test('setJson stores and getJson retrieves a map', () async {
      await storage.setJson('config', {'theme': 'dark', 'lang': 'en'});

      final result = await storage.getJson('config');
      expect(result, {'theme': 'dark', 'lang': 'en'});
    });

    test('getJson on non-existent key returns null', () async {
      final result = await storage.getJson('missing');
      expect(result, isNull);
    });

    test('getJson on a non-JSON string returns null', () async {
      await storage.setString('plain', 'not json');

      final result = await storage.getJson('plain');
      expect(result, isNull);
    });

    test('setJson with empty map', () async {
      await storage.setJson('empty', {});

      final result = await storage.getJson('empty');
      expect(result, <String, dynamic>{});
    });

    test('setJson with nested map', () async {
      await storage.setJson('nested', {
        'user': {'name': 'Alice', 'settings': {'notifications': true}}
      });

      final result = await storage.getJson('nested');
      expect(result?['user'], {'name': 'Alice', 'settings': {'notifications': true}});
    });
  });
}
