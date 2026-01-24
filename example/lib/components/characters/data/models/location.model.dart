// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$Location implements FactoryModelWatcher, Location {
  _$Location({
    required this.name,
    required this.url,
  });

  factory _$Location.fromJson(Map<String, Object?> json) {
    return _$Location(
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

abstract class _$LocationContract {
  String get name;

  String get url;
}
