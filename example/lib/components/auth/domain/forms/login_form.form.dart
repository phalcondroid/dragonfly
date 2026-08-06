// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'login_form.dart';

// **************************************************************************
// FormSchemaGenerator
// **************************************************************************

/// Enum of form fields for type-safe field references.
enum LoginFormField { email, password, acceptTerms }

/// Generated form state for managing field values and validation.
class LoginFormState extends FormController<LoginFormState> {
  LoginFormState({
    DragonflyFormFieldState<String>? email,
    DragonflyFormFieldState<String>? password,
    DragonflyFormFieldState<bool>? acceptTerms,
  }) : _email =
           email ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _password =
           password ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _acceptTerms =
           acceptTerms ??
           DragonflyFormFieldState<bool>(value: false, initialValue: false);

  /// Creates an initial form state.
  factory LoginFormState.initial() => LoginFormState();

  final DragonflyFormFieldState<String> _email;
  final DragonflyFormFieldState<String> _password;
  final DragonflyFormFieldState<bool> _acceptTerms;

  /// State for the email field.
  DragonflyFormFieldState<String> get email => _email;

  /// State for the password field.
  DragonflyFormFieldState<String> get password => _password;

  /// State for the acceptTerms field.
  DragonflyFormFieldState<bool> get acceptTerms => _acceptTerms;

  @override
  Map<String, DragonflyFormFieldState<dynamic>> get fields => {
    'email': _email,
    'password': _password,
    'acceptTerms': _acceptTerms,
  };

  @override
  Map<String, List<Validator<dynamic>>> get validators => {
    'email': [
      (value) => Validators.required('Email is required')(value as String),
      (value) => Validators.email('Please enter a valid email address')(
        value as String,
      ),
    ],
    'password': [
      (value) => Validators.required('Password is required')(value as String),
      (value) => Validators.minLength(
        8,
        'Password must be at least 8 characters',
      )(value as String),
      (value) => Validators.strongPassword(
        minLength: 8,
        requireUppercase: true,
        requireLowercase: true,
        requireDigit: true,
        requireSpecial: false,
        message: 'Password does not meet requirements',
      )(value as String),
    ],
    'acceptTerms': [
      (value) => Validators.mustBeTrue(
        'You must accept the terms and conditions',
      )(value as bool),
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
  LoginFormState copyWith({
    DragonflyFormFieldState<String>? email,
    DragonflyFormFieldState<String>? password,
    DragonflyFormFieldState<bool>? acceptTerms,
  }) {
    return LoginFormState(
      email: email ?? _email,
      password: password ?? _password,
      acceptTerms: acceptTerms ?? _acceptTerms,
    );
  }

  /// Creates a copy with an updated field.
  LoginFormState updateField(
    String fieldName,
    DragonflyFormFieldState<dynamic> newState,
  ) {
    switch (fieldName) {
      case 'email':
        return copyWith(email: newState as DragonflyFormFieldState<String>);
      case 'password':
        return copyWith(password: newState as DragonflyFormFieldState<String>);
      case 'acceptTerms':
        return copyWith(acceptTerms: newState as DragonflyFormFieldState<bool>);
      default:
        return this;
    }
  }

  /// Sets a field value, validating it when [validateOnChange] is on.
  LoginFormState updateFieldValue(String fieldName, dynamic value) {
    final current = fields[fieldName];
    if (current == null) return this;
    String? error;
    if (validateOnChange) {
      error = _validateValue(fieldName, value);
    }
    return updateField(
      fieldName,
      current.copyWith(value: value, error: error, clearError: error == null),
    );
  }

  /// Marks a field as touched, validating it when [validateOnBlur] is on.
  LoginFormState touchField(String fieldName) {
    final current = fields[fieldName];
    if (current == null) return this;
    String? error = current.error;
    if (validateOnBlur) {
      error = _validateValue(fieldName, current.value);
    }
    return updateField(
      fieldName,
      current.copyWith(touched: true, error: error, clearError: error == null),
    );
  }

  /// Validates every field, marking all as touched, and returns the
  /// state with the resulting errors applied. Read [isValid] afterwards.
  LoginFormState validateAllFields() {
    LoginFormState next = this;
    for (final entry in fields.entries) {
      final error = _validateValue(entry.key, entry.value.value);
      next = next.updateField(
        entry.key,
        entry.value.copyWith(
          error: error,
          clearError: error == null,
          touched: true,
        ),
      );
    }
    return next;
  }

  String? _validateValue(String fieldName, dynamic value) {
    for (final validator in validators[fieldName] ?? <Validator<dynamic>>[]) {
      final error = validator(value);
      if (error != null) return error;
    }
    final allValues = {...values, fieldName: value};
    for (final validator
        in crossFieldValidators[fieldName] ??
            <CrossFieldValidator<dynamic>>[]) {
      final error = validator(value, allValues);
      if (error != null) return error;
    }
    return null;
  }
}
