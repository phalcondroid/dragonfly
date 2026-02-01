// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_state.dart';

// **************************************************************************
// StateModelGenerator
// **************************************************************************

mixin _$UserState {
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(Character user) loaded,
    required T Function(List<Character> users) userList,
    required T Function(String message) error,
  }) {
    return switch (this) {
      UserStateInitial e => initial(),
      UserStateLoading e => loading(),
      UserStateLoaded e => loaded(e.user),
      UserStateUserList e => userList(e.users),
      UserStateError e => error(e.message),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(Character user)? loaded,
    T Function(List<Character> users)? userList,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      UserStateInitial e => initial?.call() ?? orElse(),
      UserStateLoading e => loading?.call() ?? orElse(),
      UserStateLoaded e => loaded?.call(e.user) ?? orElse(),
      UserStateUserList e => userList?.call(e.users) ?? orElse(),
      UserStateError e => error?.call(e.message) ?? orElse(),
      _ => orElse(),
    };
  }

  T map<T>({
    required T Function(UserStateInitial value) initial,
    required T Function(UserStateLoading value) loading,
    required T Function(UserStateLoaded value) loaded,
    required T Function(UserStateUserList value) userList,
    required T Function(UserStateError value) error,
  }) {
    return switch (this) {
      UserStateInitial e => initial(e),
      UserStateLoading e => loading(e),
      UserStateLoaded e => loaded(e),
      UserStateUserList e => userList(e),
      UserStateError e => error(e),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeMap<T>({
    T Function(UserStateInitial value)? initial,
    T Function(UserStateLoading value)? loading,
    T Function(UserStateLoaded value)? loaded,
    T Function(UserStateUserList value)? userList,
    T Function(UserStateError value)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      UserStateInitial e => initial?.call(e) ?? orElse(),
      UserStateLoading e => loading?.call(e) ?? orElse(),
      UserStateLoaded e => loaded?.call(e) ?? orElse(),
      UserStateUserList e => userList?.call(e) ?? orElse(),
      UserStateError e => error?.call(e) ?? orElse(),
      _ => orElse(),
    };
  }
}

class UserStateInitial extends UserState {
  const UserStateInitial() : super._();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStateInitial;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode;
  }

  @override
  String toString() {
    return 'UserStateInitial()';
  }
}

class UserStateLoading extends UserState {
  const UserStateLoading() : super._();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStateLoading;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode;
  }

  @override
  String toString() {
    return 'UserStateLoading()';
  }
}

class UserStateLoaded extends UserState {
  const UserStateLoaded({required this.user}) : super._();

  final Character user;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStateLoaded && other.user == user;
  }

  @override
  int get hashCode {
    return user.hashCode;
  }

  @override
  String toString() {
    return 'UserStateLoaded(user: $user)';
  }

  UserStateLoaded copyWith({Character? user}) {
    return UserStateLoaded(user: user ?? this.user);
  }
}

class UserStateUserList extends UserState {
  const UserStateUserList({required this.users}) : super._();

  final List<Character> users;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStateUserList && _listEquals(other.users, users);
  }

  @override
  int get hashCode {
    return users.hashCode;
  }

  static bool _listEquals<T>(
    List<T>? a,
    List<T>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(
    Map<K, V>? a,
    Map<K, V>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static bool _setEquals<T>(
    Set<T>? a,
    Set<T>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  String toString() {
    return 'UserStateUserList(users: $users)';
  }

  UserStateUserList copyWith({List<Character>? users}) {
    return UserStateUserList(users: users ?? this.users);
  }
}

class UserStateError extends UserState {
  const UserStateError({required this.message}) : super._();

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStateError && other.message == message;
  }

  @override
  int get hashCode {
    return message.hashCode;
  }

  @override
  String toString() {
    return 'UserStateError(message: $message)';
  }

  UserStateError copyWith({String? message}) {
    return UserStateError(message: message ?? this.message);
  }
}
