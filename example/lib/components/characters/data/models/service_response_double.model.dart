// GENERATED CODE - DO NOT MODIFY BY HAND

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
        info: JsonDatatypeMapper.mapForGeneric<Map<String, Object?>>(
            json, 'info', defaultValue: null, mustWithDefault: false),
        result: JsonDatatypeMapper.mapGenericList<R>(
            json['result'] as List, fromJsonR),
        res: JsonDatatypeMapper.mapForGeneric<T>(json, 'res',
            defaultValue: null, mustWithDefault: false));
  }

  @override
  final Map<String, Object?> info;

  @override
  final List<R> result;

  @override
  final T res;
}

abstract class _$ServiceResponseDoubleContract<T, R> {
  Map<String, Object?> get info;

  List<R> get result;

  T get res;
}
