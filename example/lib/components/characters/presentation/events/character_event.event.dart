// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_event.dart';

// **************************************************************************
// EventModelGenerator
// **************************************************************************

mixin _$CharacterEvent {
  T when<T>({
    required T Function() loading,
    required T Function(int characterId) fetch,
    required T Function(Character character) delete,
    required T Function(Character character, String newName) update,
  }) {
    return switch (this) {
      CharacterEventLoading e => loading(),
      CharacterEventFetch e => fetch(e.characterId),
      CharacterEventDelete e => delete(e.character),
      CharacterEventUpdate e => update(e.character, e.newName),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeWhen<T>({
    T Function()? loading,
    T Function(int characterId)? fetch,
    T Function(Character character)? delete,
    T Function(Character character, String newName)? update,
    required T Function() orElse,
  }) {
    return switch (this) {
      CharacterEventLoading e => loading?.call() ?? orElse(),
      CharacterEventFetch e => fetch?.call(e.characterId) ?? orElse(),
      CharacterEventDelete e => delete?.call(e.character) ?? orElse(),
      CharacterEventUpdate e =>
        update?.call(e.character, e.newName) ?? orElse(),
      _ => orElse(),
    };
  }

  T map<T>({
    required T Function(CharacterEventLoading value) loading,
    required T Function(CharacterEventFetch value) fetch,
    required T Function(CharacterEventDelete value) delete,
    required T Function(CharacterEventUpdate value) update,
  }) {
    return switch (this) {
      CharacterEventLoading e => loading(e),
      CharacterEventFetch e => fetch(e),
      CharacterEventDelete e => delete(e),
      CharacterEventUpdate e => update(e),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeMap<T>({
    T Function(CharacterEventLoading value)? loading,
    T Function(CharacterEventFetch value)? fetch,
    T Function(CharacterEventDelete value)? delete,
    T Function(CharacterEventUpdate value)? update,
    required T Function() orElse,
  }) {
    return switch (this) {
      CharacterEventLoading e => loading?.call(e) ?? orElse(),
      CharacterEventFetch e => fetch?.call(e) ?? orElse(),
      CharacterEventDelete e => delete?.call(e) ?? orElse(),
      CharacterEventUpdate e => update?.call(e) ?? orElse(),
      _ => orElse(),
    };
  }
}

class CharacterEventLoading extends CharacterEvent {
  const CharacterEventLoading() : super._();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterEventLoading;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode;
  }

  @override
  String toString() {
    return 'CharacterEventLoading()';
  }
}

class CharacterEventFetch extends CharacterEvent {
  const CharacterEventFetch({required this.characterId}) : super._();

  final int characterId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterEventFetch && other.characterId == characterId;
  }

  @override
  int get hashCode {
    return characterId.hashCode;
  }

  @override
  String toString() {
    return 'CharacterEventFetch(characterId: $characterId)';
  }

  CharacterEventFetch copyWith({int? characterId}) {
    return CharacterEventFetch(characterId: characterId ?? this.characterId);
  }
}

class CharacterEventDelete extends CharacterEvent {
  const CharacterEventDelete({required this.character}) : super._();

  final Character character;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterEventDelete && other.character == character;
  }

  @override
  int get hashCode {
    return character.hashCode;
  }

  @override
  String toString() {
    return 'CharacterEventDelete(character: $character)';
  }

  CharacterEventDelete copyWith({Character? character}) {
    return CharacterEventDelete(character: character ?? this.character);
  }
}

class CharacterEventUpdate extends CharacterEvent {
  const CharacterEventUpdate({
    required this.character,
    required this.newName,
  }) : super._();

  final Character character;

  final String newName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterEventUpdate &&
        other.character == character &&
        other.newName == newName;
  }

  @override
  int get hashCode {
    return character.hashCode ^ newName.hashCode;
  }

  @override
  String toString() {
    return 'CharacterEventUpdate(character: $character, newName: $newName)';
  }

  CharacterEventUpdate copyWith({
    Character? character,
    String? newName,
  }) {
    return CharacterEventUpdate(
        character: character ?? this.character,
        newName: newName ?? this.newName);
  }
}
