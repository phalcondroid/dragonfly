// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'character_search_screen.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

/// View mixin for [CharacterSearchStateManager].
///
/// Flattens the state API onto the bound widget: dispatch events by
/// calling them (`initialize(session)`), rebuild from state with
/// [when], [buildFor] or the typed `build<Event>` builders.
mixin $CharacterSearchStateManager {
  $CharacterSearchStateManagerController
  get _characterSearchStateManagerController =>
      DragonflyContainer.I.get<$CharacterSearchStateManagerController>();

  /// The current state of the bound controller.
  CharacterSearchStateManagerState get currentState =>
      _characterSearchStateManagerController.state;

  /// Dispatches the `search` event.
  Future<void> search(String name) =>
      _characterSearchStateManagerController.search(name);

  /// Dispatches the `clear` event.
  Future<void> clear() => _characterSearchStateManagerController.clear();

  /// Rebuilds on every state change. All variant callbacks are
  /// optional; [orElse] covers the unmatched ones.
  Widget when({
    Widget Function()? initial,
    Widget Function()? loading,
    Widget Function(String message)? error,
    Widget Function(List<Character> value)? search,
    Widget Function()? clear,
    required Widget Function() orElse,
  }) {
    return DragonflyStateBuilder<CharacterSearchStateManagerState>(
      controller: _characterSearchStateManagerController,
      builder: (context, state) => state.maybeWhen(
        initial: initial,
        loading: loading,
        error: error,
        search: search,
        clear: clear,
        orElse: orElse,
      ),
    );
  }

  /// Builds only while the state is `CharacterSearchStateManagerState.initial`.
  Widget buildInitial(Widget Function() builder, {Widget Function()? orElse}) {
    return DragonflyStateBuilder<CharacterSearchStateManagerState>(
      controller: _characterSearchStateManagerController,
      builder: (context, state) =>
          state is CharacterSearchStateManagerStateInitial
          ? builder()
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `CharacterSearchStateManagerState.loading`.
  Widget buildLoading(Widget Function() builder, {Widget Function()? orElse}) {
    return DragonflyStateBuilder<CharacterSearchStateManagerState>(
      controller: _characterSearchStateManagerController,
      builder: (context, state) =>
          state is CharacterSearchStateManagerStateLoading
          ? builder()
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `CharacterSearchStateManagerState.error`.
  Widget buildError(
    Widget Function(String message) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<CharacterSearchStateManagerState>(
      controller: _characterSearchStateManagerController,
      builder: (context, state) =>
          state is CharacterSearchStateManagerStateError
          ? builder(state.message)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `CharacterSearchStateManagerState.search`.
  Widget buildSearch(
    Widget Function(List<Character> value) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<CharacterSearchStateManagerState>(
      controller: _characterSearchStateManagerController,
      builder: (context, state) =>
          state is CharacterSearchStateManagerStateSearch
          ? builder(state.value)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `CharacterSearchStateManagerState.clear`.
  Widget buildClear(Widget Function() builder, {Widget Function()? orElse}) {
    return DragonflyStateBuilder<CharacterSearchStateManagerState>(
      controller: _characterSearchStateManagerController,
      builder: (context, state) =>
          state is CharacterSearchStateManagerStateClear
          ? builder()
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
    return DragonflyStateBuilder<CharacterSearchStateManagerState>(
      controller: _characterSearchStateManagerController,
      builder: (context, state) {
        final matched = switch (state) {
          CharacterSearchStateManagerStateInitial() => event == 'initial',
          CharacterSearchStateManagerStateLoading() => event == 'loading',
          CharacterSearchStateManagerStateError() => event == 'error',
          CharacterSearchStateManagerStateSearch() => event == 'search',
          CharacterSearchStateManagerStateClear() => event == 'clear',
        };
        if (!matched) {
          return orElse?.call() ?? const SizedBox.shrink();
        }
        final value = switch (state) {
          CharacterSearchStateManagerStateInitial() => null,
          CharacterSearchStateManagerStateLoading() => null,
          CharacterSearchStateManagerStateError(:final message) => message,
          CharacterSearchStateManagerStateSearch(:final value) => value,
          CharacterSearchStateManagerStateClear() => null,
        };
        return builder(value);
      },
    );
  }
}
