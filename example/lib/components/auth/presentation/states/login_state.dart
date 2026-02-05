import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/auth/domain/forms/login_form.dart';

part 'login_state.state.dart';

/// Login screen state with form validation.
@StateModel()
class LoginState {
  /// The login form state.
  @Field()
  final LoginFormState form;

  /// Whether a login request is in progress.
  @Field()
  final bool isLoading;

  /// Error message from login attempt.
  @Field()
  final String? errorMessage;

  const LoginState._({
    required this.form,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state with empty form.
  const factory LoginState.initial() = LoginStateInitial;

  /// Loading state while logging in.
  const factory LoginState.loading({
    required LoginFormState form,
  }) = LoginStateLoading;

  /// Success state after successful login.
  const factory LoginState.success({
    required LoginFormState form,
  }) = LoginStateSuccess;

  /// Error state with message.
  const factory LoginState.error({
    required LoginFormState form,
    required String message,
  }) = LoginStateError;
}
