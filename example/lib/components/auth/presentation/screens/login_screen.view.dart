// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'login_screen.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

/// View mixin for [LoginStateManager].
///
/// Flattens the state API onto the bound widget: dispatch events by
/// calling them (`initialize(session)`), rebuild from state with
/// [when], [buildFor] or the typed `build<Event>` builders.
mixin $LoginStateManager {
  $LoginStateManagerController get _loginStateManagerController =>
      DragonflyContainer.I.get<$LoginStateManagerController>();

  /// The current state of the bound controller.
  LoginState get currentState => _loginStateManagerController.state;

  /// Dispatches the `emailChanged` event.
  Future<void> emailChanged(String value) =>
      _loginStateManagerController.emailChanged(value);

  /// Dispatches the `passwordChanged` event.
  Future<void> passwordChanged(String value) =>
      _loginStateManagerController.passwordChanged(value);

  /// Dispatches the `acceptTermsChanged` event.
  Future<void> acceptTermsChanged(bool value) =>
      _loginStateManagerController.acceptTermsChanged(value);

  /// Dispatches the `emailTouched` event.
  Future<void> emailTouched() => _loginStateManagerController.emailTouched();

  /// Dispatches the `passwordTouched` event.
  Future<void> passwordTouched() =>
      _loginStateManagerController.passwordTouched();

  /// Dispatches the `login` event.
  Future<void> login() => _loginStateManagerController.login();

  /// Dispatches the `logout` event.
  Future<void> logout() => _loginStateManagerController.logout();

  /// Rebuilds on every state change. All variant callbacks are
  /// optional; [orElse] covers the unmatched ones.
  Widget when({
    Widget Function(LoginFormState form)? initial,
    Widget Function(LoginFormState form)? editing,
    Widget Function(LoginFormState form)? loading,
    Widget Function(LoginFormState form)? success,
    Widget Function(LoginFormState form, String message)? error,
    required Widget Function() orElse,
  }) {
    return DragonflyStateBuilder<LoginState>(
      controller: _loginStateManagerController,
      builder: (context, state) => state.maybeWhen(
        initial: initial,
        editing: editing,
        loading: loading,
        success: success,
        error: error,
        orElse: orElse,
      ),
    );
  }

  /// Builds only while the state is `LoginState.initial`.
  Widget buildInitial(
    Widget Function(LoginFormState form) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<LoginState>(
      controller: _loginStateManagerController,
      builder: (context, state) => state is LoginStateInitial
          ? builder(state.form)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `LoginState.editing`.
  Widget buildEditing(
    Widget Function(LoginFormState form) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<LoginState>(
      controller: _loginStateManagerController,
      builder: (context, state) => state is LoginStateEditing
          ? builder(state.form)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `LoginState.loading`.
  Widget buildLoading(
    Widget Function(LoginFormState form) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<LoginState>(
      controller: _loginStateManagerController,
      builder: (context, state) => state is LoginStateLoading
          ? builder(state.form)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `LoginState.success`.
  Widget buildSuccess(
    Widget Function(LoginFormState form) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<LoginState>(
      controller: _loginStateManagerController,
      builder: (context, state) => state is LoginStateSuccess
          ? builder(state.form)
          : orElse?.call() ?? const SizedBox.shrink(),
    );
  }

  /// Builds only while the state is `LoginState.error`.
  Widget buildError(
    Widget Function(LoginFormState form, String message) builder, {
    Widget Function()? orElse,
  }) {
    return DragonflyStateBuilder<LoginState>(
      controller: _loginStateManagerController,
      builder: (context, state) => state is LoginStateError
          ? builder(state.form, state.message)
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
    return DragonflyStateBuilder<LoginState>(
      controller: _loginStateManagerController,
      builder: (context, state) {
        final matched = switch (state) {
          LoginStateInitial() => event == 'initial',
          LoginStateEditing() => event == 'editing',
          LoginStateLoading() => event == 'loading',
          LoginStateSuccess() => event == 'success',
          LoginStateError() => event == 'error',
        };
        if (!matched) {
          return orElse?.call() ?? const SizedBox.shrink();
        }
        final value = switch (state) {
          LoginStateInitial(:final form) => form,
          LoginStateEditing(:final form) => form,
          LoginStateLoading(:final form) => form,
          LoginStateSuccess(:final form) => form,
          LoginStateError() => state,
        };
        return builder(value);
      },
    );
  }
}
