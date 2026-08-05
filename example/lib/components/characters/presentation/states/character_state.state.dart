// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'character_state.dart';

// **************************************************************************
// StateModelGenerator
// **************************************************************************

mixin _$CharacterState {
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(Character character) loaded,
    required T Function(List<Character> characters) characterList,
    required T Function(String message) error,
  }) {
    return switch (this) {
      CharacterStateInitial e => initial(),
      CharacterStateLoading e => loading(),
      CharacterStateLoaded e => loaded(e.character),
      CharacterStateCharacterList e => characterList(e.characters),
      CharacterStateError e => error(e.message),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(Character character)? loaded,
    T Function(List<Character> characters)? characterList,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      CharacterStateInitial e => initial?.call() ?? orElse(),
      CharacterStateLoading e => loading?.call() ?? orElse(),
      CharacterStateLoaded e => loaded?.call(e.character) ?? orElse(),
      CharacterStateCharacterList e =>
        characterList?.call(e.characters) ?? orElse(),
      CharacterStateError e => error?.call(e.message) ?? orElse(),
      _ => orElse(),
    };
  }

  T map<T>({
    required T Function(CharacterStateInitial value) initial,
    required T Function(CharacterStateLoading value) loading,
    required T Function(CharacterStateLoaded value) loaded,
    required T Function(CharacterStateCharacterList value) characterList,
    required T Function(CharacterStateError value) error,
  }) {
    return switch (this) {
      CharacterStateInitial e => initial(e),
      CharacterStateLoading e => loading(e),
      CharacterStateLoaded e => loaded(e),
      CharacterStateCharacterList e => characterList(e),
      CharacterStateError e => error(e),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeMap<T>({
    T Function(CharacterStateInitial value)? initial,
    T Function(CharacterStateLoading value)? loading,
    T Function(CharacterStateLoaded value)? loaded,
    T Function(CharacterStateCharacterList value)? characterList,
    T Function(CharacterStateError value)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      CharacterStateInitial e => initial?.call(e) ?? orElse(),
      CharacterStateLoading e => loading?.call(e) ?? orElse(),
      CharacterStateLoaded e => loaded?.call(e) ?? orElse(),
      CharacterStateCharacterList e => characterList?.call(e) ?? orElse(),
      CharacterStateError e => error?.call(e) ?? orElse(),
      _ => orElse(),
    };
  }
}

class CharacterStateInitial extends CharacterState {
  const CharacterStateInitial() : super._();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterStateInitial;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode;
  }

  @override
  String toString() {
    return 'CharacterStateInitial()';
  }
}

class CharacterStateLoading extends CharacterState {
  const CharacterStateLoading() : super._();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterStateLoading;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode;
  }

  @override
  String toString() {
    return 'CharacterStateLoading()';
  }
}

class CharacterStateLoaded extends CharacterState {
  const CharacterStateLoaded({required this.character}) : super._();

  final Character character;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterStateLoaded && other.character == character;
  }

  @override
  int get hashCode {
    return character.hashCode;
  }

  @override
  String toString() {
    return 'CharacterStateLoaded(character: $character)';
  }

  CharacterStateLoaded copyWith({Character? character}) {
    return CharacterStateLoaded(character: character ?? this.character);
  }
}

class CharacterStateCharacterList extends CharacterState {
  const CharacterStateCharacterList({required this.characters}) : super._();

  final List<Character> characters;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterStateCharacterList &&
        _listEquals(other.characters, characters);
  }

  @override
  int get hashCode {
    return characters.hashCode;
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

  @override
  String toString() {
    return 'CharacterStateCharacterList(characters: $characters)';
  }

  CharacterStateCharacterList copyWith({List<Character>? characters}) {
    return CharacterStateCharacterList(
      characters: characters ?? this.characters,
    );
  }
}

class CharacterStateError extends CharacterState {
  const CharacterStateError({required this.message}) : super._();

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterStateError && other.message == message;
  }

  @override
  int get hashCode {
    return message.hashCode;
  }

  @override
  String toString() {
    return 'CharacterStateError(message: $message)';
  }

  CharacterStateError copyWith({String? message}) {
    return CharacterStateError(message: message ?? this.message);
  }
}
