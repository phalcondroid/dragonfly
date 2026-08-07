/// Runtime validators for form validation.
///
/// These are used by the generated code to perform actual validation.
/// Each validator returns null if valid, or an error message if invalid.

import 'dragonfly_validation_messages.dart';

typedef Validator<T> = String? Function(T? value);
typedef CrossFieldValidator<T> = String? Function(T? value, Map<String, dynamic> allValues);

/// Collection of built-in validators.
///
/// Each validator accepts an optional [message] parameter. If omitted,
/// the message is read from the global [DragonflyValidationMessages]
/// instance (set via [DragonflyConfig.validationMessages]), falling
/// back to English defaults.
class Validators {
  Validators._();

  static DragonflyValidationMessages? _messages;

  /// Sets the global validation messages used by all validators.
  ///
  /// Called during [DragonflyApp.init] if [DragonflyConfig.validationMessages]
  /// is not null.
  static void setMessages(DragonflyValidationMessages messages) {
    _messages = messages;
  }

  static DragonflyValidationMessages get _m =>
      _messages ?? const DragonflyValidationMessages();

  // ═══════════════════════════════════════════════════════════════════════════
  // String Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that a value is not null or empty.
  static Validator<T> required<T>([String? message]) {
    final msg = message ?? _m.required;
    return (value) {
      if (value == null) return msg;
      if (value is String && value.isEmpty) return msg;
      if (value is Iterable && value.isEmpty) return msg;
      if (value is Map && value.isEmpty) return msg;
      return null;
    };
  }

  /// Validates email format.
  static Validator<String> email([String? message]) {
    final msg = message ?? _m.invalidEmail;
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : msg;
    };
  }

  /// Validates minimum string length.
  static Validator<String> minLength(int length, [String? message]) {
    final msg = message ?? _m.minLength(length);
    return (value) {
      if (value == null || value.isEmpty) return null;
      return value.length >= length ? null : msg;
    };
  }

  /// Validates maximum string length.
  static Validator<String> maxLength(int length, [String? message]) {
    final msg = message ?? _m.maxLength(length);
    return (value) {
      if (value == null || value.isEmpty) return null;
      return value.length <= length ? null : msg;
    };
  }

  /// Validates string matches a regex pattern.
  static Validator<String> pattern(String patternStr, [String? message]) {
    final msg = message ?? _m.invalidFormat;
    final regex = RegExp(patternStr);
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : msg;
    };
  }

  /// Validates URL format.
  static Validator<String> url([String? message]) {
    final msg = message ?? _m.invalidUrl;
    return (value) {
      if (value == null || value.isEmpty) return null;
      try {
        final uri = Uri.parse(value);
        return (uri.hasScheme && uri.hasAuthority) ? null : msg;
      } catch (_) {
        return msg;
      }
    };
  }

  /// Validates phone number format.
  static Validator<String> phone([String? message]) {
    final msg = message ?? _m.invalidPhone;
    final regex = RegExp(r'^\+?[\d\s\-()]{10,}$');
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : msg;
    };
  }

  /// Validates that string contains only alphanumeric characters.
  static Validator<String> alphanumeric([String? message]) {
    final msg = message ?? _m.notAlphanumeric;
    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : msg;
    };
  }

  /// Validates that string contains only alphabetic characters.
  static Validator<String> alpha([String? message]) {
    final msg = message ?? _m.notAlpha;
    final regex = RegExp(r'^[a-zA-Z]+$');
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : msg;
    };
  }

  /// Validates that string contains only numeric characters.
  static Validator<String> numeric([String? message]) {
    final msg = message ?? _m.notNumeric;
    final regex = RegExp(r'^[0-9]+$');
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : msg;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Number Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates minimum numeric value.
  static Validator<num> min(num minValue, [String? message]) {
    final msg = message ?? _m.tooLow(minValue);
    return (value) {
      if (value == null) return null;
      return value >= minValue ? null : msg;
    };
  }

  /// Validates maximum numeric value.
  static Validator<num> max(num maxValue, [String? message]) {
    final msg = message ?? _m.tooHigh(maxValue);
    return (value) {
      if (value == null) return null;
      return value <= maxValue ? null : msg;
    };
  }

  /// Validates value is within a range.
  static Validator<num> range(num minValue, num maxValue, [String? message]) {
    final msg = message ?? _m.outOfRange(minValue, maxValue);
    return (value) {
      if (value == null) return null;
      return (value >= minValue && value <= maxValue) ? null : msg;
    };
  }

  /// Validates that number is positive.
  static Validator<num> positive([String? message]) {
    final msg = message ?? _m.notPositive;
    return (value) {
      if (value == null) return null;
      return value > 0 ? null : msg;
    };
  }

  /// Validates that number is negative.
  static Validator<num> negative([String? message]) {
    final msg = message ?? _m.notNegative;
    return (value) {
      if (value == null) return null;
      return value < 0 ? null : msg;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Boolean Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that a boolean field is true.
  static Validator<bool> mustBeTrue([String? message]) {
    final msg = message ?? _m.mustBeTrue;
    return (value) {
      if (value == null) return null;
      return value == true ? null : msg;
    };
  }

  /// Validates that a boolean field is false.
  static Validator<bool> mustBeFalse([String? message]) {
    final msg = message ?? _m.mustBeFalse;
    return (value) {
      if (value == null) return null;
      return value == false ? null : msg;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Date Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that date is in the past.
  static Validator<DateTime> pastDate([String? message]) {
    final msg = message ?? _m.dateInPast;
    return (value) {
      if (value == null) return null;
      return value.isBefore(DateTime.now()) ? null : msg;
    };
  }

  /// Validates that date is in the future.
  static Validator<DateTime> futureDate([String? message]) {
    final msg = message ?? _m.dateInFuture;
    return (value) {
      if (value == null) return null;
      return value.isAfter(DateTime.now()) ? null : msg;
    };
  }

  /// Validates minimum age (date must be at least X years ago).
  static Validator<DateTime> minAge(int years, [String? message]) {
    final msg = message ?? _m.tooYoung(years);
    return (value) {
      if (value == null) return null;
      final minDate = DateTime.now().subtract(Duration(days: years * 365));
      return value.isBefore(minDate) ? null : msg;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Collection Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates minimum number of items in a list.
  static Validator<List<T>> minItems<T>(int count, [String? message]) {
    final msg = message ?? _m.tooFewItems(count);
    return (value) {
      if (value == null) return null;
      return value.length >= count ? null : msg;
    };
  }

  /// Validates maximum number of items in a list.
  static Validator<List<T>> maxItems<T>(int count, [String? message]) {
    final msg = message ?? _m.tooManyItems(count);
    return (value) {
      if (value == null) return null;
      return value.length <= count ? null : msg;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Comparison Validators (Cross-field)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that this field equals another field's value.
  static CrossFieldValidator<T> equalTo<T>(String fieldName, [String? message]) {
    final msg = message ?? _m.fieldsMustMatch;
    return (value, allValues) {
      if (value == null) return null;
      final otherValue = allValues[fieldName];
      return value == otherValue ? null : msg;
    };
  }

  /// Validates that this field is different from another field's value.
  static CrossFieldValidator<T> notEqualTo<T>(String fieldName, [String? message]) {
    final msg = message ?? _m.fieldsMustDiffer;
    return (value, allValues) {
      if (value == null) return null;
      final otherValue = allValues[fieldName];
      return value != otherValue ? null : msg;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conditional Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Makes validation conditional based on another field's value.
  static CrossFieldValidator<T> requiredIf<T>(
    String fieldName,
    Object? expectedValue, [
    String? message,
  ]) {
    final msg = message ?? _m.requiredConditional;
    return (value, allValues) {
      final otherValue = allValues[fieldName];
      if (otherValue != expectedValue) return null;

      if (value == null) return msg;
      if (value is String && value.isEmpty) return msg;
      if (value is Iterable && value.isEmpty) return msg;
      return null;
    };
  }

  /// Makes validation conditional - required unless another field has a value.
  static CrossFieldValidator<T> requiredUnless<T>(
    String fieldName,
    Object? expectedValue, [
    String? message,
  ]) {
    final msg = message ?? _m.requiredConditional;
    return (value, allValues) {
      final otherValue = allValues[fieldName];
      if (otherValue == expectedValue) return null;

      if (value == null) return msg;
      if (value is String && value.isEmpty) return msg;
      if (value is Iterable && value.isEmpty) return msg;
      return null;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Credit Card Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates credit card number format (Luhn algorithm).
  static Validator<String> creditCard([String? message]) {
    final msg = message ?? _m.invalidCreditCard;
    return (value) {
      if (value == null || value.isEmpty) return null;

      // Remove spaces and dashes
      final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

      // Check if it's all digits
      if (!RegExp(r'^\d+$').hasMatch(cleaned)) return message;

      // Luhn algorithm
      int sum = 0;
      bool alternate = false;
      for (int i = cleaned.length - 1; i >= 0; i--) {
        int digit = int.parse(cleaned[i]);
        if (alternate) {
          digit *= 2;
          if (digit > 9) digit -= 9;
        }
        sum += digit;
        alternate = !alternate;
      }

      return sum % 10 == 0 ? null : msg;
    };
  }

  /// Validates CVV format.
  static Validator<String> cvv([String? message]) {
    final msg = message ?? _m.invalidCvv;
    return (value) {
      if (value == null || value.isEmpty) return null;
      final regex = RegExp(r'^\d{3,4}$');
      return regex.hasMatch(value) ? null : msg;
    };
  }

  /// Validates expiry date format (MM/YY or MM/YYYY).
  static Validator<String> expiryDate([String? message]) {
    final msg = message ?? _m.invalidExpiryDate;
    return (value) {
      if (value == null || value.isEmpty) return null;

      final regex = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$');
      if (!regex.hasMatch(value)) return message;

      final parts = value.split('/');
      final month = int.parse(parts[0]);
      var year = int.parse(parts[1]);

      // Convert 2-digit year to 4-digit
      if (year < 100) {
        year += 2000;
      }

      final expiry = DateTime(year, month + 1, 0); // Last day of the month
      final now = DateTime.now();

      return expiry.isAfter(now) ? null : msg;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Password Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates password strength.
  static Validator<String> strongPassword({
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireDigit = true,
    bool requireSpecial = false,
    String? message,
  }) {
    final msg = message ?? _m.weakPassword;
    return (value) {
      if (value == null || value.isEmpty) return null;

      final errors = <String>[];

      if (value.length < minLength) {
        errors.add(_m.passwordChars(minLength));
      }
      if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(value)) {
        errors.add(_m.passwordUppercase);
      }
      if (requireLowercase && !RegExp(r'[a-z]').hasMatch(value)) {
        errors.add(_m.passwordLowercase);
      }
      if (requireDigit && !RegExp(r'\d').hasMatch(value)) {
        errors.add(_m.passwordNumber);
      }
      if (requireSpecial && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
        errors.add(_m.passwordSpecial);
      }

      if (errors.isEmpty) return null;

      return _m.passwordRequirements(errors);
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Compose Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Composes multiple validators into a single validator.
  /// Returns the first error encountered, or null if all pass.
  static Validator<T> compose<T>(List<Validator<T>> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Composes multiple cross-field validators into a single validator.
  static CrossFieldValidator<T> composeCrossField<T>(List<CrossFieldValidator<T>> validators) {
    return (value, allValues) {
      for (final validator in validators) {
        final error = validator(value, allValues);
        if (error != null) return error;
      }
      return null;
    };
  }
}
