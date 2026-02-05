/// Runtime validators for form validation.
///
/// These are used by the generated code to perform actual validation.
/// Each validator returns null if valid, or an error message if invalid.

typedef Validator<T> = String? Function(T? value);
typedef CrossFieldValidator<T> = String? Function(T? value, Map<String, dynamic> allValues);

/// Collection of built-in validators.
class Validators {
  Validators._();

  // ═══════════════════════════════════════════════════════════════════════════
  // String Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that a value is not null or empty.
  static Validator<T> required<T>([String message = 'This field is required']) {
    return (value) {
      if (value == null) return message;
      if (value is String && value.isEmpty) return message;
      if (value is Iterable && value.isEmpty) return message;
      if (value is Map && value.isEmpty) return message;
      return null;
    };
  }

  /// Validates email format.
  static Validator<String> email([String message = 'Invalid email format']) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : message;
    };
  }

  /// Validates minimum string length.
  static Validator<String> minLength(int length, [String? message]) {
    final msg = message ?? 'Must be at least $length characters';
    return (value) {
      if (value == null || value.isEmpty) return null;
      return value.length >= length ? null : msg;
    };
  }

  /// Validates maximum string length.
  static Validator<String> maxLength(int length, [String? message]) {
    final msg = message ?? 'Must be at most $length characters';
    return (value) {
      if (value == null || value.isEmpty) return null;
      return value.length <= length ? null : msg;
    };
  }

  /// Validates string matches a regex pattern.
  static Validator<String> pattern(String patternStr, [String message = 'Invalid format']) {
    final regex = RegExp(patternStr);
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : message;
    };
  }

  /// Validates URL format.
  static Validator<String> url([String message = 'Invalid URL format']) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      try {
        final uri = Uri.parse(value);
        return (uri.hasScheme && uri.hasAuthority) ? null : message;
      } catch (_) {
        return message;
      }
    };
  }

  /// Validates phone number format.
  static Validator<String> phone([String message = 'Invalid phone number']) {
    final regex = RegExp(r'^\+?[\d\s\-()]{10,}$');
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : message;
    };
  }

  /// Validates that string contains only alphanumeric characters.
  static Validator<String> alphanumeric([String message = 'Must contain only letters and numbers']) {
    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : message;
    };
  }

  /// Validates that string contains only alphabetic characters.
  static Validator<String> alpha([String message = 'Must contain only letters']) {
    final regex = RegExp(r'^[a-zA-Z]+$');
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : message;
    };
  }

  /// Validates that string contains only numeric characters.
  static Validator<String> numeric([String message = 'Must contain only numbers']) {
    final regex = RegExp(r'^[0-9]+$');
    return (value) {
      if (value == null || value.isEmpty) return null;
      return regex.hasMatch(value) ? null : message;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Number Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates minimum numeric value.
  static Validator<num> min(num minValue, [String? message]) {
    final msg = message ?? 'Must be at least $minValue';
    return (value) {
      if (value == null) return null;
      return value >= minValue ? null : msg;
    };
  }

  /// Validates maximum numeric value.
  static Validator<num> max(num maxValue, [String? message]) {
    final msg = message ?? 'Must be at most $maxValue';
    return (value) {
      if (value == null) return null;
      return value <= maxValue ? null : msg;
    };
  }

  /// Validates value is within a range.
  static Validator<num> range(num minValue, num maxValue, [String? message]) {
    final msg = message ?? 'Must be between $minValue and $maxValue';
    return (value) {
      if (value == null) return null;
      return (value >= minValue && value <= maxValue) ? null : msg;
    };
  }

  /// Validates that number is positive.
  static Validator<num> positive([String message = 'Must be a positive number']) {
    return (value) {
      if (value == null) return null;
      return value > 0 ? null : message;
    };
  }

  /// Validates that number is negative.
  static Validator<num> negative([String message = 'Must be a negative number']) {
    return (value) {
      if (value == null) return null;
      return value < 0 ? null : message;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Boolean Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that a boolean field is true.
  static Validator<bool> mustBeTrue([String message = 'This field must be checked']) {
    return (value) {
      if (value == null) return null;
      return value == true ? null : message;
    };
  }

  /// Validates that a boolean field is false.
  static Validator<bool> mustBeFalse([String message = 'This field must be unchecked']) {
    return (value) {
      if (value == null) return null;
      return value == false ? null : message;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Date Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that date is in the past.
  static Validator<DateTime> pastDate([String message = 'Date must be in the past']) {
    return (value) {
      if (value == null) return null;
      return value.isBefore(DateTime.now()) ? null : message;
    };
  }

  /// Validates that date is in the future.
  static Validator<DateTime> futureDate([String message = 'Date must be in the future']) {
    return (value) {
      if (value == null) return null;
      return value.isAfter(DateTime.now()) ? null : message;
    };
  }

  /// Validates minimum age (date must be at least X years ago).
  static Validator<DateTime> minAge(int years, [String? message]) {
    final msg = message ?? 'Must be at least $years years old';
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
    final msg = message ?? 'Must have at least $count items';
    return (value) {
      if (value == null) return null;
      return value.length >= count ? null : msg;
    };
  }

  /// Validates maximum number of items in a list.
  static Validator<List<T>> maxItems<T>(int count, [String? message]) {
    final msg = message ?? 'Must have at most $count items';
    return (value) {
      if (value == null) return null;
      return value.length <= count ? null : msg;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Comparison Validators (Cross-field)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that this field equals another field's value.
  static CrossFieldValidator<T> equalTo<T>(String fieldName, [String message = 'Fields must match']) {
    return (value, allValues) {
      if (value == null) return null;
      final otherValue = allValues[fieldName];
      return value == otherValue ? null : message;
    };
  }

  /// Validates that this field is different from another field's value.
  static CrossFieldValidator<T> notEqualTo<T>(String fieldName, [String message = 'Fields must be different']) {
    return (value, allValues) {
      if (value == null) return null;
      final otherValue = allValues[fieldName];
      return value != otherValue ? null : message;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conditional Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Makes validation conditional based on another field's value.
  static CrossFieldValidator<T> requiredIf<T>(
    String fieldName,
    Object? expectedValue, [
    String message = 'This field is required',
  ]) {
    return (value, allValues) {
      final otherValue = allValues[fieldName];
      if (otherValue != expectedValue) return null;

      // Now check if this field is required
      if (value == null) return message;
      if (value is String && value.isEmpty) return message;
      if (value is Iterable && value.isEmpty) return message;
      return null;
    };
  }

  /// Makes validation conditional - required unless another field has a value.
  static CrossFieldValidator<T> requiredUnless<T>(
    String fieldName,
    Object? expectedValue, [
    String message = 'This field is required',
  ]) {
    return (value, allValues) {
      final otherValue = allValues[fieldName];
      if (otherValue == expectedValue) return null;

      // Now check if this field is required
      if (value == null) return message;
      if (value is String && value.isEmpty) return message;
      if (value is Iterable && value.isEmpty) return message;
      return null;
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Credit Card Validators
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates credit card number format (Luhn algorithm).
  static Validator<String> creditCard([String message = 'Invalid credit card number']) {
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

      return sum % 10 == 0 ? null : message;
    };
  }

  /// Validates CVV format.
  static Validator<String> cvv([String message = 'Invalid CVV']) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      final regex = RegExp(r'^\d{3,4}$');
      return regex.hasMatch(value) ? null : message;
    };
  }

  /// Validates expiry date format (MM/YY or MM/YYYY).
  static Validator<String> expiryDate([String message = 'Invalid or expired date']) {
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

      return expiry.isAfter(now) ? null : message;
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
    String message = 'Password does not meet requirements',
  }) {
    return (value) {
      if (value == null || value.isEmpty) return null;

      final errors = <String>[];

      if (value.length < minLength) {
        errors.add('at least $minLength characters');
      }
      if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(value)) {
        errors.add('an uppercase letter');
      }
      if (requireLowercase && !RegExp(r'[a-z]').hasMatch(value)) {
        errors.add('a lowercase letter');
      }
      if (requireDigit && !RegExp(r'\d').hasMatch(value)) {
        errors.add('a number');
      }
      if (requireSpecial && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
        errors.add('a special character');
      }

      if (errors.isEmpty) return null;

      return 'Password must contain ${errors.join(', ')}';
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
