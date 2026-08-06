import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/auth/domain/forms/login_form.dart';
import 'package:example/components/auth/presentation/states/login_state.dart';

part 'login_state_manager.state_manager.dart';

/// State manager for the login screen (v2).
///
/// Holds the current [LoginFormState] and models every user interaction as an
/// `@Event` returning the next [LoginState]. The form validates itself:
/// `updateFieldValue` applies `validateOnChange`, `touchField` applies
/// `validateOnBlur`, and `validateAllFields` runs the whole schema on submit.
@StateManager(state: LoginState)
class LoginStateManager {
  LoginStateManager();

  LoginFormState _form = LoginFormState.initial();

  /// The controller's starting state (the `initial` variant takes the form as
  /// a parameter, so it cannot be const-constructed by the controller).
  LoginState get initialState => LoginState.initial(form: _form);

  @Event()
  LoginState emailChanged(String value) {
    _form = _form.updateFieldValue('email', value);
    return LoginState.editing(form: _form);
  }

  @Event()
  LoginState passwordChanged(String value) {
    _form = _form.updateFieldValue('password', value);
    return LoginState.editing(form: _form);
  }

  @Event()
  LoginState acceptTermsChanged(bool value) {
    _form = _form.updateFieldValue('acceptTerms', value);
    return LoginState.editing(form: _form);
  }

  @Event()
  LoginState emailTouched() {
    _form = _form.touchField('email');
    return LoginState.editing(form: _form);
  }

  @Event()
  LoginState passwordTouched() {
    _form = _form.touchField('password');
    return LoginState.editing(form: _form);
  }

  /// Validates the whole form and simulates a login request.
  @Event()
  Future<LoginState> login() async {
    _form = _form.validateAllFields();
    if (!_form.isValid) {
      return LoginState.editing(form: _form);
    }

    // No backend in the example app — simulate a round trip.
    await Future<void>.delayed(const Duration(seconds: 1));

    final email = _form.values['email'] as String;
    if (email == 'demo@dragonfly.dev') {
      return LoginState.success(form: _form);
    }
    return LoginState.error(
      form: _form,
      message: 'Invalid credentials. Try demo@dragonfly.dev.',
    );
  }

  /// Back to a pristine form after a successful login.
  @Event()
  LoginState logout() {
    _form = LoginFormState.initial();
    return LoginState.initial(form: _form);
  }
}
