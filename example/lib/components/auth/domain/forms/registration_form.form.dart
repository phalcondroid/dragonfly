// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'registration_form.dart';

// **************************************************************************
// FormSchemaGenerator
// **************************************************************************

/// Enum of form fields for type-safe field references.
enum RegistrationFormField {
  firstName,
  lastName,
  email,
  username,
  password,
  confirmPassword,
  phone,
  dateOfBirth,
  isCompany,
  companyName,
  website,
  acceptTerms,
  acceptPrivacy,
}

/// Generated form state for managing field values and validation.
class RegistrationFormState extends FormController<RegistrationFormState> {
  RegistrationFormState({
    DragonflyFormFieldState<String>? firstName,
    DragonflyFormFieldState<String>? lastName,
    DragonflyFormFieldState<String>? email,
    DragonflyFormFieldState<String>? username,
    DragonflyFormFieldState<String>? password,
    DragonflyFormFieldState<String>? confirmPassword,
    DragonflyFormFieldState<String>? phone,
    DragonflyFormFieldState<DateTime?>? dateOfBirth,
    DragonflyFormFieldState<bool>? isCompany,
    DragonflyFormFieldState<String>? companyName,
    DragonflyFormFieldState<String>? website,
    DragonflyFormFieldState<bool>? acceptTerms,
    DragonflyFormFieldState<bool>? acceptPrivacy,
  }) : _firstName =
           firstName ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _lastName =
           lastName ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _email =
           email ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _username =
           username ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _password =
           password ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _confirmPassword =
           confirmPassword ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _phone =
           phone ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _dateOfBirth =
           dateOfBirth ??
           DragonflyFormFieldState<DateTime?>(value: null, initialValue: null),
       _isCompany =
           isCompany ??
           DragonflyFormFieldState<bool>(value: false, initialValue: false),
       _companyName =
           companyName ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _website =
           website ??
           DragonflyFormFieldState<String>(value: '', initialValue: ''),
       _acceptTerms =
           acceptTerms ??
           DragonflyFormFieldState<bool>(value: false, initialValue: false),
       _acceptPrivacy =
           acceptPrivacy ??
           DragonflyFormFieldState<bool>(value: false, initialValue: false);

  /// Creates an initial form state.
  factory RegistrationFormState.initial() => RegistrationFormState();

  final DragonflyFormFieldState<String> _firstName;
  final DragonflyFormFieldState<String> _lastName;
  final DragonflyFormFieldState<String> _email;
  final DragonflyFormFieldState<String> _username;
  final DragonflyFormFieldState<String> _password;
  final DragonflyFormFieldState<String> _confirmPassword;
  final DragonflyFormFieldState<String> _phone;
  final DragonflyFormFieldState<DateTime?> _dateOfBirth;
  final DragonflyFormFieldState<bool> _isCompany;
  final DragonflyFormFieldState<String> _companyName;
  final DragonflyFormFieldState<String> _website;
  final DragonflyFormFieldState<bool> _acceptTerms;
  final DragonflyFormFieldState<bool> _acceptPrivacy;

  /// State for the firstName field.
  DragonflyFormFieldState<String> get firstName => _firstName;

  /// State for the lastName field.
  DragonflyFormFieldState<String> get lastName => _lastName;

  /// State for the email field.
  DragonflyFormFieldState<String> get email => _email;

  /// State for the username field.
  DragonflyFormFieldState<String> get username => _username;

  /// State for the password field.
  DragonflyFormFieldState<String> get password => _password;

  /// State for the confirmPassword field.
  DragonflyFormFieldState<String> get confirmPassword => _confirmPassword;

  /// State for the phone field.
  DragonflyFormFieldState<String> get phone => _phone;

  /// State for the dateOfBirth field.
  DragonflyFormFieldState<DateTime?> get dateOfBirth => _dateOfBirth;

  /// State for the isCompany field.
  DragonflyFormFieldState<bool> get isCompany => _isCompany;

  /// State for the companyName field.
  DragonflyFormFieldState<String> get companyName => _companyName;

  /// State for the website field.
  DragonflyFormFieldState<String> get website => _website;

  /// State for the acceptTerms field.
  DragonflyFormFieldState<bool> get acceptTerms => _acceptTerms;

  /// State for the acceptPrivacy field.
  DragonflyFormFieldState<bool> get acceptPrivacy => _acceptPrivacy;

  @override
  Map<String, DragonflyFormFieldState<dynamic>> get fields => {
    'firstName': _firstName,
    'lastName': _lastName,
    'email': _email,
    'username': _username,
    'password': _password,
    'confirmPassword': _confirmPassword,
    'phone': _phone,
    'dateOfBirth': _dateOfBirth,
    'isCompany': _isCompany,
    'companyName': _companyName,
    'website': _website,
    'acceptTerms': _acceptTerms,
    'acceptPrivacy': _acceptPrivacy,
  };

  @override
  Map<String, List<Validator<dynamic>>> get validators => {
    'firstName': [
      (value) => Validators.required('First name is required')(value as String),
      (value) => Validators.minLength(
        2,
        'First name must be at least 2 characters',
      )(value as String),
      (value) => Validators.alpha('First name must contain only letters')(
        value as String,
      ),
    ],
    'lastName': [
      (value) => Validators.required('Last name is required')(value as String),
      (value) => Validators.minLength(
        2,
        'Last name must be at least 2 characters',
      )(value as String),
      (value) => Validators.alpha('Last name must contain only letters')(
        value as String,
      ),
    ],
    'email': [
      (value) => Validators.required('Email is required')(value as String),
      (value) => Validators.email('Please enter a valid email address')(
        value as String,
      ),
    ],
    'username': [
      (value) => Validators.required('Username is required')(value as String),
      (value) => Validators.minLength(
        3,
        'Username must be at least 3 characters',
      )(value as String),
      (value) => Validators.maxLength(
        20,
        'Username must be at most 20 characters',
      )(value as String),
      (value) => Validators.alphanumeric(
        'Username must contain only letters and numbers',
      )(value as String),
    ],
    'password': [
      (value) => Validators.required('Password is required')(value as String),
      (value) => Validators.strongPassword(
        minLength: 8,
        requireUppercase: true,
        requireLowercase: true,
        requireDigit: true,
        requireSpecial: true,
        message: 'Password must have 8+ chars, upper, lower, digit, special',
      )(value as String),
    ],
    'confirmPassword': [
      (value) =>
          Validators.required('Please confirm your password')(value as String),
    ],
    'phone': [
      (value) => Validators.phone('Please enter a valid phone number')(
        value as String,
      ),
    ],
    'dateOfBirth': [
      (value) => Validators.minAge(18, 'You must be at least 18 years old')(
        value as DateTime?,
      ),
    ],
    'companyName': [
      (value) => Validators.minLength(
        2,
        'Company name must be at least 2 characters',
      )(value as String),
    ],
    'website': [
      (value) =>
          Validators.url('Please enter a valid website URL')(value as String),
    ],
    'acceptTerms': [
      (value) => Validators.mustBeTrue(
        'You must accept the terms and conditions',
      )(value as bool),
    ],
    'acceptPrivacy': [
      (value) => Validators.mustBeTrue('You must accept the privacy policy')(
        value as bool,
      ),
    ],
  };

  @override
  Map<String, List<CrossFieldValidator<dynamic>>> get crossFieldValidators => {
    'confirmPassword': [
      Validators.equalTo('password', 'Passwords do not match'),
    ],
    'companyName': [
      Validators.requiredIf('isCompany', true, 'Company name is required'),
    ],
  };

  @override
  bool get validateOnChange => true;

  @override
  bool get validateOnBlur => true;

  /// Creates a copy with updated field states.
  RegistrationFormState copyWith({
    DragonflyFormFieldState<String>? firstName,
    DragonflyFormFieldState<String>? lastName,
    DragonflyFormFieldState<String>? email,
    DragonflyFormFieldState<String>? username,
    DragonflyFormFieldState<String>? password,
    DragonflyFormFieldState<String>? confirmPassword,
    DragonflyFormFieldState<String>? phone,
    DragonflyFormFieldState<DateTime?>? dateOfBirth,
    DragonflyFormFieldState<bool>? isCompany,
    DragonflyFormFieldState<String>? companyName,
    DragonflyFormFieldState<String>? website,
    DragonflyFormFieldState<bool>? acceptTerms,
    DragonflyFormFieldState<bool>? acceptPrivacy,
  }) {
    return RegistrationFormState(
      firstName: firstName ?? _firstName,
      lastName: lastName ?? _lastName,
      email: email ?? _email,
      username: username ?? _username,
      password: password ?? _password,
      confirmPassword: confirmPassword ?? _confirmPassword,
      phone: phone ?? _phone,
      dateOfBirth: dateOfBirth ?? _dateOfBirth,
      isCompany: isCompany ?? _isCompany,
      companyName: companyName ?? _companyName,
      website: website ?? _website,
      acceptTerms: acceptTerms ?? _acceptTerms,
      acceptPrivacy: acceptPrivacy ?? _acceptPrivacy,
    );
  }

  /// Creates a copy with an updated field.
  RegistrationFormState updateField(
    String fieldName,
    DragonflyFormFieldState<dynamic> newState,
  ) {
    switch (fieldName) {
      case 'firstName':
        return copyWith(firstName: newState as DragonflyFormFieldState<String>);
      case 'lastName':
        return copyWith(lastName: newState as DragonflyFormFieldState<String>);
      case 'email':
        return copyWith(email: newState as DragonflyFormFieldState<String>);
      case 'username':
        return copyWith(username: newState as DragonflyFormFieldState<String>);
      case 'password':
        return copyWith(password: newState as DragonflyFormFieldState<String>);
      case 'confirmPassword':
        return copyWith(
          confirmPassword: newState as DragonflyFormFieldState<String>,
        );
      case 'phone':
        return copyWith(phone: newState as DragonflyFormFieldState<String>);
      case 'dateOfBirth':
        return copyWith(
          dateOfBirth: newState as DragonflyFormFieldState<DateTime?>,
        );
      case 'isCompany':
        return copyWith(isCompany: newState as DragonflyFormFieldState<bool>);
      case 'companyName':
        return copyWith(
          companyName: newState as DragonflyFormFieldState<String>,
        );
      case 'website':
        return copyWith(website: newState as DragonflyFormFieldState<String>);
      case 'acceptTerms':
        return copyWith(acceptTerms: newState as DragonflyFormFieldState<bool>);
      case 'acceptPrivacy':
        return copyWith(
          acceptPrivacy: newState as DragonflyFormFieldState<bool>,
        );
      default:
        return this;
    }
  }

  /// Sets a field value, validating it when [validateOnChange] is on.
  RegistrationFormState updateFieldValue(String fieldName, dynamic value) {
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
  RegistrationFormState touchField(String fieldName) {
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
  RegistrationFormState validateAllFields() {
    RegistrationFormState next = this;
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
