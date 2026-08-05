// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'login_state_manager.dart';

// **************************************************************************
// DragonflyStateManagerGenerator
// **************************************************************************

/// Generated mixin for LoginStateManager.
///
/// Provides logging configuration.
/// State pattern matching (when, maybeWhen, map) is available directly on the state.
mixin _$LoginStateManagerMixin on StateManager<LoginState> {
  @override
  bool get loggingEnabled => true;
}

/// Provider widget that injects [LoginStateManager] into the widget tree.
///
/// Usage:
/// ```dart
/// LoginStateManagerProvider(
///   child: const MyWidget(),
/// )
/// ```
class LoginStateManagerProvider extends StatelessWidget {
  const LoginStateManagerProvider({
    super.key,
    this.create,
    required this.child,
  });

  /// Optional factory to create the state manager.
  /// If not provided, gets the state manager from DI.
  final LoginStateManager Function(BuildContext context)? create;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StateManagerProvider<LoginStateManager>(
      create: create ?? (_) => DragonflyContainer.I.get<LoginStateManager>(),
      child: child,
    );
  }
}

/// Builder widget that only builds when state is [LoginStateInitial].
///
/// Usage:
/// ```dart
/// LoginInitial(
///   builder: () => const MyWidget(),
/// )
/// ```
class LoginInitial extends StatelessWidget {
  const LoginInitial({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
  });

  /// Builder function called with state parameters when state is [LoginStateInitial].
  final Widget Function() builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(LoginState previous, LoginState current)? buildWhen;

  /// Optional widget to show when state is not [LoginStateInitial].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<LoginStateManager, LoginState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is LoginStateInitial) {
          return builder();
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Builder widget that only builds when state is [LoginStateLoading].
///
/// Usage:
/// ```dart
/// LoginLoading(
///   builder: (form) => MyWidget(form),
/// )
/// ```
class LoginLoading extends StatelessWidget {
  const LoginLoading({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
    this.initialForm,
  });

  /// Builder function called with state parameters when state is [LoginStateLoading].
  final Widget Function(InvalidType form) builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(LoginState previous, LoginState current)? buildWhen;

  /// Optional widget to show when state is not [LoginStateLoading].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  /// Initial value for form before state loads.
  final InvalidType? initialForm;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<LoginStateManager, LoginState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is LoginStateLoading) {
          return builder(state.form);
        }
        // Check if initial data is provided
        if (initialForm != null) {
          return builder(initialForm!);
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Builder widget that only builds when state is [LoginStateSuccess].
///
/// Usage:
/// ```dart
/// LoginSuccess(
///   builder: (form) => MyWidget(form),
/// )
/// ```
class LoginSuccess extends StatelessWidget {
  const LoginSuccess({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
    this.initialForm,
  });

  /// Builder function called with state parameters when state is [LoginStateSuccess].
  final Widget Function(InvalidType form) builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(LoginState previous, LoginState current)? buildWhen;

  /// Optional widget to show when state is not [LoginStateSuccess].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  /// Initial value for form before state loads.
  final InvalidType? initialForm;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<LoginStateManager, LoginState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is LoginStateSuccess) {
          return builder(state.form);
        }
        // Check if initial data is provided
        if (initialForm != null) {
          return builder(initialForm!);
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Builder widget that only builds when state is [LoginStateError].
///
/// Usage:
/// ```dart
/// LoginError(
///   builder: (form, message) => MyWidget(form, message),
/// )
/// ```
class LoginError extends StatelessWidget {
  const LoginError({
    super.key,
    required this.builder,
    this.buildWhen,
    this.orElse,
    this.initialForm,
    this.initialMessage,
  });

  /// Builder function called with state parameters when state is [LoginStateError].
  final Widget Function(InvalidType form, String message) builder;

  /// Optional function to determine if the builder should be called.
  /// Receives the previous and current state.
  final bool Function(LoginState previous, LoginState current)? buildWhen;

  /// Optional widget to show when state is not [LoginStateError].
  /// Defaults to an empty SizedBox.
  final Widget Function()? orElse;

  /// Initial value for form before state loads.
  final InvalidType? initialForm;

  /// Initial value for message before state loads.
  final String? initialMessage;

  @override
  Widget build(BuildContext context) {
    return StateManagerBuilder<LoginStateManager, LoginState>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is LoginStateError) {
          return builder(state.form, state.message);
        }
        // Check if initial data is provided
        if (initialForm != null && initialMessage != null) {
          return builder(initialForm!, initialMessage!);
        }
        return orElse?.call() ?? const SizedBox.shrink();
      },
    );
  }
}

/// Extension methods for using LoginStateManager in widgets.
extension LoginStateManagerBuildContextExtension on BuildContext {
  /// Gets the [LoginStateManager] from the widget tree.
  LoginStateManager get loginStateManager => stateManager<LoginStateManager>();

  /// Alias for backward compatibility.
  @Deprecated('Use loginStateManager instead')
  LoginStateManager get loginFeature => stateManager<LoginStateManager>();

  /// Builds a widget based on the current state of [LoginStateManager].
  /// Consider using individual state builders like [LoginLoaded] instead.
  Widget loginStateManagerBuilder({
    required Widget Function() onInitial,
    required Widget Function(InvalidType form) onLoading,
    required Widget Function(InvalidType form) onSuccess,
    required Widget Function(InvalidType form, String message) onError,
  }) {
    return StateManagerBuilder<LoginStateManager, LoginState>(
      builder: (context, state) {
        return state.when(
          initial: onInitial,
          loading: (form) => onLoading(form),
          success: (form) => onSuccess(form),
          error: (form, message) => onError(form, message),
        );
      },
    );
  }
}
