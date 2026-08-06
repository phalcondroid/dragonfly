import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/auth/domain/forms/login_form.dart';

part 'login_state.state.dart';

/// Login screen state with form validation.
///
/// Every variant carries the current [LoginFormState] so the view can always
/// read field values and errors. `initial` takes the form as a parameter, so
/// the controller reads its starting state from the manager's `initialState`
/// getter instead of a const constructor.
@StateModel()
sealed class LoginState with _$LoginState {
  const LoginState._();

  /// Initial state with a pristine form.
  const factory LoginState.initial({required LoginFormState form}) =
      LoginStateInitial;

  /// The user is editing the form.
  const factory LoginState.editing({required LoginFormState form}) =
      LoginStateEditing;

  /// A login request is in progress.
  const factory LoginState.loading({required LoginFormState form}) =
      LoginStateLoading;

  /// Login succeeded.
  const factory LoginState.success({required LoginFormState form}) =
      LoginStateSuccess;

  /// Login failed with a message.
  const factory LoginState.error({
    required LoginFormState form,
    required String message,
  }) = LoginStateError;
}
