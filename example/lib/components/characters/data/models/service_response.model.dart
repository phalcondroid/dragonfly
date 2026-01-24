// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_response.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$ServiceResponse<T> implements FactoryModelWatcher, ServiceResponse<T> {
  _$ServiceResponse({
    required this.info,
    required this.result,
  });

  factory _$ServiceResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) {
    return _$ServiceResponse(
        info: JsonDatatypeMapper.mapForGeneric<Info>(json, 'info',
            defaultValue: null, mustWithDefault: false),
        result: JsonDatatypeMapper.mapGenericList<T>(
            json['result'] as List, fromJsonT));
  }

  @override
  final Info info;

  @override
  final List<T> result;
}

abstract class _$ServiceResponseContract<T> {
  Info get info;

  List<T> get result;
}
