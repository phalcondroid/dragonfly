import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/code_builder/sealed_model/sealed_model_builder.dart';
import 'package:dragonfly_builder/builder/models/factory_model_config.dart';
import 'package:dragonfly_builder/builder/visitor/sealed_class_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for @EventModel annotated classes.
///
/// This generator creates sealed event classes for BLoC-style state management.
/// Each factory constructor in the annotated class becomes a sealed subclass.
///
/// Example input:
/// ```dart
/// @EventModel()
/// sealed class UserEvent with _$UserEvent {
///   const factory UserEvent.loading() = UserEventLoading;
///   const factory UserEvent.getUser(User user) = UserEventGetUser;
///   const factory UserEvent.deleteUser(User user, Purchases purchases) = UserEventDeleteUser;
/// }
/// ```
///
/// Example output:
/// ```dart
/// mixin _$UserEvent {
///   T when<T>({
///     required T Function() loading,
///     required T Function(User user) getUser,
///     required T Function(User user, Purchases purchases) deleteUser,
///   }) { ... }
///
///   T maybeWhen<T>({
///     T Function()? loading,
///     T Function(User user)? getUser,
///     T Function(User user, Purchases purchases)? deleteUser,
///     required T Function() orElse,
///   }) { ... }
///
///   T map<T>({
///     required T Function(UserEventLoading value) loading,
///     required T Function(UserEventGetUser value) getUser,
///     required T Function(UserEventDeleteUser value) deleteUser,
///   }) { ... }
///
///   T maybeMap<T>({
///     T Function(UserEventLoading value)? loading,
///     T Function(UserEventGetUser value)? getUser,
///     T Function(UserEventDeleteUser value)? deleteUser,
///     required T Function() orElse,
///   }) { ... }
/// }
///
/// class UserEventLoading extends UserEvent {
///   const UserEventLoading() : super._();
///
///   @override
///   bool operator ==(Object other) => identical(this, other) || other is UserEventLoading;
///
///   @override
///   int get hashCode => runtimeType.hashCode;
///
///   @override
///   String toString() => 'UserEventLoading()';
/// }
///
/// class UserEventGetUser extends UserEvent {
///   const UserEventGetUser({required this.user}) : super._();
///
///   final User user;
///
///   @override
///   bool operator ==(Object other) =>
///       identical(this, other) ||
///       other is UserEventGetUser && other.user == user;
///
///   @override
///   int get hashCode => user.hashCode;
///
///   @override
///   String toString() => 'UserEventGetUser(user: $user)';
///
///   UserEventGetUser copyWith({User? user}) =>
///       UserEventGetUser(user: user ?? this.user);
/// }
/// ```
class EventModelGenerator extends GeneratorForAnnotation<EventModel> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = SealedClassVisitor();
    element.visitChildren(visitor);

    // Read configuration from annotation
    final config = EventModelConfig.fromAnnotation(
      copyWith: annotation.peek('copyWith')?.boolValue,
      equals: annotation.peek('equals')?.boolValue,
      toStringMethod: annotation.peek('toStringMethod')?.boolValue,
      whenMethods: annotation.peek('whenMethods')?.boolValue,
      mapMethods: annotation.peek('mapMethods')?.boolValue,
    );

    try {
      final builder = SealedModelBuilder();
      final code = builder.generateSealedModel(visitor, config, 'event');

      visitor.reset();
      return code;
    } catch (e, stackTrace) {
      log.severe('EventModelGenerator error: $e\n$stackTrace');
      visitor.reset();
      return '// Error generating event model: $e';
    }
  }
}
