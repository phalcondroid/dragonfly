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
class RegistrationFormFormState
    extends FormController<RegistrationFormFormState> {
  RegistrationFormFormState({
    FormFieldState<String>? firstName,
    FormFieldState<String>? lastName,
    FormFieldState<String>? email,
    FormFieldState<String>? username,
    FormFieldState<String>? password,
    FormFieldState<String>? confirmPassword,
    FormFieldState<String>? phone,
    FormFieldState<DateTime?>? dateOfBirth,
    FormFieldState<bool>? isCompany,
    FormFieldState<String>? companyName,
    FormFieldState<String>? website,
    FormFieldState<bool>? acceptTerms,
    FormFieldState<bool>? acceptPrivacy,
  }) : _firstName =
           firstName ?? FormFieldState<String>(value: '', initialValue: ''),
       _lastName =
           lastName ?? FormFieldState<String>(value: '', initialValue: ''),
       _email = email ?? FormFieldState<String>(value: '', initialValue: ''),
       _username =
           username ?? FormFieldState<String>(value: '', initialValue: ''),
       _password =
           password ?? FormFieldState<String>(value: '', initialValue: ''),
       _confirmPassword =
           confirmPassword ??
           FormFieldState<String>(value: '', initialValue: ''),
       _phone = phone ?? FormFieldState<String>(value: '', initialValue: ''),
       _dateOfBirth =
           dateOfBirth ??
           FormFieldState<DateTime?>(value: null, initialValue: null),
       _isCompany =
           isCompany ?? FormFieldState<bool>(value: false, initialValue: false),
       _companyName =
           companyName ?? FormFieldState<String>(value: '', initialValue: ''),
       _website =
           website ?? FormFieldState<String>(value: '', initialValue: ''),
       _acceptTerms =
           acceptTerms ??
           FormFieldState<bool>(value: false, initialValue: false),
       _acceptPrivacy =
           acceptPrivacy ??
           FormFieldState<bool>(value: false, initialValue: false);

  /// Creates an initial form state.
  factory RegistrationFormFormState.initial() => RegistrationFormFormState();

  final FormFieldState<String> _firstName;
  final FormFieldState<String> _lastName;
  final FormFieldState<String> _email;
  final FormFieldState<String> _username;
  final FormFieldState<String> _password;
  final FormFieldState<String> _confirmPassword;
  final FormFieldState<String> _phone;
  final FormFieldState<DateTime?> _dateOfBirth;
  final FormFieldState<bool> _isCompany;
  final FormFieldState<String> _companyName;
  final FormFieldState<String> _website;
  final FormFieldState<bool> _acceptTerms;
  final FormFieldState<bool> _acceptPrivacy;

  /// State for the firstName field.
  FormFieldState<String> get firstName => _firstName;

  /// State for the lastName field.
  FormFieldState<String> get lastName => _lastName;

  /// State for the email field.
  FormFieldState<String> get email => _email;

  /// State for the username field.
  FormFieldState<String> get username => _username;

  /// State for the password field.
  FormFieldState<String> get password => _password;

  /// State for the confirmPassword field.
  FormFieldState<String> get confirmPassword => _confirmPassword;

  /// State for the phone field.
  FormFieldState<String> get phone => _phone;

  /// State for the dateOfBirth field.
  FormFieldState<DateTime?> get dateOfBirth => _dateOfBirth;

  /// State for the isCompany field.
  FormFieldState<bool> get isCompany => _isCompany;

  /// State for the companyName field.
  FormFieldState<String> get companyName => _companyName;

  /// State for the website field.
  FormFieldState<String> get website => _website;

  /// State for the acceptTerms field.
  FormFieldState<bool> get acceptTerms => _acceptTerms;

  /// State for the acceptPrivacy field.
  FormFieldState<bool> get acceptPrivacy => _acceptPrivacy;

  @override
  Map<String, FormFieldState<dynamic>> get fields => {
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
      Validators.required('First name is required'),
      Validators.minLength(2, 'First name must be at least 2 characters'),
      Validators.alpha('First name must contain only letters'),
    ],
    'lastName': [
      Validators.required('Last name is required'),
      Validators.minLength(2, 'Last name must be at least 2 characters'),
      Validators.alpha('Last name must contain only letters'),
    ],
    'email': [
      Validators.required('Email is required'),
      Validators.email('Please enter a valid email address'),
    ],
    'username': [
      Validators.required('Username is required'),
      Validators.minLength(3, 'Username must be at least 3 characters'),
      Validators.maxLength(20, 'Username must be at most 20 characters'),
      Validators.alphanumeric('Username must contain only letters and numbers'),
    ],
    'password': [
      Validators.required('Password is required'),
      Validators.strongPassword(
        minLength: 8,
        requireUppercase: true,
        requireLowercase: true,
        requireDigit: true,
        requireSpecial: true,
        message: 'Password must have 8+ chars, upper, lower, digit, special',
      ),
    ],
    'confirmPassword': [Validators.required('Please confirm your password')],
    'phone': [Validators.phone('Please enter a valid phone number')],
    'dateOfBirth': [Validators.minAge(18, 'You must be at least 18 years old')],
    'companyName': [
      Validators.minLength(2, 'Company name must be at least 2 characters'),
    ],
    'website': [Validators.url('Please enter a valid website URL')],
    'acceptTerms': [
      Validators.mustBeTrue('You must accept the terms and conditions'),
    ],
    'acceptPrivacy': [
      Validators.mustBeTrue('You must accept the privacy policy'),
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
  RegistrationFormFormState copyWith({
    FormFieldState<String>? firstName,
    FormFieldState<String>? lastName,
    FormFieldState<String>? email,
    FormFieldState<String>? username,
    FormFieldState<String>? password,
    FormFieldState<String>? confirmPassword,
    FormFieldState<String>? phone,
    FormFieldState<DateTime?>? dateOfBirth,
    FormFieldState<bool>? isCompany,
    FormFieldState<String>? companyName,
    FormFieldState<String>? website,
    FormFieldState<bool>? acceptTerms,
    FormFieldState<bool>? acceptPrivacy,
  }) {
    return RegistrationFormFormState(
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
  RegistrationFormFormState updateField(
    String fieldName,
    FormFieldState<dynamic> newState,
  ) {
    switch (fieldName) {
      case 'firstName':
        return copyWith(firstName: newState as FormFieldState<String>);
      case 'lastName':
        return copyWith(lastName: newState as FormFieldState<String>);
      case 'email':
        return copyWith(email: newState as FormFieldState<String>);
      case 'username':
        return copyWith(username: newState as FormFieldState<String>);
      case 'password':
        return copyWith(password: newState as FormFieldState<String>);
      case 'confirmPassword':
        return copyWith(confirmPassword: newState as FormFieldState<String>);
      case 'phone':
        return copyWith(phone: newState as FormFieldState<String>);
      case 'dateOfBirth':
        return copyWith(dateOfBirth: newState as FormFieldState<DateTime?>);
      case 'isCompany':
        return copyWith(isCompany: newState as FormFieldState<bool>);
      case 'companyName':
        return copyWith(companyName: newState as FormFieldState<String>);
      case 'website':
        return copyWith(website: newState as FormFieldState<String>);
      case 'acceptTerms':
        return copyWith(acceptTerms: newState as FormFieldState<bool>);
      case 'acceptPrivacy':
        return copyWith(acceptPrivacy: newState as FormFieldState<bool>);
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
/// class MyStateManager extends StateManager<MyState> with RegistrationFormFormController {
///   // ...
/// }
/// ```
mixin RegistrationFormFormController<S> on StateManager<S> {
  /// Gets the form state from the current state.
  /// Override this in your StateManager to return the actual form state.
  RegistrationFormFormState get formState;

  /// Updates the state with a new form state.
  /// Override this in your StateManager to update the actual state.
  void updateFormState(RegistrationFormFormState newFormState);

  /// Updates the firstName field value.
  void updateFirstName(String value) {
    final currentField = formState.firstName;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('firstName');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('firstName', newField));
  }

  /// Updates the lastName field value.
  void updateLastName(String value) {
    final currentField = formState.lastName;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('lastName');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('lastName', newField));
  }

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

  /// Updates the username field value.
  void updateUsername(String value) {
    final currentField = formState.username;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('username');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('username', newField));
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

  /// Updates the confirmPassword field value.
  void updateConfirmPassword(String value) {
    final currentField = formState.confirmPassword;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('confirmPassword');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('confirmPassword', newField));
  }

  /// Updates the phone field value.
  void updatePhone(String value) {
    final currentField = formState.phone;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('phone');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('phone', newField));
  }

  /// Updates the dateOfBirth field value.
  void updateDateOfBirth(DateTime? value) {
    final currentField = formState.dateOfBirth;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('dateOfBirth');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('dateOfBirth', newField));
  }

  /// Updates the isCompany field value.
  void updateIsCompany(bool value) {
    final currentField = formState.isCompany;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('isCompany');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('isCompany', newField));
  }

  /// Updates the companyName field value.
  void updateCompanyName(String value) {
    final currentField = formState.companyName;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('companyName');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('companyName', newField));
  }

  /// Updates the website field value.
  void updateWebsite(String value) {
    final currentField = formState.website;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('website');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('website', newField));
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

  /// Updates the acceptPrivacy field value.
  void updateAcceptPrivacy(bool value) {
    final currentField = formState.acceptPrivacy;
    var newField = currentField.copyWith(value: value);

    // Validate if validateOnChange is true
    if (formState.validateOnChange) {
      final error = formState.validateField('acceptPrivacy');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('acceptPrivacy', newField));
  }

  /// Marks the firstName field as touched.
  void touchFirstName() {
    final currentField = formState.firstName;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('firstName');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('firstName', newField));
  }

  /// Marks the lastName field as touched.
  void touchLastName() {
    final currentField = formState.lastName;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('lastName');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('lastName', newField));
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

  /// Marks the username field as touched.
  void touchUsername() {
    final currentField = formState.username;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('username');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('username', newField));
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

  /// Marks the confirmPassword field as touched.
  void touchConfirmPassword() {
    final currentField = formState.confirmPassword;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('confirmPassword');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('confirmPassword', newField));
  }

  /// Marks the phone field as touched.
  void touchPhone() {
    final currentField = formState.phone;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('phone');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('phone', newField));
  }

  /// Marks the dateOfBirth field as touched.
  void touchDateOfBirth() {
    final currentField = formState.dateOfBirth;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('dateOfBirth');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('dateOfBirth', newField));
  }

  /// Marks the isCompany field as touched.
  void touchIsCompany() {
    final currentField = formState.isCompany;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('isCompany');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('isCompany', newField));
  }

  /// Marks the companyName field as touched.
  void touchCompanyName() {
    final currentField = formState.companyName;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('companyName');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('companyName', newField));
  }

  /// Marks the website field as touched.
  void touchWebsite() {
    final currentField = formState.website;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('website');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('website', newField));
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

  /// Marks the acceptPrivacy field as touched.
  void touchAcceptPrivacy() {
    final currentField = formState.acceptPrivacy;
    var newField = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = formState.validateField('acceptPrivacy');
      newField = newField.copyWith(error: error, clearError: error == null);
    }

    updateFormState(formState.updateField('acceptPrivacy', newField));
  }

  /// Validates all fields and returns true if the form is valid.
  bool validateAllFields() {
    var newFormState = formState;
    bool allValid = true;

    final firstNameError = formState.validateField('firstName');
    newFormState = newFormState.updateField(
      'firstName',
      formState.firstName.copyWith(
        error: firstNameError,
        clearError: firstNameError == null,
        touched: true,
      ),
    );
    if (firstNameError != null) allValid = false;

    final lastNameError = formState.validateField('lastName');
    newFormState = newFormState.updateField(
      'lastName',
      formState.lastName.copyWith(
        error: lastNameError,
        clearError: lastNameError == null,
        touched: true,
      ),
    );
    if (lastNameError != null) allValid = false;

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

    final usernameError = formState.validateField('username');
    newFormState = newFormState.updateField(
      'username',
      formState.username.copyWith(
        error: usernameError,
        clearError: usernameError == null,
        touched: true,
      ),
    );
    if (usernameError != null) allValid = false;

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

    final confirmPasswordError = formState.validateField('confirmPassword');
    newFormState = newFormState.updateField(
      'confirmPassword',
      formState.confirmPassword.copyWith(
        error: confirmPasswordError,
        clearError: confirmPasswordError == null,
        touched: true,
      ),
    );
    if (confirmPasswordError != null) allValid = false;

    final phoneError = formState.validateField('phone');
    newFormState = newFormState.updateField(
      'phone',
      formState.phone.copyWith(
        error: phoneError,
        clearError: phoneError == null,
        touched: true,
      ),
    );
    if (phoneError != null) allValid = false;

    final dateOfBirthError = formState.validateField('dateOfBirth');
    newFormState = newFormState.updateField(
      'dateOfBirth',
      formState.dateOfBirth.copyWith(
        error: dateOfBirthError,
        clearError: dateOfBirthError == null,
        touched: true,
      ),
    );
    if (dateOfBirthError != null) allValid = false;

    final isCompanyError = formState.validateField('isCompany');
    newFormState = newFormState.updateField(
      'isCompany',
      formState.isCompany.copyWith(
        error: isCompanyError,
        clearError: isCompanyError == null,
        touched: true,
      ),
    );
    if (isCompanyError != null) allValid = false;

    final companyNameError = formState.validateField('companyName');
    newFormState = newFormState.updateField(
      'companyName',
      formState.companyName.copyWith(
        error: companyNameError,
        clearError: companyNameError == null,
        touched: true,
      ),
    );
    if (companyNameError != null) allValid = false;

    final websiteError = formState.validateField('website');
    newFormState = newFormState.updateField(
      'website',
      formState.website.copyWith(
        error: websiteError,
        clearError: websiteError == null,
        touched: true,
      ),
    );
    if (websiteError != null) allValid = false;

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

    final acceptPrivacyError = formState.validateField('acceptPrivacy');
    newFormState = newFormState.updateField(
      'acceptPrivacy',
      formState.acceptPrivacy.copyWith(
        error: acceptPrivacyError,
        clearError: acceptPrivacyError == null,
        touched: true,
      ),
    );
    if (acceptPrivacyError != null) allValid = false;

    updateFormState(newFormState);
    return allValid;
  }

  /// Resets all fields to their initial values.
  void resetAllFields() {
    updateFormState(RegistrationFormFormState.initial());
  }
}
