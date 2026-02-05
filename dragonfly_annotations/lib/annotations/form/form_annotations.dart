import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Marks a class as a form schema for validation.
///
/// The generator will create:
/// - A `FormState` class to track field values, errors, and touched state
/// - A `FormController` mixin to integrate with StateManager
/// - Field enum for type-safe field references
/// - Validation logic based on field annotations
///
/// Example:
/// ```dart
/// @FormSchema()
/// class LoginForm {
///   @Required(message: 'Email is required')
///   @Email()
///   final String email;
///
///   @Required()
///   @MinLength(8)
///   final String password;
///
///   const LoginForm({this.email = '', this.password = ''});
/// }
/// ```
@immutable
@Target({TargetKind.classType})
class FormSchema {
  /// Whether to generate copyWith method for the form state.
  final bool copyWith;

  /// Whether to validate on field change.
  final bool validateOnChange;

  /// Whether to validate on field blur (lost focus).
  final bool validateOnBlur;

  /// Custom name for the generated form state class.
  /// Defaults to `${ClassName}State`.
  final String? stateName;

  const FormSchema({
    this.copyWith = true,
    this.validateOnChange = true,
    this.validateOnBlur = true,
    this.stateName,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Base Validator
// ═══════════════════════════════════════════════════════════════════════════

/// Base class for all field validators.
@immutable
abstract class FieldValidator {
  /// Error message when validation fails.
  final String? message;

  const FieldValidator({this.message});
}

// ═══════════════════════════════════════════════════════════════════════════
// String Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Validates that a field is not null or empty.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Required extends FieldValidator {
  const Required({super.message = 'This field is required'});
}

/// Validates email format.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Email extends FieldValidator {
  const Email({super.message = 'Invalid email format'});
}

/// Validates minimum string length.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class MinLength extends FieldValidator {
  final int length;

  const MinLength(this.length, {String? message})
      : super(message: message ?? 'Must be at least $length characters');
}

/// Validates maximum string length.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class MaxLength extends FieldValidator {
  final int length;

  const MaxLength(this.length, {String? message})
      : super(message: message ?? 'Must be at most $length characters');
}

/// Validates string matches a regex pattern.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Pattern extends FieldValidator {
  final String pattern;

  const Pattern(this.pattern, {super.message = 'Invalid format'});
}

/// Validates URL format.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Url extends FieldValidator {
  const Url({super.message = 'Invalid URL format'});
}

/// Validates phone number format.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Phone extends FieldValidator {
  const Phone({super.message = 'Invalid phone number'});
}

/// Validates that string contains only alphanumeric characters.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Alphanumeric extends FieldValidator {
  const Alphanumeric({super.message = 'Must contain only letters and numbers'});
}

/// Validates that string contains only alphabetic characters.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Alpha extends FieldValidator {
  const Alpha({super.message = 'Must contain only letters'});
}

/// Validates that string contains only numeric characters.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Numeric extends FieldValidator {
  const Numeric({super.message = 'Must contain only numbers'});
}

// ═══════════════════════════════════════════════════════════════════════════
// Number Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Validates minimum numeric value.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Min extends FieldValidator {
  final num value;

  const Min(this.value, {String? message})
      : super(message: message ?? 'Must be at least $value');
}

/// Validates maximum numeric value.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Max extends FieldValidator {
  final num value;

  const Max(this.value, {String? message})
      : super(message: message ?? 'Must be at most $value');
}

/// Validates value is within a range.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Range extends FieldValidator {
  final num min;
  final num max;

  const Range(this.min, this.max, {String? message})
      : super(message: message ?? 'Must be between $min and $max');
}

/// Validates that number is positive.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Positive extends FieldValidator {
  const Positive({super.message = 'Must be a positive number'});
}

/// Validates that number is negative.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Negative extends FieldValidator {
  const Negative({super.message = 'Must be a negative number'});
}

// ═══════════════════════════════════════════════════════════════════════════
// Comparison Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Validates that this field equals another field's value.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class EqualTo extends FieldValidator {
  /// The name of the field to compare with.
  final String field;

  const EqualTo(this.field, {super.message = 'Fields must match'});
}

/// Validates that this field is different from another field's value.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class NotEqualTo extends FieldValidator {
  /// The name of the field to compare with.
  final String field;

  const NotEqualTo(this.field, {super.message = 'Fields must be different'});
}

// ═══════════════════════════════════════════════════════════════════════════
// Date Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Validates that date is in the past.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class PastDate extends FieldValidator {
  const PastDate({super.message = 'Date must be in the past'});
}

/// Validates that date is in the future.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class FutureDate extends FieldValidator {
  const FutureDate({super.message = 'Date must be in the future'});
}

/// Validates minimum age (date must be at least X years ago).
@immutable
@Target({TargetKind.field, TargetKind.getter})
class MinAge extends FieldValidator {
  final int years;

  const MinAge(this.years, {String? message})
      : super(message: message ?? 'Must be at least $years years old');
}

// ═══════════════════════════════════════════════════════════════════════════
// Collection Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Validates minimum number of items in a list.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class MinItems extends FieldValidator {
  final int count;

  const MinItems(this.count, {String? message})
      : super(message: message ?? 'Must have at least $count items');
}

/// Validates maximum number of items in a list.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class MaxItems extends FieldValidator {
  final int count;

  const MaxItems(this.count, {String? message})
      : super(message: message ?? 'Must have at most $count items');
}

// ═══════════════════════════════════════════════════════════════════════════
// Boolean Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Validates that a boolean field is true.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class MustBeTrue extends FieldValidator {
  const MustBeTrue({super.message = 'This field must be checked'});
}

/// Validates that a boolean field is false.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class MustBeFalse extends FieldValidator {
  const MustBeFalse({super.message = 'This field must be unchecked'});
}

// ═══════════════════════════════════════════════════════════════════════════
// Custom Validator
// ═══════════════════════════════════════════════════════════════════════════

/// Applies a custom validation function.
///
/// The function name must be a static method that takes the field value
/// and returns a String? (null if valid, error message if invalid).
///
/// Example:
/// ```dart
/// @Custom('validateUsername')
/// final String username;
///
/// // In the same class or a separate validator class:
/// static String? validateUsername(String value) {
///   if (value.contains(' ')) return 'Username cannot contain spaces';
///   return null;
/// }
/// ```
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Custom extends FieldValidator {
  /// The name of the validation function.
  final String validatorName;

  const Custom(this.validatorName, {super.message});
}

// ═══════════════════════════════════════════════════════════════════════════
// Conditional Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Makes validation conditional based on another field's value.
///
/// Example:
/// ```dart
/// @RequiredIf('hasCompany', true)
/// final String companyName;
/// ```
@immutable
@Target({TargetKind.field, TargetKind.getter})
class RequiredIf extends FieldValidator {
  /// The field to check.
  final String field;

  /// The value that triggers the requirement.
  final Object? value;

  const RequiredIf(this.field, this.value, {super.message = 'This field is required'});
}

/// Makes validation conditional - required unless another field has a value.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class RequiredUnless extends FieldValidator {
  /// The field to check.
  final String field;

  /// The value that removes the requirement.
  final Object? value;

  const RequiredUnless(this.field, this.value, {super.message = 'This field is required'});
}

// ═══════════════════════════════════════════════════════════════════════════
// Credit Card Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Validates credit card number format (Luhn algorithm).
@immutable
@Target({TargetKind.field, TargetKind.getter})
class CreditCard extends FieldValidator {
  const CreditCard({super.message = 'Invalid credit card number'});
}

/// Validates CVV format.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class Cvv extends FieldValidator {
  const Cvv({super.message = 'Invalid CVV'});
}

/// Validates expiry date format (MM/YY or MM/YYYY).
@immutable
@Target({TargetKind.field, TargetKind.getter})
class ExpiryDate extends FieldValidator {
  const ExpiryDate({super.message = 'Invalid or expired date'});
}

// ═══════════════════════════════════════════════════════════════════════════
// Password Validators
// ═══════════════════════════════════════════════════════════════════════════

/// Validates password strength.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class StrongPassword extends FieldValidator {
  /// Minimum length (default: 8).
  final int minLength;

  /// Require uppercase letter.
  final bool requireUppercase;

  /// Require lowercase letter.
  final bool requireLowercase;

  /// Require digit.
  final bool requireDigit;

  /// Require special character.
  final bool requireSpecial;

  const StrongPassword({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireDigit = true,
    this.requireSpecial = false,
    super.message = 'Password does not meet requirements',
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Field Metadata
// ═══════════════════════════════════════════════════════════════════════════

/// Provides additional metadata for a form field.
@immutable
@Target({TargetKind.field, TargetKind.getter})
class FormField {
  /// Display label for the field.
  final String? label;

  /// Placeholder/hint text.
  final String? hint;

  /// Help text shown below the field.
  final String? helpText;

  /// Whether to obscure text (for passwords).
  final bool obscureText;

  /// Keyboard type for text fields.
  final FormKeyboardType keyboardType;

  /// Text capitalization.
  final FormTextCapitalization textCapitalization;

  /// Whether field is enabled.
  final bool enabled;

  /// Whether field is read-only.
  final bool readOnly;

  /// Maximum lines for text area.
  final int? maxLines;

  /// Autofill hints.
  final List<String> autofillHints;

  const FormField({
    this.label,
    this.hint,
    this.helpText,
    this.obscureText = false,
    this.keyboardType = FormKeyboardType.text,
    this.textCapitalization = FormTextCapitalization.none,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines,
    this.autofillHints = const [],
  });
}

/// Keyboard type for form fields.
enum FormKeyboardType {
  text,
  multiline,
  number,
  phone,
  datetime,
  emailAddress,
  url,
  visiblePassword,
  name,
  streetAddress,
}

/// Text capitalization for form fields.
enum FormTextCapitalization {
  none,
  characters,
  words,
  sentences,
}
