// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'character_screen.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

/// View mixin for [CharacterStateManager].
///
/// Flattens the state API onto the bound widget: dispatch events by
/// calling them (`initialize(session)`), rebuild from state with
/// [when], [buildFor] or the typed `build<Event>` builders.
mixin $CharacterStateManager {
  $CharacterStateManagerController get _characterStateManagerController =>
      DragonflyContainer.I.get<$CharacterStateManagerController>();

  /// The current state of the bound controller.
  CharacterState get currentState => _characterStateManagerController.state;

  /// Dispatches the `fetchCharacter` event.
  Future<void> fetchCharacter(int id) =>
      _characterStateManagerController.fetchCharacter(id);

  /// Dispatches the `fetchAllCharacters` event.
  Future<void> fetchAllCharacters() =>
      _characterStateManagerController.fetchAllCharacters();

  /// Dispatches the `deleteCharacter` event.
  Future<void> deleteCharacter(Character character) =>
      _characterStateManagerController.deleteCharacter(character);

  /// Dispatches the `updateCharacter` event.
  Future<void> updateCharacter(Character character, String newName) =>
      _characterStateManagerController.updateCharacter(character, newName);

  /// Dispatches the `reset` event.
  Future<void> reset() => _characterStateManagerController.reset();

  /// Dispatches the `searchByName` event.
  Future<void> searchByName(String name) =>
      _characterStateManagerController.searchByName(name);

  /// Dispatches the `refreshThrottled` event.
  Future<void> refreshThrottled() =>
      _characterStateManagerController.refreshThrottled();

  /// Rebuilds on every state change. All variant callbacks are
  /// optional; [orElse] covers the unmatched ones.
  Widget when({
    Widget Function()? initial,
    Widget Function()? loading,
    Widget Function(Character character)? loaded,
    Widget Function(List<Character> characters)? characterList,
    Widget Function(String message)? error,
    required Widget Function() orElse,
  }) {
    return DragonflyStateBuilder<CharacterState>(
      controller: _characterStateManagerController,
      builder: (context, state) => state.maybeWhen(
        initial: initial,
        loading: loading,
        loaded: loaded,
        characterList: characterList,
        error: error,
        orElse: orElse,
      ),
    );
  }

  /// Builds only while the state is `CharacterState.initial`.
  Widget buildInitial(Widget Function() builder, {Widget Function()? orElse}) {
    return DragonflyStateBuilder<CharacterState>(
      controller: _characterStateManagerController,
      builder: (context, state) => state is CharacterStateInitial
          ? builder()
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `CharacterState.loading`.
  Widget buildLoading(Widget Function() builder, {Widget Function()? orElse}) {
    return DragonflyStateBuilder<CharacterState>(
      controller: _characterStateManagerController,
      builder: (context, state) => state is CharacterStateLoading
          ? builder()
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `CharacterState.loaded`.
  Widget buildLoaded(
    Widget Function(Character character) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<CharacterState>(
      controller: _characterStateManagerController,
      builder: (context, state) => state is CharacterStateLoaded
          ? builder(state.character)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `CharacterState.characterList`.
  Widget buildCharacterList(
    Widget Function(List<Character> characters) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<CharacterState>(
      controller: _characterStateManagerController,
      builder: (context, state) => state is CharacterStateCharacterList
          ? builder(state.characters)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `CharacterState.error`.
  Widget buildError(
    Widget Function(String message) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<CharacterState>(
      controller: _characterStateManagerController,
      builder: (context, state) => state is CharacterStateError
          ? builder(state.message)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// String-keyed builder. The payload is `dynamic` — prefer the
  /// typed `build<Event>` builders where possible.
  ///
  /// Payload rules: zero-field variants pass `null`, single-field variants
  /// pass the field value, multi-field variants pass the state object.
  Widget buildFor(
    String event,
    Widget Function(dynamic value) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<CharacterState>(
      controller: _characterStateManagerController,
      builder: (context, state) {
        final matched = switch (state) {
          CharacterStateInitial() => event == 'initial',
          CharacterStateLoading() => event == 'loading',
          CharacterStateLoaded() => event == 'loaded',
          CharacterStateCharacterList() => event == 'characterList',
          CharacterStateError() => event == 'error',
        };
        if (!matched) {
          return orElse?.call() ?? const SizedBox.shrink();
        }
        final value = switch (state) {
          CharacterStateInitial() => null,
          CharacterStateLoading() => null,
          CharacterStateLoaded(:final character) => character,
          CharacterStateCharacterList(:final characters) => characters,
          CharacterStateError(:final message) => message,
        };
        return builder(value);
      },
    );
  }
}
