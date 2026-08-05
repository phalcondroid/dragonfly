// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'login_state.dart';

// **************************************************************************
// StateModelGenerator
// **************************************************************************

mixin _$LoginState {
  T when<T>({
    required T Function() initial,
    required T Function(InvalidType form) loading,
    required T Function(InvalidType form) success,
    required T Function(InvalidType form, String message) error,
  }) {
    return switch (this) {
      LoginStateInitial e => initial(),
      LoginStateLoading e => loading(e.form),
      LoginStateSuccess e => success(e.form),
      LoginStateError e => error(e.form, e.message),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function(InvalidType form)? loading,
    T Function(InvalidType form)? success,
    T Function(InvalidType form, String message)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      LoginStateInitial e => initial?.call() ?? orElse(),
      LoginStateLoading e => loading?.call(e.form) ?? orElse(),
      LoginStateSuccess e => success?.call(e.form) ?? orElse(),
      LoginStateError e => error?.call(e.form, e.message) ?? orElse(),
      _ => orElse(),
    };
  }

  T map<T>({
    required T Function(LoginStateInitial value) initial,
    required T Function(LoginStateLoading value) loading,
    required T Function(LoginStateSuccess value) success,
    required T Function(LoginStateError value) error,
  }) {
    return switch (this) {
      LoginStateInitial e => initial(e),
      LoginStateLoading e => loading(e),
      LoginStateSuccess e => success(e),
      LoginStateError e => error(e),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeMap<T>({
    T Function(LoginStateInitial value)? initial,
    T Function(LoginStateLoading value)? loading,
    T Function(LoginStateSuccess value)? success,
    T Function(LoginStateError value)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      LoginStateInitial e => initial?.call(e) ?? orElse(),
      LoginStateLoading e => loading?.call(e) ?? orElse(),
      LoginStateSuccess e => success?.call(e) ?? orElse(),
      LoginStateError e => error?.call(e) ?? orElse(),
      _ => orElse(),
    };
  }
}

class LoginStateInitial extends LoginState {
  const LoginStateInitial() : super._();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginStateInitial;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode;
  }

  @override
  String toString() {
    return 'LoginStateInitial()';
  }
}

class LoginStateLoading extends LoginState {
  const LoginStateLoading({required this.form}) : super._();

  final InvalidType form;

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

  LoginStateLoading copyWith({InvalidType? form}) {
    return LoginStateLoading(form: form ?? this.form);
  }
}

class LoginStateSuccess extends LoginState {
  const LoginStateSuccess({required this.form}) : super._();

  final InvalidType form;

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

  LoginStateSuccess copyWith({InvalidType? form}) {
    return LoginStateSuccess(form: form ?? this.form);
  }
}

class LoginStateError extends LoginState {
  const LoginStateError({required this.form, required this.message})
    : super._();

  final InvalidType form;

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

  LoginStateError copyWith({InvalidType? form, String? message}) {
    return LoginStateError(
      form: form ?? this.form,
      message: message ?? this.message,
    );
  }
}
