/// Holds all translatable validation error messages.
///
/// Override any field to customize validation error text for your locale.
/// Pass an instance to [DragonflyConfig.validationMessages] to set globally,
/// or provide one from your [DragonflyI18n] subclass.
///
/// ```dart
/// class AppI18n extends DragonflyI18n {
///   // ...
///   DragonflyValidationMessages get validationMessages =>
///       SpanishValidationMessages();
/// }
///
/// class SpanishValidationMessages extends DragonflyValidationMessages {
///   @override String get required => 'Este campo es obligatorio';
///   @override String get invalidEmail => 'Formato de correo inválido';
/// }
/// ```
class DragonflyValidationMessages {
  const DragonflyValidationMessages();

  String get required => 'This field is required';
  String get invalidEmail => 'Invalid email format';
  String minLength(int length) => 'Must be at least $length characters';
  String maxLength(int length) => 'Must be at most $length characters';
  String get invalidFormat => 'Invalid format';
  String get invalidUrl => 'Invalid URL format';
  String get invalidPhone => 'Invalid phone number';
  String get notAlphanumeric => 'Must contain only letters and numbers';
  String get notAlpha => 'Must contain only letters';
  String get notNumeric => 'Must contain only numbers';
  String tooLow(num min) => 'Must be at least $min';
  String tooHigh(num max) => 'Must be at most $max';
  String outOfRange(num min, num max) => 'Must be between $min and $max';
  String get notPositive => 'Must be a positive number';
  String get notNegative => 'Must be a negative number';
  String get mustBeTrue => 'This field must be checked';
  String get mustBeFalse => 'This field must be unchecked';
  String get dateInPast => 'Date must be in the past';
  String get dateInFuture => 'Date must be in the future';
  String tooYoung(int years) => 'Must be at least $years years old';
  String tooFewItems(int count) => 'Must have at least $count items';
  String tooManyItems(int count) => 'Must have at most $count items';
  String get fieldsMustMatch => 'Fields must match';
  String get fieldsMustDiffer => 'Fields must be different';
  String get requiredConditional => 'This field is required';
  String get invalidCreditCard => 'Invalid credit card number';
  String get invalidCvv => 'Invalid CVV';
  String get invalidExpiryDate => 'Invalid or expired date';
  String get weakPassword => 'Password does not meet requirements';
  String passwordChars(int minLength) => 'at least $minLength characters';
  String get passwordUppercase => 'an uppercase letter';
  String get passwordLowercase => 'a lowercase letter';
  String get passwordNumber => 'a number';
  String get passwordSpecial => 'a special character';
  String passwordRequirements(List<String> errors) =>
      'Password must contain ${errors.join(', ')}';

  String get submitButtonLabel => 'Submit';
  String get authenticationRequired => 'Authentication required';
  String requiredRoles(List<String> roles) =>
      'Required roles: ${roles.join(', ')}';
  String requiredPermissions(List<String> permissions) =>
      'Required permissions: ${permissions.join(', ')}';
}
