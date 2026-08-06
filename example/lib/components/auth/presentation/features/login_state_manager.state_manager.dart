// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'login_state_manager.dart';

// **************************************************************************
// StateManagerGenerator
// **************************************************************************

/// Controller for [LoginStateManager].
///
/// Owns the state and wraps the delegate: `@Event` methods emit
/// Registered in DI as a lazy singleton by the generated
/// `configureDependencies`.
class $LoginStateManagerController extends DragonflyController<LoginState> {
  $LoginStateManagerController(LoginStateManager delegate)
    : _delegate = delegate,
      super(delegate.initialState);

  final LoginStateManager _delegate;

  @override
  bool get loggingEnabled => false;

  Future<void> emailChanged(String value) async {
    try {
      emit(_delegate.emailChanged(value));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> passwordChanged(String value) async {
    try {
      emit(_delegate.passwordChanged(value));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptTermsChanged(bool value) async {
    try {
      emit(_delegate.acceptTermsChanged(value));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> emailTouched() async {
    try {
      emit(_delegate.emailTouched());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> passwordTouched() async {
    try {
      emit(_delegate.passwordTouched());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login() async {
    try {
      emit(await _delegate.login());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      emit(_delegate.logout());
    } catch (e) {
      rethrow;
    }
  }
}
