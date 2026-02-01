// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_response.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$ServiceResponse<T> implements FactoryModelWatcher, ServiceResponse<T> {
  _$ServiceResponse({
    required this.info,
    required this.results,
  });

  factory _$ServiceResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) {
    return _$ServiceResponse(
        info: JsonDatatypeMapper.mapNestedObject<Info>(
          json,
          'info',
          (map) => Info.fromJson(map),
        ),
        results: JsonDatatypeMapper.mapGenericListForTypeParameter<T>(
          json['results'] as List?,
          fromJsonT,
        ));
  }

  @override
  final Info info;

  @override
  final List<T> results;

  Map<String, dynamic> toJson(dynamic Function(T value) _toJsonT) {
    return {
      'info': info.toJson(),
      'results': results.map((e) => _toJsonT(e)).toList()
    };
  }

  Map<String, Object?> toMap(Object? Function(T value) _toMapT) {
    return <String, Object?>{
      'info': info.toMap(),
      'results': results.map((e) => _toMapT(e)).toList()
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceResponse &&
        other.info == info &&
        _listEquals(other.results, results);
  }

  @override
  int get hashCode {
    return info.hashCode ^ results.hashCode;
  }

  @override
  String toString() {
    return 'ServiceResponse(info: $info, results: $results)';
  }

  static bool _listEquals<T>(
    List<T>? a,
    List<T>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(
    Map<K, V>? a,
    Map<K, V>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static bool _setEquals<T>(
    Set<T>? a,
    Set<T>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

abstract class _$ServiceResponseContract<T> {
  Info get info;

  List<T> get results;
}
