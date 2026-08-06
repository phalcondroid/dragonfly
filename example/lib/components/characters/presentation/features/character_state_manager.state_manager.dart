// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'character_state_manager.dart';

// **************************************************************************
// StateManagerGenerator
// **************************************************************************

/// Controller for [CharacterStateManager].
///
/// Owns the state and wraps the delegate: `@Event` methods emit
/// `loading` before the body runs and `error` if it throws.
/// Registered in DI as a lazy singleton by the generated
/// `configureDependencies`.
class $CharacterStateManagerController
    extends DragonflyController<CharacterState> {
  $CharacterStateManagerController(this._delegate)
    : super(const CharacterState.initial());

  final CharacterStateManager _delegate;

  @override
  bool get loggingEnabled => true;

  Future<void> fetchCharacter(int id) async {
    emit(const CharacterState.loading());
    try {
      emit(await _delegate.fetchCharacter(id));
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  Future<void> fetchAllCharacters() async {
    emit(const CharacterState.loading());
    try {
      emit(await _delegate.fetchAllCharacters());
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  Future<void> deleteCharacter(Character character) async {
    emit(const CharacterState.loading());
    try {
      emit(await _delegate.deleteCharacter(character));
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  Future<void> updateCharacter(Character character, String newName) async {
    emit(const CharacterState.loading());
    try {
      emit(await _delegate.updateCharacter(character, newName));
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  Future<void> reset() async {
    emit(const CharacterState.loading());
    try {
      emit(await _delegate.reset());
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  Future<void> searchByName(String name) async => schedule(
    'searchByName',
    () => _searchByName(name),
    debounce: const Duration(microseconds: 300000),
  );

  Future<void> _searchByName(String name) async {
    emit(const CharacterState.loading());
    try {
      emit(await _delegate.searchByName(name));
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }

  Future<void> refreshThrottled() async => schedule(
    'refreshThrottled',
    () => _refreshThrottled(),
    throttle: const Duration(microseconds: 1000000),
  );

  Future<void> _refreshThrottled() async {
    emit(const CharacterState.loading());
    try {
      emit(await _delegate.refreshThrottled());
    } catch (e) {
      emit(CharacterState.error(message: e.toString()));
    }
  }
}
