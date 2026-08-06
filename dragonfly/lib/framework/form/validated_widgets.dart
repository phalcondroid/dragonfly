import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dragonfly/framework/state/state_builder.dart';
import 'package:dragonfly/framework/state/state_controller.dart';

/// A text field that integrates with form validation.
///
/// Automatically displays validation errors and updates form state.
///
/// Example:
/// ```dart
/// ValidatedTextField<$LoginStateManagerController, LoginStateManagerState>(
///   stateController: loginController,
///   fieldName: 'email',
///   formSelector: (state) => state.form,
///   onChanged: (value) => loginController.updateField('email', value),
///   onBlur: () => loginController.touchField('email'),
///   decoration: InputDecoration(labelText: 'Email'),
/// )
/// ```
class ValidatedTextField<S> extends StatelessWidget {
  const ValidatedTextField({
    super.key,
    required this.stateController,
    required this.fieldName,
    required this.formSelector,
    required this.onChanged,
    this.onBlur,
    this.decoration,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autofillHints,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.controller,
    this.style,
    this.showErrorOnlyWhenTouched = true,
  });

  /// The controller whose state drives validation display.
  final DragonflyController<S> stateController;

  /// The name of the form field.
  final String fieldName;

  /// Selector to get the form state from the StateManager state.
  final FormStateAccessor<S> formSelector;

  /// Called when the field value changes.
  final ValueChanged<String> onChanged;

  /// Called when the field loses focus.
  final VoidCallback? onBlur;

  /// Input decoration for the text field.
  final InputDecoration? decoration;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Text capitalization.
  final TextCapitalization textCapitalization;

  /// Whether to obscure text (for passwords).
  final bool obscureText;

  /// Maximum number of lines.
  final int? maxLines;

  /// Minimum number of lines.
  final int? minLines;

  /// Maximum length of input.
  final int? maxLength;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether to autofocus.
  final bool autofocus;

  /// Autofill hints.
  final Iterable<String>? autofillHints;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Text input action.
  final TextInputAction? textInputAction;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  /// Focus node.
  final FocusNode? focusNode;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Text style.
  final TextStyle? style;

  /// Whether to show error only when field is touched.
  final bool showErrorOnlyWhenTouched;

  @override
  Widget build(BuildContext context) {
    return DragonflyStateBuilder<S>(
      controller: stateController,
      builder: (context, state) {
        final formState = formSelector(state);
        final fieldState = formState.fields[fieldName];

        final value = fieldState?.value?.toString() ?? '';
        final error = fieldState?.error;
        final touched = fieldState?.touched ?? false;
        final showError = showErrorOnlyWhenTouched ? (touched && error != null) : error != null;

        return Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              onBlur?.call();
            }
          },
          child: TextFormField(
            key: ValueKey('$fieldName-$value'),
            initialValue: controller == null ? value : null,
            controller: controller,
            decoration: (decoration ?? const InputDecoration()).copyWith(
              errorText: showError ? error : null,
            ),
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            enabled: enabled,
            readOnly: readOnly,
            autofocus: autofocus,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            focusNode: focusNode,
            style: style,
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

/// A dropdown that integrates with form validation.
class ValidatedDropdown<S, T> extends StatelessWidget {
  const ValidatedDropdown({
    super.key,
    required this.stateController,
    required this.fieldName,
    required this.formSelector,
    required this.items,
    required this.onChanged,
    this.onBlur,
    this.decoration,
    this.hint,
    this.disabledHint,
    this.enabled = true,
    this.isDense = true,
    this.isExpanded = false,
    this.itemBuilder,
    this.selectedItemBuilder,
    this.showErrorOnlyWhenTouched = true,
  });

  /// The controller whose state drives validation display.
  final DragonflyController<S> stateController;

  final String fieldName;
  final FormStateAccessor<S> formSelector;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final VoidCallback? onBlur;
  final InputDecoration? decoration;
  final Widget? hint;
  final Widget? disabledHint;
  final bool enabled;
  final bool isDense;
  final bool isExpanded;
  final Widget Function(T item)? itemBuilder;
  final Widget Function(T item)? selectedItemBuilder;
  final bool showErrorOnlyWhenTouched;

  @override
  Widget build(BuildContext context) {
    return DragonflyStateBuilder<S>(
      controller: stateController,
      builder: (context, state) {
        final formState = formSelector(state);
        final fieldState = formState.fields[fieldName];

        final value = fieldState?.value as T?;
        final error = fieldState?.error;
        final touched = fieldState?.touched ?? false;
        final showError = showErrorOnlyWhenTouched ? (touched && error != null) : error != null;

        return Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              onBlur?.call();
            }
          },
          child: DropdownButtonFormField<T>(
            value: items.contains(value) ? value : null,
            decoration: (decoration ?? const InputDecoration()).copyWith(
              errorText: showError ? error : null,
            ),
            hint: hint,
            disabledHint: disabledHint,
            isDense: isDense,
            isExpanded: isExpanded,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: itemBuilder?.call(item) ?? Text(item.toString()),
              );
            }).toList(),
            selectedItemBuilder: selectedItemBuilder != null
                ? (context) => items.map((item) => selectedItemBuilder!(item)).toList()
                : null,
            onChanged: enabled ? onChanged : null,
          ),
        );
      },
    );
  }
}

/// A checkbox that integrates with form validation.
class ValidatedCheckbox<S> extends StatelessWidget {
  const ValidatedCheckbox({
    super.key,
    required this.stateController,
    required this.fieldName,
    required this.formSelector,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.enabled = true,
    this.dense = false,
    this.contentPadding,
    this.showErrorOnlyWhenTouched = true,
  });

  /// The controller whose state drives validation display.
  final DragonflyController<S> stateController;

  final String fieldName;
  final FormStateAccessor<S> formSelector;
  final ValueChanged<bool?> onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool enabled;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;
  final bool showErrorOnlyWhenTouched;

  @override
  Widget build(BuildContext context) {
    return DragonflyStateBuilder<S>(
      controller: stateController,
      builder: (context, state) {
        final formState = formSelector(state);
        final fieldState = formState.fields[fieldName];

        final value = fieldState?.value as bool? ?? false;
        final error = fieldState?.error;
        final touched = fieldState?.touched ?? false;
        final showError = showErrorOnlyWhenTouched ? (touched && error != null) : error != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: value,
              onChanged: enabled ? onChanged : null,
              title: title,
              subtitle: subtitle,
              secondary: secondary,
              dense: dense,
              contentPadding: contentPadding,
            ),
            if (showError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A switch that integrates with form validation.
class ValidatedSwitch<S> extends StatelessWidget {
  const ValidatedSwitch({
    super.key,
    required this.stateController,
    required this.fieldName,
    required this.formSelector,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.enabled = true,
    this.dense = false,
    this.contentPadding,
    this.showErrorOnlyWhenTouched = true,
  });

  /// The controller whose state drives validation display.
  final DragonflyController<S> stateController;

  final String fieldName;
  final FormStateAccessor<S> formSelector;
  final ValueChanged<bool> onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool enabled;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;
  final bool showErrorOnlyWhenTouched;

  @override
  Widget build(BuildContext context) {
    return DragonflyStateBuilder<S>(
      controller: stateController,
      builder: (context, state) {
        final formState = formSelector(state);
        final fieldState = formState.fields[fieldName];

        final value = fieldState?.value as bool? ?? false;
        final error = fieldState?.error;
        final touched = fieldState?.touched ?? false;
        final showError = showErrorOnlyWhenTouched ? (touched && error != null) : error != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: value,
              onChanged: enabled ? onChanged : null,
              title: title,
              subtitle: subtitle,
              secondary: secondary,
              dense: dense,
              contentPadding: contentPadding,
            ),
            if (showError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A date picker that integrates with form validation.
class ValidatedDatePicker<S> extends StatelessWidget {
  const ValidatedDatePicker({
    super.key,
    required this.stateController,
    required this.fieldName,
    required this.formSelector,
    required this.onChanged,
    this.onBlur,
    this.decoration,
    this.firstDate,
    this.lastDate,
    this.dateFormat,
    this.enabled = true,
    this.showErrorOnlyWhenTouched = true,
  });

  /// The controller whose state drives validation display.
  final DragonflyController<S> stateController;

  final String fieldName;
  final FormStateAccessor<S> formSelector;
  final ValueChanged<DateTime?> onChanged;
  final VoidCallback? onBlur;
  final InputDecoration? decoration;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String Function(DateTime)? dateFormat;
  final bool enabled;
  final bool showErrorOnlyWhenTouched;

  String _formatDate(DateTime date) {
    if (dateFormat != null) return dateFormat!(date);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DragonflyStateBuilder<S>(
      controller: stateController,
      builder: (context, state) {
        final formState = formSelector(state);
        final fieldState = formState.fields[fieldName];

        final value = fieldState?.value as DateTime?;
        final error = fieldState?.error;
        final touched = fieldState?.touched ?? false;
        final showError = showErrorOnlyWhenTouched ? (touched && error != null) : error != null;

        return GestureDetector(
          onTap: enabled
              ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: value ?? DateTime.now(),
                    firstDate: firstDate ?? DateTime(1900),
                    lastDate: lastDate ?? DateTime(2100),
                  );
                  if (picked != null) {
                    onChanged(picked);
                  }
                  onBlur?.call();
                }
              : null,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: (decoration ?? const InputDecoration()).copyWith(
                errorText: showError ? error : null,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: value != null ? _formatDate(value) : '',
              ),
              enabled: enabled,
            ),
          ),
        );
      },
    );
  }
}

/// Type definition for form state accessor.
typedef FormStateAccessor<S> = dynamic Function(S state);

/// A form wrapper that provides form-level functionality.
class ValidatedForm extends StatelessWidget {
  const ValidatedForm({
    super.key,
    required this.child,
    this.onSubmit,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final Widget child;
  final VoidCallback? onSubmit;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: autovalidateMode,
      child: child,
    );
  }
}

/// A submit button that integrates with form validation.
class ValidatedSubmitButton<S> extends StatelessWidget {
  const ValidatedSubmitButton({
    super.key,
    required this.stateController,
    required this.formSelector,
    required this.onSubmit,
    this.child,
    this.disableWhenInvalid = true,
    this.disableWhenLoading = true,
    this.loadingSelector,
  });

  /// The controller whose state drives validation display.
  final DragonflyController<S> stateController;

  final FormStateAccessor<S> formSelector;
  final VoidCallback onSubmit;
  final Widget? child;
  final bool disableWhenInvalid;
  final bool disableWhenLoading;
  final bool Function(S state)? loadingSelector;

  @override
  Widget build(BuildContext context) {
    return DragonflyStateBuilder<S>(
      controller: stateController,
      builder: (context, state) {
        final formState = formSelector(state);
        final isValid = formState.isValid;
        final isLoading = loadingSelector?.call(state) ?? false;

        final disabled = (disableWhenInvalid && !isValid) || (disableWhenLoading && isLoading);

        return FilledButton(
          onPressed: disabled ? null : onSubmit,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : child ?? const Text('Submit'),
        );
      },
    );
  }
}
