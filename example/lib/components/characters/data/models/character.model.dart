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
  });

  factory _$Character.fromJson(Map<String, Object?> json) {
    return _$Character(
        id: JsonDatatypeMapper.mapForGeneric<int>(json, 'id',
            defaultValue: 123, mustWithDefault: true),
        name: JsonDatatypeMapper.mapForGeneric<String>(json, 'name',
            defaultValue: null, mustWithDefault: false),
        status: JsonDatatypeMapper.mapForGeneric<String>(json, 'status',
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
        location: Location.fromJson(
          json['location'] as Map<String, Object?>,
        ),
        image: JsonDatatypeMapper.mapForGeneric<String>(json, 'image',
            defaultValue: null, mustWithDefault: false),
        episode: JsonDatatypeMapper.mapGenericList<String>(
            json['episode'] as List, (item) => item),
        url: JsonDatatypeMapper.mapForGeneric<String>(json, 'url',
            defaultValue: null, mustWithDefault: false),
        created: JsonDatatypeMapper.mapForGeneric<String>(json, 'created',
            defaultValue: null, mustWithDefault: false));
  }

  @override
  final int id;

  @override
  final String name;

  @override
  final String status;

  @override
  final String species;

  @override
  final String type;

  @override
  final String gender;

  @override
  final Origin origin;

  @override
  final Location location;

  @override
  final String image;

  @override
  final List<String> episode;

  @override
  final String url;

  @override
  final String created;
}

abstract class _$CharacterContract {
  int get id;

  String get name;

  String get status;

  String get species;

  String get type;

  String get gender;

  Origin get origin;

  Location get location;

  String get image;

  List<String> get episode;

  String get url;

  String get created;
}
