// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_response.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$PaginatedResponse<I, T>
    implements FactoryModelWatcher, PaginatedResponse<I, T> {
  _$PaginatedResponse({
    required this.info,
    required this.results,
  });

  factory _$PaginatedResponse.fromJson(
    Map<String, Object?> json,
    I Function(Object? json) fromJsonI,
    T Function(Object? json) fromJsonT,
  ) {
    return _$PaginatedResponse(
        info: fromJsonI(json['info']),
        results: JsonDatatypeMapper.mapGenericListForTypeParameter<T>(
          json['results'] as List?,
          fromJsonT,
        ));
  }

  @override
  final I info;

  @override
  final List<T> results;

  Map<String, dynamic> toJson(
    dynamic Function(I value) _toJsonI,
    dynamic Function(T value) _toJsonT,
  ) {
    return {
      'info': _toJsonI(info),
      'results': results.map((e) => _toJsonT(e)).toList()
    };
  }

  Map<String, Object?> toMap(
    dynamic Function(I value) _toJsonI,
    dynamic Function(T value) _toJsonT,
  ) {
    return <String, Object?>{
      'info': _toJsonI(info),
      'results': results.map((e) => _toJsonT(e)).toList()
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginatedResponse &&
        other.info == info &&
        _listEquals(other.results, results);
  }

  @override
  int get hashCode {
    return info.hashCode ^ results.hashCode;
  }

  @override
  String toString() {
    return 'PaginatedResponse(info: $info, results: $results)';
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

abstract class _$PaginatedResponseContract<I, T> {
  I get info;

  List<T> get results;
}
