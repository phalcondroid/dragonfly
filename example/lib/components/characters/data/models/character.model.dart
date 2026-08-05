// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

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
      id: JsonDatatypeMapper.mapForGeneric<int>(
        json,
        'id',
        defaultValue: 0,
        mustWithDefault: true,
      ),
      name: JsonDatatypeMapper.mapForGeneric<String>(
        json,
        'name',
        defaultValue: null,
        mustWithDefault: false,
      ),
      status: JsonDatatypeMapper.mapForGeneric<String>(
        json,
        'status',
        defaultValue: null,
        mustWithDefault: false,
      ),
      species: JsonDatatypeMapper.mapForGeneric<String>(
        json,
        'species',
        defaultValue: null,
        mustWithDefault: false,
      ),
      type: JsonDatatypeMapper.mapForGeneric<String>(
        json,
        'type',
        defaultValue: null,
        mustWithDefault: false,
      ),
      gender: JsonDatatypeMapper.mapForGeneric<String>(
        json,
        'gender',
        defaultValue: null,
        mustWithDefault: false,
      ),
      origin: JsonDatatypeMapper.mapNestedObject<Origin>(
        json,
        'origin',
        (map) => Origin.fromJson(map),
      ),
      location: JsonDatatypeMapper.mapNestedObject<Location>(
        json,
        'location',
        (map) => Location.fromJson(map),
      ),
      image: JsonDatatypeMapper.mapForGeneric<String>(
        json,
        'image',
        defaultValue: null,
        mustWithDefault: false,
      ),
      episode: JsonDatatypeMapper.mapGenericList<String>(
        json['episode'] as List?,
        (e) => e as String,
      ),
      url: JsonDatatypeMapper.mapForGeneric<String>(
        json,
        'url',
        defaultValue: null,
        mustWithDefault: false,
      ),
      created: JsonDatatypeMapper.mapForGeneric<String>(
        json,
        'created',
        defaultValue: null,
        mustWithDefault: false,
      ),
    );
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'species': species,
      'type': type,
      'gender': gender,
      'origin': origin.toJson(),
      'location': location.toJson(),
      'image': image,
      'episode': episode,
      'url': url,
      'created': created,
    };
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'status': status,
      'species': species,
      'type': type,
      'gender': gender,
      'origin': origin.toJson(),
      'location': location.toJson(),
      'image': image,
      'episode': episode,
      'url': url,
      'created': created,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Character &&
        other.id == id &&
        other.name == name &&
        other.status == status &&
        other.species == species &&
        other.type == type &&
        other.gender == gender &&
        other.origin == origin &&
        other.location == location &&
        other.image == image &&
        _listEquals(other.episode, episode) &&
        other.url == url &&
        other.created == created;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        status.hashCode ^
        species.hashCode ^
        type.hashCode ^
        gender.hashCode ^
        origin.hashCode ^
        location.hashCode ^
        image.hashCode ^
        episode.hashCode ^
        url.hashCode ^
        created.hashCode;
  }

  @override
  String toString() {
    return 'Character(id: $id, name: $name, status: $status, species: $species, type: $type, gender: $gender, origin: $origin, location: $location, image: $image, episode: $episode, url: $url, created: $created)';
  }

  Character copyWith({
    int? id,
    String? name,
    String? status,
    String? species,
    String? type,
    String? gender,
    Origin? origin,
    Location? location,
    String? image,
    List<String>? episode,
    String? url,
    String? created,
  }) {
    return _$Character(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      species: species ?? this.species,
      type: type ?? this.type,
      gender: gender ?? this.gender,
      origin: origin ?? this.origin,
      location: location ?? this.location,
      image: image ?? this.image,
      episode: episode ?? this.episode,
      url: url ?? this.url,
      created: created ?? this.created,
    );
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static bool _setEquals<T>(Set<T>? a, Set<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
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

  Map<String, dynamic> toJson();
  Map<String, Object?> toMap();
  Character copyWith({
    int? id,
    String? name,
    String? status,
    String? species,
    String? type,
    String? gender,
    Origin? origin,
    Location? location,
    String? image,
    List<String>? episode,
    String? url,
    String? created,
  });
}
