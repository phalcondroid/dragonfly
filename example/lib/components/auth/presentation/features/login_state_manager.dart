import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/auth/domain/forms/login_form.dart';
import 'package:example/components/auth/presentation/states/login_state.dart';

part 'login_state_manager.state_manager.dart';

/// State manager for the login screen.
///
/// Demonstrates form validation integration with StateManager.
@DragonflyStateManager(logging: true)
class LoginStateManager extends StateManager<LoginState>
    with _$LoginStateManagerMixin, LoginFormFormController<LoginState> {
  LoginStateManager() : super(const LoginState.initial());

  // ═══════════════════════════════════════════════════════════════════════════
  // Form Integration
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  LoginFormState get formState => state.when(
        initial: () => LoginFormState.initial(),
        loading: (form) => form,
        success: (form) => form,
        error: (form, _) => form,
      );

  @override
  void updateFormState(LoginFormState newFormState) {
    state.when(
      initial: () => emit(LoginState.initial()..copyWith(form: newFormState)),
      loading: (form) => emit(LoginState.loading(form: newFormState)),
      success: (form) => emit(LoginState.success(form: newFormState)),
      error: (form, message) =>
          emit(LoginState.error(form: newFormState, message: message)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Attempts to log in with the current form values.
  @StateAction()
  Future<void> login() async {
    // Validate all fields first
    if (!validateAllFields()) {
      return;
    }

    // Start loading
    emit(LoginState.loading(form: formState));

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success/failure based on email
      final email = formState.email.value;
      if (email == 'error@test.com') {
        throw Exception('Invalid credentials');
      }

      // Success
      emit(LoginState.success(form: formState));

      // Navigate to home
      sideEffect(const NavigateTo('/home', replace: true));
      sideEffect(ShowSnackbar('Welcome back!'));
    } catch (e) {
      emit(LoginState.error(
        form: formState,
        message: e.toString(),
      ));
      sideEffect(ShowSnackbar('Login failed: $e', isError: true));
    }
  }

  /// Resets the form to initial state.
  @StateAction()
  void resetForm() {
    resetAllFields();
    emit(const LoginState.initial());
  }

  /// Navigates to registration screen.
  @StateAction()
  void goToRegistration() {
    sideEffect(const NavigateTo('/register'));
  }

  /// Navigates to forgot password screen.
  @StateAction()
  void goToForgotPassword() {
    sideEffect(const NavigateTo('/forgot-password'));
  }
}
