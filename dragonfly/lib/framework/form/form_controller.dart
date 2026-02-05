import 'package:dragonfly/framework/form/form_field_state.dart';
import 'package:dragonfly/framework/form/validators.dart';

/// Abstract base class for generated form controllers.
///
/// This class is extended by the generated form state classes.
/// It provides common functionality for form validation and state management.
abstract class FormController<T> {
  /// Map of field names to their states.
  Map<String, FormFieldState<dynamic>> get fields;

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

/// Mixin that provides form controller functionality for StateManagers.
///
/// This is used by generated form state classes to integrate with StateManager.
mixin FormControllerMixin<F extends FormController<dynamic>> {
  /// The current form state.
  F get formState;

  /// Updates the form state.
  void updateFormState(F newState);

  /// Updates a field value.
  void updateField(String fieldName, dynamic value) {
    final currentField = formState.fields[fieldName];
    if (currentField == null) return;

    final newFieldState = currentField.copyWith(
      value: value,
      clearError: !formState.validateOnChange,
    );

    // Validate if validateOnChange is true
    String? error;
    if (formState.validateOnChange) {
      error = _validateFieldWithValue(fieldName, value);
    }

    _updateFieldState(fieldName, newFieldState.copyWith(error: error));
  }

  /// Marks a field as touched.
  void touchField(String fieldName) {
    final currentField = formState.fields[fieldName];
    if (currentField == null) return;

    var newFieldState = currentField.copyWith(touched: true);

    // Validate if validateOnBlur is true
    if (formState.validateOnBlur) {
      final error = _validateFieldWithValue(fieldName, currentField.value);
      newFieldState = newFieldState.copyWith(error: error);
    }

    _updateFieldState(fieldName, newFieldState);
  }

  /// Sets an error on a field manually.
  void setFieldError(String fieldName, String? error) {
    final currentField = formState.fields[fieldName];
    if (currentField == null) return;

    _updateFieldState(fieldName, currentField.copyWith(error: error, clearError: error == null));
  }

  /// Clears a field's error.
  void clearFieldError(String fieldName) {
    setFieldError(fieldName, null);
  }

  /// Validates a specific field and updates its error state.
  bool validateField(String fieldName) {
    final currentField = formState.fields[fieldName];
    if (currentField == null) return true;

    final error = _validateFieldWithValue(fieldName, currentField.value);
    _updateFieldState(fieldName, currentField.copyWith(error: error, clearError: error == null));

    return error == null;
  }

  /// Validates all fields and returns true if all are valid.
  bool validateAll() {
    bool allValid = true;

    for (final fieldName in formState.fields.keys) {
      final currentField = formState.fields[fieldName]!;
      final error = _validateFieldWithValue(fieldName, currentField.value);

      if (error != null) {
        allValid = false;
      }

      _updateFieldState(
        fieldName,
        currentField.copyWith(
          error: error,
          clearError: error == null,
          touched: true,
        ),
      );
    }

    return allValid;
  }

  /// Resets the form to initial values.
  void resetForm();

  /// Internal method to validate a field with a specific value.
  String? _validateFieldWithValue(String fieldName, dynamic value) {
    // Run standard validators
    final fieldValidators = formState.validators[fieldName] ?? [];
    for (final validator in fieldValidators) {
      final error = validator(value);
      if (error != null) return error;
    }

    // Run cross-field validators
    final crossValidators = formState.crossFieldValidators[fieldName] ?? [];
    final allValues = formState.values;
    allValues[fieldName] = value; // Use the new value for cross-field validation

    for (final validator in crossValidators) {
      final error = validator(value, allValues);
      if (error != null) return error;
    }

    return null;
  }

  /// Internal method to update a field's state.
  void _updateFieldState(String fieldName, FormFieldState<dynamic> newFieldState);
}
