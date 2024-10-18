// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$Character implements FactoryModelWatcher, Character {
  _$Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.type,
    required this.gender,
    required this.origin,
    required this.location,
    required this.image,
    required this.episode,
    required this.url,
    required this.created,
    required this.setObj,
    required this.map,
    this.obj,
    required this.devices,
  });

  factory _$Character.fromJson(Map<String, Object?> json) {
    return _$Character(
        id: JsonDatatypeMapper.mapForGeneric<int>(json, 'id',
            defaultValue: 123, mustWithDefault: true),
        name: JsonDatatypeMapper.mapForGeneric<String>(json, 'name',
            defaultValue: null, mustWithDefault: false),
        status: JsonDatatypeMapper.mapForGeneric<bool>(json, 'status',
            defaultValue: null, mustWithDefault: false),
        species: JsonDatatypeMapper.mapForGeneric<String>(json, 'species',
            defaultValue: null, mustWithDefault: false),
        type: JsonDatatypeMapper.mapForGeneric<String>(json, 'type',
            defaultValue: null, mustWithDefault: false),
        gender: JsonDatatypeMapper.mapForGeneric<String>(json, 'gender',
            defaultValue: null, mustWithDefault: false),
        origin: Origin.fromJson(
          json['origin'] as Map<String, Object?>,
        ),
        location: JsonDatatypeMapper.mapForGeneric<String>(json, 'location',
            defaultValue: null, mustWithDefault: false),
        image: JsonDatatypeMapper.mapForGeneric<String>(json, 'image',
            defaultValue: null, mustWithDefault: false),
        episode: JsonDatatypeMapper.mapGenericList<String>(
            json['episode'] as List, (item) => item),
        url: JsonDatatypeMapper.mapForGeneric<String>(json, 'url',
            defaultValue: null, mustWithDefault: false),
        created: JsonDatatypeMapper.mapForGeneric<String>(json, 'created',
            defaultValue: null, mustWithDefault: false),
        setObj: JsonDatatypeMapper.mapForGeneric<Set<Origin>>(json, 'setObj',
            defaultValue: null, mustWithDefault: false),
        map: JsonDatatypeMapper.mapForGeneric<Map<String, int>>(json, 'map',
            defaultValue: null, mustWithDefault: false),
        obj: JsonDatatypeMapper.mapForGeneric<Object?>(json, 'obj',
            defaultValue: null, mustWithDefault: false),
        devices: JsonDatatypeMapper.mapGenericList<Object?>(
            json['devices'] as List, (item) => item));
  }

  final int id;

  final String name;

  final bool status;

  final String species;

  final String type;

  final String gender;

  final Origin origin;

  final String location;

  final String image;

  final List<String> episode;

  final String url;

  final String created;

  final Set<Origin> setObj;

  final Map<String, int> map;

  final Object? obj;

  final List<Object?> devices;
}

abstract class _$CharacterContract {
  int get id;

  String get name;

  bool get status;

  String get species;

  String get type;

  String get gender;

  Origin get origin;

  String get location;

  String get image;

  List<String> get episode;

  String get url;

  String get created;

  Set<Origin> get setObj;

  Map<String, int> get map;

  Object? get obj;

  List<Object?> get devices;
}
