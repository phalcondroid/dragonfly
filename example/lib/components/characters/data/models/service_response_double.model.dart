// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'service_response_double.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$ServiceResponseDouble<T, R>
    implements FactoryModelWatcher, ServiceResponseDouble<T, R> {
  _$ServiceResponseDouble({
    required this.info,
    required this.result,
    required this.res,
  });

  factory _$ServiceResponseDouble.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
    R Function(Object? json) fromJsonR,
  ) {
    return _$ServiceResponseDouble(
      info: (json['info'] as Map<String, Object?>?) ?? <String, dynamic>{},
      result: JsonDatatypeMapper.mapGenericListForTypeParameter<R>(
        json['result'] as List?,
        fromJsonR,
      ),
      res: fromJsonT(json['res']),
    );
  }

  @override
  final Map<String, Object?> info;

  @override
  final List<R> result;

  @override
  final T res;

  Map<String, dynamic> toJson(
    dynamic Function(T value) _toJsonT,
    dynamic Function(R value) _toJsonR,
  ) {
    return {
      'info': info,
      'result': result.map((e) => _toJsonR(e)).toList(),
      'res': _toJsonT(res),
    };
  }

  Map<String, Object?> toMap(
    dynamic Function(T value) _toJsonT,
    dynamic Function(R value) _toJsonR,
  ) {
    return <String, Object?>{
      'info': info,
      'result': result.map((e) => _toJsonR(e)).toList(),
      'res': _toJsonT(res),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceResponseDouble &&
        _mapEquals(other.info, info) &&
        _listEquals(other.result, result) &&
        other.res == res;
  }

  @override
  int get hashCode {
    return info.hashCode ^ result.hashCode ^ res.hashCode;
  }

  @override
  String toString() {
    return 'ServiceResponseDouble(info: $info, result: $result, res: $res)';
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static bool _setEquals<T>(Set<T>? a, Set<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

abstract class _$ServiceResponseDoubleContract<T, R> {
  Map<String, Object?> get info;

  List<R> get result;

  T get res;
}
