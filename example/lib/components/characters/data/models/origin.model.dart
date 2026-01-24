// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'origin.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$Origin implements FactoryModelWatcher, Origin {
  _$Origin({
    required this.name,
    required this.url,
  });

  factory _$Origin.fromJson(Map<String, Object?> json) {
    return _$Origin(
        name: JsonDatatypeMapper.mapForGeneric<String>(json, 'name',
            defaultValue: null, mustWithDefault: false),
        url: JsonDatatypeMapper.mapForGeneric<String>(json, 'url',
            defaultValue: null, mustWithDefault: false));
  }

  @override
  final String name;

  @override
  final String url;
}

abstract class _$OriginContract {
  String get name;

  String get url;
}
