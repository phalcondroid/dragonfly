import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonMappingException', () {
    test('stores message', () {
      const e = JsonMappingException('test error');
      expect(e.message, 'test error');
    });

    test('toString includes message', () {
      const e = JsonMappingException('test error');
      expect(e.toString(), 'JsonMappingException: test error');
    });

    test('is an Exception', () {
      const e = JsonMappingException('test error');
      expect(e, isA<Exception>());
    });
  });

  group('DataTypeEnum', () {
    test('all values exist', () {
      expect(DataTypeEnum.values, [
        DataTypeEnum.isClass,
        DataTypeEnum.isObject,
        DataTypeEnum.isString,
        DataTypeEnum.isDouble,
        DataTypeEnum.isInt,
        DataTypeEnum.isBool,
        DataTypeEnum.isList,
        DataTypeEnum.isMap,
        DataTypeEnum.isSet,
        DataTypeEnum.isNull,
        DataTypeEnum.isDateTime,
        DataTypeEnum.isDynamic,
      ]);
    });
  });

  group('getDataType', () {
    test('null returns isNull', () {
      expect(JsonDatatypeMapper.getDataType(null), DataTypeEnum.isNull);
    });

    test('String returns isString', () {
      expect(JsonDatatypeMapper.getDataType('hello'), DataTypeEnum.isString);
    });

    test('int returns isInt', () {
      expect(JsonDatatypeMapper.getDataType(42), DataTypeEnum.isInt);
    });

    test('double returns isDouble', () {
      expect(JsonDatatypeMapper.getDataType(3.14), DataTypeEnum.isDouble);
    });

    test('bool returns isBool', () {
      expect(JsonDatatypeMapper.getDataType(true), DataTypeEnum.isBool);
    });

    test('List returns isList', () {
      expect(JsonDatatypeMapper.getDataType([]), DataTypeEnum.isList);
    });

    test('Map returns isMap', () {
      expect(JsonDatatypeMapper.getDataType({}), DataTypeEnum.isMap);
    });

    test('Set returns isSet', () {
      expect(JsonDatatypeMapper.getDataType(<String>{}), DataTypeEnum.isSet);
    });

    test('DateTime returns isDateTime', () {
      expect(
        JsonDatatypeMapper.getDataType(DateTime(2024)),
        DataTypeEnum.isDateTime,
      );
    });

    test('unknown object returns isObject', () {
      expect(
        JsonDatatypeMapper.getDataType(Object()),
        DataTypeEnum.isObject,
      );
    });
  });

  group('mapForGeneric', () {
    test('extracts a String value', () {
      final json = <String, Object?>{'name': 'Rick'};
      expect(JsonDatatypeMapper.mapForGeneric<String>(json, 'name'), 'Rick');
    });

    test('extracts an int value', () {
      final json = <String, Object?>{'age': 70};
      expect(JsonDatatypeMapper.mapForGeneric<int>(json, 'age'), 70);
    });

    test('extracts a double value', () {
      final json = <String, Object?>{'score': 4.5};
      expect(JsonDatatypeMapper.mapForGeneric<double>(json, 'score'), 4.5);
    });

    test('extracts a bool value', () {
      final json = <String, Object?>{'active': true};
      expect(JsonDatatypeMapper.mapForGeneric<bool>(json, 'active'), isTrue);
    });

    test('extracts a List value', () {
      final json = <String, Object?>{
        'tags': ['a', 'b'],
      };
      expect(JsonDatatypeMapper.mapForGeneric<List>(json, 'tags'), ['a', 'b']);
    });

    test('extracts a Map value', () {
      final json = <String, Object?>{
        'meta': {'key': 'value'},
      };
      final result = JsonDatatypeMapper.mapForGeneric<Map>(json, 'meta');
      expect(result, {'key': 'value'});
    });

    test('returns null for nullable type with missing key', () {
      final json = <String, Object?>{};
      expect(JsonDatatypeMapper.mapForGeneric<String?>(json, 'missing'), isNull);
    });

    test('returns null for nullable type with null value', () {
      final json = <String, Object?>{'name': null};
      expect(JsonDatatypeMapper.mapForGeneric<String?>(json, 'name'), isNull);
    });

    test('returns defaultValue when key is missing', () {
      final json = <String, Object?>{};
      expect(
        JsonDatatypeMapper.mapForGeneric<String>(
          json,
          'missing',
          defaultValue: 'fallback',
        ),
        'fallback',
      );
    });

    test('returns defaultValue when value is null', () {
      final json = <String, Object?>{'name': null};
      expect(
        JsonDatatypeMapper.mapForGeneric<String>(
          json,
          'name',
          defaultValue: 'fallback',
        ),
        'fallback',
      );
    });

    test('converts int to double', () {
      final json = <String, Object?>{'score': 5};
      final result = JsonDatatypeMapper.mapForGeneric<double>(json, 'score');
      expect(result, 5.0);
    });

    test('converts double to int', () {
      final json = <String, Object?>{'count': 3.0};
      final result = JsonDatatypeMapper.mapForGeneric<int>(json, 'count');
      expect(result, 3);
    });

    test('converts numeric String to int', () {
      final json = <String, Object?>{'count': '42'};
      final result = JsonDatatypeMapper.mapForGeneric<int>(json, 'count');
      expect(result, 42);
    });

    test('converts numeric String to double', () {
      final json = <String, Object?>{'score': '3.14'};
      final result = JsonDatatypeMapper.mapForGeneric<double>(json, 'score');
      expect(result, 3.14);
    });

    test('parses DateTime from String', () {
      final json = <String, Object?>{'created': '2024-01-15T10:30:00.000Z'};
      final result =
      JsonDatatypeMapper.mapForGeneric<DateTime>(json, 'created');
      expect(result.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('parses DateTime from int (milliseconds)', () {
      final json = <String, Object?>{'created': 0};
      final result =
      JsonDatatypeMapper.mapForGeneric<DateTime>(json, 'created');
      expect(result, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('returns null for nullable DateTime with missing key', () {
      final json = <String, Object?>{};
      expect(
        JsonDatatypeMapper.mapForGeneric<DateTime?>(json, 'missing'),
        isNull,
      );
    });

    test('returns defaultValue for null DateTime with default', () {
      final fallback = DateTime(2020);
      final json = <String, Object?>{'created': null};
      final result = JsonDatatypeMapper.mapForGeneric<DateTime>(
        json,
        'created',
        defaultValue: fallback,
      );
      expect(result, fallback);
    });

    test('mustWithDefault throws when key missing and no default', () {
      final json = <String, Object?>{};
      expect(
            () => JsonDatatypeMapper.mapForGeneric<String>(
          json,
          'name',
          mustWithDefault: true,
        ),
        throwsA(isA<JsonMappingException>()),
      );
    });

    test('throws on null value for non-nullable type', () {
      final json = <String, Object?>{'name': null};
      expect(
            () => JsonDatatypeMapper.mapForGeneric<String>(json, 'name'),
        throwsA(isA<JsonMappingException>()),
      );
    });

    test('throws on type mismatch', () {
      // A map cannot be cast to String and has no numeric parsing path
      final json = <String, Object?>{'name': <String, Object?>{'sub': 'val'}};
      expect(
            () => JsonDatatypeMapper.mapForGeneric<String>(json, 'name'),
        throwsA(isA<JsonMappingException>()),
      );
    });

    test('returns defaultValue on type mismatch error', () {
      final json = <String, Object?>{'name': <String, Object?>{'sub': 'val'}};
      expect(
        JsonDatatypeMapper.mapForGeneric<String>(
          json,
          'name',
          defaultValue: 'fallback',
        ),
        'fallback',
      );
    });

    test('extracts num value', () {
      final json = <String, Object?>{'value': 3};
      expect(JsonDatatypeMapper.mapForGeneric<num>(json, 'value'), 3);
    });
  });

  group('mapForTypeParameter', () {
    test('maps value using fromJson', () {
      final json = <String, Object?>{'name': 'Morty'};
      final result = JsonDatatypeMapper.mapForTypeParameter<String>(
        json,
        'name',
            (json) => 'Name: $json',
      );
      expect(result, 'Name: Morty');
    });

    test('returns null for nullable type with missing key', () {
      final json = <String, Object?>{};
      expect(
        JsonDatatypeMapper.mapForTypeParameter<String?>(
          json,
          'missing',
              (_) => 'never called',
        ),
        isNull,
      );
    });

    test('throws for non-nullable type with missing key', () {
      final json = <String, Object?>{};
      expect(
            () => JsonDatatypeMapper.mapForTypeParameter<String>(
          json,
          'missing',
              (_) => 'never called',
        ),
        throwsA(isA<JsonMappingException>()),
      );
    });
  });

  group('mapGenericList', () {
    test('converts a list of maps using factory', () {
      final list = [
        {'id': 1, 'name': 'Rick'},
        {'id': 2, 'name': 'Morty'},
      ];
      // Use a non-primitive type param so factory is used, not the primitive path
      final result = JsonDatatypeMapper.mapGenericList<Map<String, dynamic>>(
        list,
            (e) => Map<String, dynamic>.from(e as Map),
      );
      expect(result.length, 2);
      expect(result.first['name'], 'Rick');
    });

    test('returns empty list for null input', () {
      expect(JsonDatatypeMapper.mapGenericList<String>(null, (e) => ''), []);
    });

    test('throws for non-list input', () {
      expect(
            () => JsonDatatypeMapper.mapGenericList<String>(42, (e) => ''),
        throwsA(isA<JsonMappingException>()),
      );
    });

    test('handles primitive types directly', () {
      final list = [1, 2, 3];
      final result = JsonDatatypeMapper.mapGenericList<int>(list, (e) => 0);
      expect(result, [1, 2, 3]);
    });

    test('throws on null item for non-nullable type', () {
      final list = [1, null, 3];
      expect(
            () => JsonDatatypeMapper.mapGenericList<int>(list, (e) => 0),
        throwsA(isA<JsonMappingException>()),
      );
    });

    test('allows null items for nullable type', () {
      final list = [1, null, 3];
      final result = JsonDatatypeMapper.mapGenericList<int?>(list, (e) => 0);
      expect(result, [1, null, 3]);
    });

    test('handles nested lists', () {
      final list = [
        [1, 2],
        [3, 4],
      ];
      final result =
      JsonDatatypeMapper.mapGenericList<List<int>>(list, (e) => []);
      expect(result, [
        [1, 2],
        [3, 4],
      ]);
    });

    test('handles map values inside list', () {
      final list = [
        {'a': 1},
        {'b': 2},
      ];
      final result = JsonDatatypeMapper.mapGenericList<Map<String, int>>(
        list,
            (e) => <String, int>{},
      );
      expect(result, [
        {'a': 1},
        {'b': 2},
      ]);
    });
  });

  group('mapGenericListForTypeParameter', () {
    test('converts a list using fromJson', () {
      final list = [1, 2, 3];
      final result =
      JsonDatatypeMapper.mapGenericListForTypeParameter<String>(
        list,
            (e) => 'Item $e',
      );
      expect(result, ['Item 1', 'Item 2', 'Item 3']);
    });

    test('returns empty list for null input', () {
      expect(
        JsonDatatypeMapper.mapGenericListForTypeParameter<String>(
          null,
              (_) => '',
        ),
        [],
      );
    });

    test('throws for non-list input', () {
      expect(
            () =>
            JsonDatatypeMapper.mapGenericListForTypeParameter<String>(
              'not a list',
                  (_) => '',
            ),
        throwsA(isA<JsonMappingException>()),
      );
    });
  });

  group('mapGenericMap', () {
    test('converts map keys and values', () {
      final input = {'1': 'Rick', '2': 'Morty'};
      final result = JsonDatatypeMapper.mapGenericMap<int, String>(
        input,
            (k) => int.parse(k.toString()),
            (v) => 'Name: $v',
      );
      expect(result, {1: 'Name: Rick', 2: 'Name: Morty'});
    });

    test('returns empty map for null input', () {
      expect(
        JsonDatatypeMapper.mapGenericMap<String, String>(
          null,
              (k) => '',
              (v) => '',
        ),
        {},
      );
    });

    test('throws for non-map input', () {
      expect(
            () => JsonDatatypeMapper.mapGenericMap<String, String>(
          'not a map',
              (k) => '',
              (v) => '',
        ),
        throwsA(isA<JsonMappingException>()),
      );
    });
  });

  group('mapNullable', () {
    test('returns null for missing key', () {
      final json = <String, Object?>{};
      expect(
        JsonDatatypeMapper.mapNullable<String>(json, 'missing', (v) => '$v'),
        isNull,
      );
    });

    test('returns null for null value', () {
      final json = <String, Object?>{'key': null};
      expect(
        JsonDatatypeMapper.mapNullable<String>(json, 'key', (v) => '$v'),
        isNull,
      );
    });

    test('maps non-null value', () {
      final json = <String, Object?>{'key': 'hello'};
      expect(
        JsonDatatypeMapper.mapNullable<String>(json, 'key', (v) => 'Mapped: $v'),
        'Mapped: hello',
      );
    });
  });

  group('mapNestedObject', () {
    test('maps a nested map to an object', () {
      final json = <String, Object?>{
        'user': {'name': 'Rick', 'age': 70},
      };
      final result = JsonDatatypeMapper.mapNestedObject<String>(
        json,
        'user',
            (m) => (m['name'] as String?) ?? '',
      );
      expect(result, 'Rick');
    });

    test('returns null for nullable type with missing key', () {
      final json = <String, Object?>{};
      expect(
        JsonDatatypeMapper.mapNestedObject<String?>(json, 'user', (m) => ''),
        isNull,
      );
    });

    test('throws for non-nullable type with missing key', () {
      final json = <String, Object?>{};
      expect(
            () =>
            JsonDatatypeMapper.mapNestedObject<String>(json, 'user', (m) => ''),
        throwsA(isA<JsonMappingException>()),
      );
    });

    test('throws for non-map value', () {
      final json = <String, Object?>{'user': 'not a map'};
      expect(
            () =>
            JsonDatatypeMapper.mapNestedObject<String>(json, 'user', (m) => ''),
        throwsA(isA<JsonMappingException>()),
      );
    });

    test('handles Map typed value (not Map<String, Object?>)', () {
      final json = <String, Object?>{'user': {'name': 'Rick'}};
      final result = JsonDatatypeMapper.mapNestedObject<String>(
        json,
        'user',
            (m) => (m['name'] as String?) ?? '',
      );
      expect(result, 'Rick');
    });
  });

  group('mapNullableNestedObject', () {
    test('returns null for missing key', () {
      final json = <String, Object?>{};
      expect(
        JsonDatatypeMapper.mapNullableNestedObject<String>(
          json,
          'user',
              (m) => '',
        ),
        isNull,
      );
    });

    test('returns null for null value', () {
      final json = <String, Object?>{'user': null};
      expect(
        JsonDatatypeMapper.mapNullableNestedObject<String>(
          json,
          'user',
              (m) => '',
        ),
        isNull,
      );
    });

    test('maps a nested map', () {
      final json = <String, Object?>{
        'user': {'name': 'Morty'},
      };
      expect(
        JsonDatatypeMapper.mapNullableNestedObject<String>(
          json,
          'user',
              (m) => (m['name'] as String?) ?? '',
        ),
        'Morty',
      );
    });

    test('throws for non-map value', () {
      final json = <String, Object?>{'user': 42};
      expect(
            () => JsonDatatypeMapper.mapNullableNestedObject<String>(
          json,
          'user',
              (m) => '',
        ),
        throwsA(isA<JsonMappingException>()),
      );
    });
  });
}
