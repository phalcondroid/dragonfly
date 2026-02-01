// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_event.dart';

// **************************************************************************
// EventModelGenerator
// **************************************************************************

mixin _$UserEvent {
  T when<T>({
    required T Function() loading,
    required T Function(int userId) fetchUser,
    required T Function(Character user) deleteUser,
    required T Function(Character user, String newName) updateUser,
  }) {
    return switch (this) {
      UserEventLoading e => loading(),
      UserEventFetchUser e => fetchUser(e.userId),
      UserEventDeleteUser e => deleteUser(e.user),
      UserEventUpdateUser e => updateUser(e.user, e.newName),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeWhen<T>({
    T Function()? loading,
    T Function(int userId)? fetchUser,
    T Function(Character user)? deleteUser,
    T Function(Character user, String newName)? updateUser,
    required T Function() orElse,
  }) {
    return switch (this) {
      UserEventLoading e => loading?.call() ?? orElse(),
      UserEventFetchUser e => fetchUser?.call(e.userId) ?? orElse(),
      UserEventDeleteUser e => deleteUser?.call(e.user) ?? orElse(),
      UserEventUpdateUser e => updateUser?.call(e.user, e.newName) ?? orElse(),
      _ => orElse(),
    };
  }

  T map<T>({
    required T Function(UserEventLoading value) loading,
    required T Function(UserEventFetchUser value) fetchUser,
    required T Function(UserEventDeleteUser value) deleteUser,
    required T Function(UserEventUpdateUser value) updateUser,
  }) {
    return switch (this) {
      UserEventLoading e => loading(e),
      UserEventFetchUser e => fetchUser(e),
      UserEventDeleteUser e => deleteUser(e),
      UserEventUpdateUser e => updateUser(e),
      _ => throw StateError('Unknown variant: $runtimeType'),
    };
  }

  T maybeMap<T>({
    T Function(UserEventLoading value)? loading,
    T Function(UserEventFetchUser value)? fetchUser,
    T Function(UserEventDeleteUser value)? deleteUser,
    T Function(UserEventUpdateUser value)? updateUser,
    required T Function() orElse,
  }) {
    return switch (this) {
      UserEventLoading e => loading?.call(e) ?? orElse(),
      UserEventFetchUser e => fetchUser?.call(e) ?? orElse(),
      UserEventDeleteUser e => deleteUser?.call(e) ?? orElse(),
      UserEventUpdateUser e => updateUser?.call(e) ?? orElse(),
      _ => orElse(),
    };
  }
}

class UserEventLoading extends UserEvent {
  const UserEventLoading() : super._();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEventLoading;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode;
  }

  @override
  String toString() {
    return 'UserEventLoading()';
  }
}

class UserEventFetchUser extends UserEvent {
  const UserEventFetchUser({required this.userId}) : super._();

  final int userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEventFetchUser && other.userId == userId;
  }

  @override
  int get hashCode {
    return userId.hashCode;
  }

  @override
  String toString() {
    return 'UserEventFetchUser(userId: $userId)';
  }

  UserEventFetchUser copyWith({int? userId}) {
    return UserEventFetchUser(userId: userId ?? this.userId);
  }
}

class UserEventDeleteUser extends UserEvent {
  const UserEventDeleteUser({required this.user}) : super._();

  final Character user;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEventDeleteUser && other.user == user;
  }

  @override
  int get hashCode {
    return user.hashCode;
  }

  @override
  String toString() {
    return 'UserEventDeleteUser(user: $user)';
  }

  UserEventDeleteUser copyWith({Character? user}) {
    return UserEventDeleteUser(user: user ?? this.user);
  }
}

class UserEventUpdateUser extends UserEvent {
  const UserEventUpdateUser({
    required this.user,
    required this.newName,
  }) : super._();

  final Character user;

  final String newName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEventUpdateUser &&
        other.user == user &&
        other.newName == newName;
  }

  @override
  int get hashCode {
    return user.hashCode ^ newName.hashCode;
  }

  @override
  String toString() {
    return 'UserEventUpdateUser(user: $user, newName: $newName)';
  }

  UserEventUpdateUser copyWith({
    Character? user,
    String? newName,
  }) {
    return UserEventUpdateUser(
        user: user ?? this.user, newName: newName ?? this.newName);
  }
}
