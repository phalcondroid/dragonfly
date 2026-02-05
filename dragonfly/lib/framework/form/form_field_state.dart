/// Represents the state of a single form field.
///
/// Tracks:
/// - Current value
/// - Validation errors
/// - Touched state (has been focused and blurred)
/// - Dirty state (value has changed from initial)
class FormFieldState<T> {
  /// The current value of the field.
  final T value;

  /// The initial value of the field.
  final T initialValue;

  /// Current validation error, if any.
  final String? error;

  /// Whether the field has been touched (focused and blurred).
  final bool touched;

  /// Whether the field value has changed from initial.
  bool get dirty => value != initialValue;

  /// Whether the field is currently valid (no error).
  bool get isValid => error == null;

  /// Whether the field is invalid (has error).
  bool get isInvalid => error != null;

  /// Whether to show the error (touched and has error).
  bool get showError => touched && isInvalid;

  const FormFieldState({
    required this.value,
    required this.initialValue,
    this.error,
    this.touched = false,
  });

  /// Creates a copy with updated values.
  FormFieldState<T> copyWith({
    T? value,
    T? initialValue,
    String? error,
    bool? touched,
    bool clearError = false,
  }) {
    return FormFieldState<T>(
      value: value ?? this.value,
      initialValue: initialValue ?? this.initialValue,
      error: clearError ? null : (error ?? this.error),
      touched: touched ?? this.touched,
    );
  }

  /// Resets the field to initial state.
  FormFieldState<T> reset() {
    return FormFieldState<T>(
      value: initialValue,
      initialValue: initialValue,
      error: null,
      touched: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormFieldState<T> &&
        other.value == value &&
        other.initialValue == initialValue &&
        other.error == error &&
        other.touched == touched;
  }

  @override
  int get hashCode => Object.hash(value, initialValue, error, touched);

  @override
  String toString() {
    return 'FormFieldState(value: $value, error: $error, touched: $touched, dirty: $dirty)';
  }
}
