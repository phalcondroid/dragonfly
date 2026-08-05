// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'origin.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$Origin implements FactoryModelWatcher, Origin {
  _$Origin({required this.name, required this.url});

  factory _$Origin.fromJson(Map<String, Object?> json) {
    return _$Origin(
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
      ),
    );
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
    return other is Origin && other.name == name && other.url == url;
  }

  @override
  int get hashCode {
    return name.hashCode ^ url.hashCode;
  }

  @override
  String toString() {
    return 'Origin(name: $name, url: $url)';
  }
}

abstract class _$OriginContract {
  String get name;

  String get url;

  Map<String, dynamic> toJson();
  Map<String, Object?> toMap();
}
