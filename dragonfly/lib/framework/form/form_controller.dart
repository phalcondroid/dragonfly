import 'package:dragonfly/framework/form/form_field_state.dart';
import 'package:dragonfly/framework/form/validators.dart';

/// Abstract base class for generated form controllers.
///
/// This class is extended by the generated form state classes.
/// It provides common functionality for form validation and state management.
abstract class FormController<T> {
  /// Map of field names to their states.
  Map<String, DragonflyFormFieldState<dynamic>> get fields;

  /// Map of field names to their validators.
  Map<String, List<Validator<dynamic>>> get validators;

  /// Map of field names to their cross-field validators.
  Map<String, List<CrossFieldValidator<dynamic>>> get crossFieldValidators;

  /// Whether to validate on field change.
  bool get validateOnChange;

  /// Whether to validate on field blur.
  bool get validateOnBlur;

  /// Whether the entire form is valid.
  bool get isValid => fields.values.every((f) => f.isValid);

  /// Whether the entire form is invalid.
  bool get isInvalid => !isValid;

  /// Whether any field has been touched.
  bool get isTouched => fields.values.any((f) => f.touched);

  /// Whether any field is dirty (changed from initial).
  bool get isDirty => fields.values.any((f) => f.dirty);

  /// Gets all current field values as a map.
  Map<String, dynamic> get values {
    return fields.map((key, state) => MapEntry(key, state.value));
  }

  /// Gets all current errors as a map.
  Map<String, String?> get errors {
    return fields.map((key, state) => MapEntry(key, state.error));
  }

  /// Gets all non-null errors.
  Map<String, String> get activeErrors {
    return Map.fromEntries(
      fields.entries
          .where((e) => e.value.error != null)
          .map((e) => MapEntry(e.key, e.value.error!)),
    );
  }

  /// Validates a single field.
  String? validateField(String fieldName) {
    final fieldState = fields[fieldName];
    if (fieldState == null) return null;

    // Run standard validators
    final fieldValidators = validators[fieldName] ?? [];
    for (final validator in fieldValidators) {
      final error = validator(fieldState.value);
      if (error != null) return error;
    }

    // Run cross-field validators
    final crossValidators = crossFieldValidators[fieldName] ?? [];
    for (final validator in crossValidators) {
      final error = validator(fieldState.value, values);
      if (error != null) return error;
    }

    return null;
  }

  /// Validates all fields.
  bool validateAll() {
    bool allValid = true;
    for (final fieldName in fields.keys) {
      final error = validateField(fieldName);
      if (error != null) {
        allValid = false;
      }
    }
    return allValid;
  }

  /// Gets the error for a specific field.
  String? getError(String fieldName) => fields[fieldName]?.error;

  /// Gets the value for a specific field.
  T? getValue<T>(String fieldName) => fields[fieldName]?.value as T?;

  /// Checks if a specific field is valid.
  bool isFieldValid(String fieldName) => fields[fieldName]?.isValid ?? true;

  /// Checks if a specific field is touched.
  bool isFieldTouched(String fieldName) => fields[fieldName]?.touched ?? false;

  /// Checks if a specific field is dirty.
  bool isFieldDirty(String fieldName) => fields[fieldName]?.dirty ?? false;

  /// Checks if a specific field should show its error.
  bool shouldShowError(String fieldName) => fields[fieldName]?.showError ?? false;
}
