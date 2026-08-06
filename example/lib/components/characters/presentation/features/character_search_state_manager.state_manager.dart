// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'character_search_state_manager.dart';

// **************************************************************************
// StateManagerGenerator
// **************************************************************************

/// State for [CharacterSearchStateManager], generated from its `@Event` methods.
///
/// Built-in variants: `initial` (starting state), `loading`
/// (emitted before every event body runs) and `error`
/// (emitted when an event throws).
sealed class CharacterSearchStateManagerState {
  const CharacterSearchStateManagerState._();

  const factory CharacterSearchStateManagerState.initial() =
      CharacterSearchStateManagerStateInitial;
  const factory CharacterSearchStateManagerState.loading() =
      CharacterSearchStateManagerStateLoading;
  const factory CharacterSearchStateManagerState.error({
    required String message,
  }) = CharacterSearchStateManagerStateError;
  const factory CharacterSearchStateManagerState.search({
    required List<Character> value,
  }) = CharacterSearchStateManagerStateSearch;
  const factory CharacterSearchStateManagerState.clear() =
      CharacterSearchStateManagerStateClear;

  /// Pattern match over all variants. Every callback is required.
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(String message) error,
    required T Function(List<Character> value) search,
    required T Function() clear,
  }) {
    final self = this;
    return switch (self) {
      CharacterSearchStateManagerStateInitial() => initial(),
      CharacterSearchStateManagerStateLoading() => loading(),
      CharacterSearchStateManagerStateError() => error(self.message),
      CharacterSearchStateManagerStateSearch() => search(self.value),
      CharacterSearchStateManagerStateClear() => clear(),
    };
  }

  /// Pattern match over variants, falling back to [orElse].
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String message)? error,
    T Function(List<Character> value)? search,
    T Function()? clear,
    required T Function() orElse,
  }) {
    final self = this;
    return switch (self) {
      CharacterSearchStateManagerStateInitial() => initial?.call() ?? orElse(),
      CharacterSearchStateManagerStateLoading() => loading?.call() ?? orElse(),
      CharacterSearchStateManagerStateError() =>
        error?.call(self.message) ?? orElse(),
      CharacterSearchStateManagerStateSearch() =>
        search?.call(self.value) ?? orElse(),
      CharacterSearchStateManagerStateClear() => clear?.call() ?? orElse(),
    };
  }
}

/// `CharacterSearchStateManagerState.initial` variant.
class CharacterSearchStateManagerStateInitial
    extends CharacterSearchStateManagerState {
  const CharacterSearchStateManagerStateInitial() : super._();

  @override
  String toString() => 'CharacterSearchStateManagerState.initial()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterSearchStateManagerStateInitial &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// `CharacterSearchStateManagerState.loading` variant.
class CharacterSearchStateManagerStateLoading
    extends CharacterSearchStateManagerState {
  const CharacterSearchStateManagerStateLoading() : super._();

  @override
  String toString() => 'CharacterSearchStateManagerState.loading()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterSearchStateManagerStateLoading &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// `CharacterSearchStateManagerState.error` variant.
class CharacterSearchStateManagerStateError
    extends CharacterSearchStateManagerState {
  const CharacterSearchStateManagerStateError({required this.message})
    : super._();

  final String message;

  @override
  String toString() =>
      'CharacterSearchStateManagerState.error(message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterSearchStateManagerStateError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// `CharacterSearchStateManagerState.search` variant.
class CharacterSearchStateManagerStateSearch
    extends CharacterSearchStateManagerState {
  const CharacterSearchStateManagerStateSearch({required this.value})
    : super._();

  final List<Character> value;

  @override
  String toString() => 'CharacterSearchStateManagerState.search(value: $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterSearchStateManagerStateSearch &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// `CharacterSearchStateManagerState.clear` variant.
class CharacterSearchStateManagerStateClear
    extends CharacterSearchStateManagerState {
  const CharacterSearchStateManagerStateClear() : super._();

  @override
  String toString() => 'CharacterSearchStateManagerState.clear()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterSearchStateManagerStateClear &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Controller for [CharacterSearchStateManager].
///
/// Owns the state and wraps the delegate: `@Event` methods emit
/// `loading` before the body runs and `error` if it throws.
/// Registered in DI as a lazy singleton by the generated
/// `configureDependencies`.
class $CharacterSearchStateManagerController
    extends DragonflyController<CharacterSearchStateManagerState> {
  $CharacterSearchStateManagerController(this._delegate)
    : super(const CharacterSearchStateManagerState.initial());

  final CharacterSearchStateManager _delegate;

  @override
  bool get loggingEnabled => false;

  Future<void> search(String name) async => schedule(
    'search',
    () => _search(name),
    debounce: const Duration(microseconds: 300000),
  );

  Future<void> _search(String name) async {
    emit(const CharacterSearchStateManagerState.loading());
    try {
      final value = await _delegate.search(name);
      emit(CharacterSearchStateManagerState.search(value: value));
    } catch (e) {
      emit(CharacterSearchStateManagerState.error(message: e.toString()));
    }
  }

  Future<void> clear() async {
    emit(const CharacterSearchStateManagerState.loading());
    try {
      await _delegate.clear();
      emit(const CharacterSearchStateManagerState.clear());
    } catch (e) {
      emit(CharacterSearchStateManagerState.error(message: e.toString()));
    }
  }
}
