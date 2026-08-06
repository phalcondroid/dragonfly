# Forms

`@FormSchema` generates a form state class (`LoginFormState`) with per-field typed
accessors, validation maps, and self-contained update methods.

```dart
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'login_form.form.dart';

@FormSchema()
class LoginForm {
  @Required(message: 'Email is required')
  @Email(message: 'Please enter a valid email address')
  final String email;

  @Required(message: 'Password is required')
  @MinLength(8)
  final String password;

  const LoginForm({this.email = '', this.password = ''});
}
```

### Generated API

```dart
LoginFormState form = LoginFormState.initial();

// Update a single field, validating when validateOnChange is on:
form = form.updateFieldValue('email', newEmail);

// Mark a field as touched, validating when validateOnBlur is on:
form = form.touchField('email');

// Validate everything and return the error-annotated state:
form = form.validateAllFields();
if (form.isValid) { ... }

// Typed accessors:
final emailField = form.email;     // DragonflyFormFieldState<String>
```

### Form-carrying state models

When the state model's `initial` variant carries the form, the manager must provide
an `initialState` getter (the generated controller cannot const-construct it):

```dart
part 'login_state.state.dart';

@StateModel()
sealed class LoginState with _$LoginState {
  const LoginState._();
  const factory LoginState.initial({required LoginFormState form}) = LoginStateInitial;
  const factory LoginState.editing({required LoginFormState form}) = LoginStateEditing;
  const factory LoginState.loading({required LoginFormState form}) = LoginStateLoading;
  const factory LoginState.success({required LoginFormState form}) = LoginStateSuccess;
  const factory LoginState.error({
    required LoginFormState form,
    required String message,
  }) = LoginStateError;
}
```

```dart
@StateManager(state: LoginState)
class LoginStateManager {
  LoginStateManager();
  LoginFormState _form = LoginFormState.initial();

  /// Called once by the generated controller instead of `const LoginState.initial()`.
  LoginState get initialState => LoginState.initial(form: _form);

  @Event()
  LoginState emailChanged(String value) {
    _form = _form.updateFieldValue('email', value);
    return LoginState.editing(form: _form);
  }
}
```

### Screen integration

```dart
/// Reads the form out of any [LoginState] variant.
LoginFormState _formOf(LoginState state) => state.when(
  initial: (f) => f, editing: (f) => f, loading: (f) => f,
  success: (f) => f, error: (f, _) => f,
);

// In the widget tree:
ValidatedTextField<LoginState>(
  stateController: _loginStateManagerController,
  fieldName: 'email',
  formSelector: _formOf,
  onChanged: emailChanged,
  ...
)
```

### Built-in validators

`@Required`, `@Email`, `@MinLength`, `@MaxLength`, `@Pattern`, `@Url`, `@Phone`,
`@Alphanumeric`, `@Alpha`, `@Numeric`, `@Min`, `@Max`, `@Range`, `@Positive`,
`@Negative`, `@EqualTo`, `@NotEqualTo`, `@PastDate`, `@FutureDate`, `@MinAge`,
`@MinItems`, `@MaxItems`, `@MustBeTrue`, `@MustBeFalse`, `@CreditCard`, `@Cvv`,
`@ExpiryDate`, `@StrongPassword`, `@RequiredIf`, `@RequiredUnless`, `@Custom`.

### Validated widgets

`ValidatedTextField<S>`, `ValidatedDropdown<S, T>`, `ValidatedCheckbox<S>`,
`ValidatedSwitch<S>`, `ValidatedDatePicker<S>`, `ValidatedSubmitButton<S>`,
`ValidatedForm`. Each takes `stateController`, `fieldName`, `formSelector` and
the relevant value-change callbacks. Error display is gated by `touched` by
default (change with `showErrorOnlyWhenTouched: false`).

[← Back to README.md](../../README.md)
