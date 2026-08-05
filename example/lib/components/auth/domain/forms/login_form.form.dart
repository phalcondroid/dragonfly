// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'login_form.dart';

// **************************************************************************
// FormSchemaGenerator
// **************************************************************************

/// Enum of form fields for type-safe field references.
enum LoginFormField { email, password, acceptTerms }

/// Generated form state for managing field values and validation.
class LoginFormFormState extends FormController<LoginFormFormState> {
  LoginFormFormState({
    FormFieldState<String>? email,
    FormFieldState<String>? password,
    FormFieldState<bool>? acceptTerms,
  }) : _email = email ?? FormFieldState<String>(value: '', initialValue: ''),
       _password =
           password ?? FormFieldState<String>(value: '', initialValue: ''),
       _acceptTerms =
           acceptTerms ??
           FormFieldState<bool>(value: false, initialValue: false);

  /// Creates an initial form state.
  factory LoginFormFormState.initial() => LoginFormFormState();

  final FormFieldState<String> _email;
  final FormFieldState<String> _password;
  final FormFieldState<bool> _acceptTerms;

  /// State for the email field.
  FormFieldState<String> get email => _email;

  /// State for the password field.
  FormFieldState<String> get password => _password;

  /// State for the acceptTerms field.
  FormFieldState<bool> get acceptTerms => _acceptTerms;

  @override
  Map<String, FormFieldState<dynamic>> get fields => {
    'email': _email,
    'password': _password,
    'acceptTerms': _acceptTerms,
  };

  @override
  Map<String, List<Validator<dynamic>>> get validators => {
    'email': [
      Validators.required('Email is required'),
      Validators.email('Please enter a valid email address'),
    ],
    'password': [
      Validators.required('Password is required'),
      Validators.minLength(8, 'Password must be at least 8 characters'),
      Validators.strongPassword(
        minLength: 8,
        requireUppercase: true,
        requireLowercase: true,
        requireDigit: true,
        requireSpecial: false,
        message: 'Password does not meet requirements',
      ),
    ],
    'acceptTerms': [
      Validators.mustBeTrue('You must accept the terms and conditions'),
    ],
  };

  @override
  Map<String, List<CrossFieldValidator<dynamic>>> get crossFieldValidators =>
      {};

  @override
  bool get validateOnChange => true;

  @override
  bool get validateOnBlur => true;

  /// Creates a copy with updated field states.
  LoginFormFormState copyWith({
    FormFieldState<String>? email,
    FormFieldState<String>? password,
    FormFieldState<bool>? acceptTerms,
  }) {
    return LoginFormFormState(
      email: email ?? _email,
      password: password ?? _password,
      acceptTerms: acceptTerms ?? _acceptTerms,
    );
  }

  /// Creates a copy with an updated field.
  LoginFormFormState updateField(
    String fieldName,
    FormFieldState<dynamic> newState,
  ) {
    switch (fieldName) {
      case 'email':
        return copyWith(email: newState as FormFieldState<String>);
      case 'password':
        return copyWith(password: newState as FormFieldState<String>);
      case 'acceptTerms':
        return copyWith(acceptTerms: newState as FormFieldState<bool>);
      default:
        return this;
    }
  }
}

/// Mixin that provides form controller functionality for StateManagers.
///
/// Use this mixin with your StateManager to get form handling:
/// ```dart
/// @DragonflyStateManager()
/// class MyStateManager extends StateManager<MyState> with LoginFormFormController {
///   // ...
/// }
/// ```
mixin LoginFormFormController<S> on StateManager<S> {
  /// Gets the form state from the current state.
  /// Override this in your StateManager to return the actual form state.
  LoginFormFormState get formState;

  /// Updates the state with a new form state.
  /// Override this in your StateManager to update the actual state.
  void updateFormState(LoginFormFormState newFormState);

  /// Updates the email field value.
  void updateEmail(String value) {
    final currentField = formState.email;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('email');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('email', newField));
  }

  /// Updates the password field value.
  void updatePassword(String value) {
    final currentField = formState.password;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('password');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('password', newField));
  }

  /// Updates the acceptTerms field value.
  void updateAcceptTerms(bool value) {
    final currentField = formState.acceptTerms;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('acceptTerms');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('acceptTerms', newField));
  }

  /// Marks the email field as touched.
  void touchEmail() {
    final currentField = formState.email;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('email');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('email', newField));
  }

  /// Marks the password field as touched.
  void touchPassword() {
    final currentField = formState.password;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('password');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('password', newField));
  }

  /// Marks the acceptTerms field as touched.
  void touchAcceptTerms() {
    final currentField = formState.acceptTerms;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('acceptTerms');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('acceptTerms', newField));
  }

  /// Validates all fields and returns true if the form is valid.
  bool validateAllFields() {
    var newFormState = formState;
    bool allValid = true;

    final emailError = formState.validateField('email');
    newFormState = newFormState.updateField(
      'email',
      formState.email.copyWith(
        error: emailError,
        clearError: emailError == null,
        touched: true,
      ),
    );
    if (emailError != null) allValid = false;

    final passwordError = formState.validateField('password');
    newFormState = newFormState.updateField(
      'password',
      formState.password.copyWith(
        error: passwordError,
        clearError: passwordError == null,
        touched: true,
      ),
    );
    if (passwordError != null) allValid = false;

    final acceptTermsError = formState.validateField('acceptTerms');
    newFormState = newFormState.updateField(
      'acceptTerms',
      formState.acceptTerms.copyWith(
        error: acceptTermsError,
        clearError: acceptTermsError == null,
        touched: true,
      ),
    );
    if (acceptTermsError != null) allValid = false;

    updateFormState(newFormState);
    return allValid;
  }

  /// Resets all fields to their initial values.
  void resetAllFields() {
    updateFormState(LoginFormFormState.initial());
  }
}
