import 'package:dragonfly/framework/contracts/models/factory_model_watcher.dart';

enum DataTypeEnum {
  isClass,
  isObject,
  isString,
  isDouble,
  isInt,
  isBool,
  isList,
  isMap,
  isSet,
  isNull
}

class JsonDatatypeMapper {
  static T mapForGeneric<T>(Map<String, Object?> json, String jsonKey,
      {T? defaultValue, bool mustWithDefault = false}) {
    try {
      if (json.containsKey(jsonKey)) {
        if (json[jsonKey] != null) {
          return json[jsonKey] as T;
        }
      }
    } catch (e, s) {
      print(
          '[WARNING] Problem identifying "$jsonKey" on json map, e: $e => $s');
    }
    if (mustWithDefault && defaultValue == null) {
      throw Exception('[WARNING] Default value is wrong for key: "$jsonKey"');
    }
    return defaultValue as T;
  }

  static List<T> mapGenericList<T>(
      List value, T Function(dynamic e) factoryFn) {
    return value.map((e) {
      if (T is int || T is double || T is bool || T is String || T is Map) {
        return e as T;
      }
      if (T is List) {
        return mapGenericList(e, factoryFn) as T;
      }
      // if (T is FactoryModelWatcher) {
      return factoryFn(e);
      // }
    }).toList();
  }
}
