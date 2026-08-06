// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'login_state.dart';

// **************************************************************************
// StateModelGenerator
// **************************************************************************

mixin _$LoginState {
  T when<T>({
    required T Function(LoginFormState form) initial,
    required T Function(LoginFormState form) editing,
    required T Function(LoginFormState form) loading,
    required T Function(LoginFormState form) success,
    required T Function(LoginFormState form, String message) error,
  }) {
    return switch (this) {
      LoginStateInitial e => initial(e.form),
      LoginStateEditing e => editing(e.form),
      LoginStateLoading e => loading(e.form),
      LoginStateSuccess e => success(e.form),
      LoginStateError e => error(e.form, e.message),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeWhen<T>({
    T Function(LoginFormState form)? initial,
    T Function(LoginFormState form)? editing,
    T Function(LoginFormState form)? loading,
    T Function(LoginFormState form)? success,
    T Function(LoginFormState form, String message)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      LoginStateInitial e => initial?.call(e.form) ?? orElse(),
      LoginStateEditing e => editing?.call(e.form) ?? orElse(),
      LoginStateLoading e => loading?.call(e.form) ?? orElse(),
      LoginStateSuccess e => success?.call(e.form) ?? orElse(),
      LoginStateError e => error?.call(e.form, e.message) ?? orElse(),
      _ => orElse(),
    };
  }

  T map<T>({
    required T Function(LoginStateInitial value) initial,
    required T Function(LoginStateEditing value) editing,
    required T Function(LoginStateLoading value) loading,
    required T Function(LoginStateSuccess value) success,
    required T Function(LoginStateError value) error,
  }) {
    return switch (this) {
      LoginStateInitial e => initial(e),
      LoginStateEditing e => editing(e),
      LoginStateLoading e => loading(e),
      LoginStateSuccess e => success(e),
      LoginStateError e => error(e),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeMap<T>({
    T Function(LoginStateInitial value)? initial,
    T Function(LoginStateEditing value)? editing,
    T Function(LoginStateLoading value)? loading,
    T Function(LoginStateSuccess value)? success,
    T Function(LoginStateError value)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      LoginStateInitial e => initial?.call(e) ?? orElse(),
      LoginStateEditing e => editing?.call(e) ?? orElse(),
      LoginStateLoading e => loading?.call(e) ?? orElse(),
      LoginStateSuccess e => success?.call(e) ?? orElse(),
      LoginStateError e => error?.call(e) ?? orElse(),
      _ => orElse(),
    };
  }
}

class LoginStateInitial extends LoginState {
  const LoginStateInitial({required this.form}) : super._();

  final LoginFormState form;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginStateInitial && other.form == form;
  }

  @override
  int get hashCode {
    return form.hashCode;
  }

  @override
  String toString() {
    return 'LoginStateInitial(form: $form)';
  }

  @override
  LoginStateInitial copyWith({LoginFormState? form}) {
    return LoginStateInitial(form: form ?? this.form);
  }
}

class LoginStateEditing extends LoginState {
  const LoginStateEditing({required this.form}) : super._();

  final LoginFormState form;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginStateEditing && other.form == form;
  }

  @override
  int get hashCode {
    return form.hashCode;
  }

  @override
  String toString() {
    return 'LoginStateEditing(form: $form)';
  }

  @override
  LoginStateEditing copyWith({LoginFormState? form}) {
    return LoginStateEditing(form: form ?? this.form);
  }
}

class LoginStateLoading extends LoginState {
  const LoginStateLoading({required this.form}) : super._();

  final LoginFormState form;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginStateLoading && other.form == form;
  }

  @override
  int get hashCode {
    return form.hashCode;
  }

  @override
  String toString() {
    return 'LoginStateLoading(form: $form)';
  }

  @override
  LoginStateLoading copyWith({LoginFormState? form}) {
    return LoginStateLoading(form: form ?? this.form);
  }
}

class LoginStateSuccess extends LoginState {
  const LoginStateSuccess({required this.form}) : super._();

  final LoginFormState form;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginStateSuccess && other.form == form;
  }

  @override
  int get hashCode {
    return form.hashCode;
  }

  @override
  String toString() {
    return 'LoginStateSuccess(form: $form)';
  }

  @override
  LoginStateSuccess copyWith({LoginFormState? form}) {
    return LoginStateSuccess(form: form ?? this.form);
  }
}

class LoginStateError extends LoginState {
  const LoginStateError({required this.form, required this.message})
    : super._();

  final LoginFormState form;

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginStateError &&
        other.form == form &&
        other.message == message;
  }

  @override
  int get hashCode {
    return form.hashCode ^ message.hashCode;
  }

  @override
  String toString() {
    return 'LoginStateError(form: $form, message: $message)';
  }

  @override
  LoginStateError copyWith({LoginFormState? form, String? message}) {
    return LoginStateError(
      form: form ?? this.form,
      message: message ?? this.message,
    );
  }
}
