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
        name: JsonDatatypeMapper.mapForGeneric<String>(
          json,
          'name',
          defaultValue: null,
          mustWithDefault: false,
        ),
        url: JsonDatatypeMapper.mapForGeneric<String>(
          json,
          'url',
          defaultValue: null,
          mustWithDefault: false,
        ));
  }

  @override
  final String name;

  @override
  final String url;

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url};
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{'name': name, 'url': url};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.name == name && other.url == url;
  }

  @override
  int get hashCode {
    return name.hashCode ^ url.hashCode;
  }

  @override
  String toString() {
    return 'Location(name: $name, url: $url)';
  }
}

abstract class _$LocationContract {
  String get name;

  String get url;
}
