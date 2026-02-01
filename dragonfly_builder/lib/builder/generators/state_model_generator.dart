import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/code_builder/sealed_model/sealed_model_builder.dart';
import 'package:dragonfly_builder/builder/models/factory_model_config.dart';
import 'package:dragonfly_builder/builder/visitor/sealed_class_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for @StateModel annotated classes.
///
/// This generator creates sealed state classes for BLoC-style state management.
/// Each factory constructor in the annotated class becomes a sealed subclass.
///
/// Example input:
/// ```dart
/// @StateModel()
/// sealed class UserState with _$UserState {
///   const factory UserState.initial() = UserStateInitial;
///   const factory UserState.loading() = UserStateLoading;
///   const factory UserState.loaded(User user) = UserStateLoaded;
///   const factory UserState.error(String message) = UserStateError;
/// }
/// ```
///
/// Example output:
/// ```dart
/// mixin _$UserState {
///   T when<T>({
///     required T Function() initial,
///     required T Function() loading,
///     required T Function(User user) loaded,
///     required T Function(String message) error,
///   }) { ... }
///
///   T maybeWhen<T>({
///     T Function()? initial,
///     T Function()? loading,
///     T Function(User user)? loaded,
///     T Function(String message)? error,
///     required T Function() orElse,
///   }) { ... }
///
///   T map<T>({
///     required T Function(UserStateInitial value) initial,
///     required T Function(UserStateLoading value) loading,
///     required T Function(UserStateLoaded value) loaded,
///     required T Function(UserStateError value) error,
///   }) { ... }
///
///   T maybeMap<T>({
///     T Function(UserStateInitial value)? initial,
///     T Function(UserStateLoading value)? loading,
///     T Function(UserStateLoaded value)? loaded,
///     T Function(UserStateError value)? error,
///     required T Function() orElse,
///   }) { ... }
/// }
///
/// class UserStateInitial extends UserState {
///   const UserStateInitial() : super._();
///   ...
/// }
///
/// class UserStateLoading extends UserState {
///   const UserStateLoading() : super._();
///   ...
/// }
///
/// class UserStateLoaded extends UserState {
///   const UserStateLoaded({required this.user}) : super._();
///
///   final User user;
///
///   UserStateLoaded copyWith({User? user}) =>
///       UserStateLoaded(user: user ?? this.user);
///   ...
/// }
///
/// class UserStateError extends UserState {
///   const UserStateError({required this.message}) : super._();
///
///   final String message;
///
///   UserStateError copyWith({String? message}) =>
///       UserStateError(message: message ?? this.message);
///   ...
/// }
/// ```
class StateModelGenerator extends GeneratorForAnnotation<StateModel> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = SealedClassVisitor();
    element.visitChildren(visitor);

    // Read configuration from annotation
    final config = StateModelConfig.fromAnnotation(
      copyWith: annotation.peek('copyWith')?.boolValue,
      toJson: annotation.peek('toJson')?.boolValue,
      toMap: annotation.peek('toMap')?.boolValue,
      equals: annotation.peek('equals')?.boolValue,
      toStringMethod: annotation.peek('toStringMethod')?.boolValue,
      whenMethods: annotation.peek('whenMethods')?.boolValue,
      mapMethods: annotation.peek('mapMethods')?.boolValue,
    );

    try {
      final builder = SealedModelBuilder();
      final code = builder.generateSealedModel(visitor, config, 'state');

      visitor.reset();
      return code;
    } catch (e, stackTrace) {
      log.severe('StateModelGenerator error: $e\n$stackTrace');
      visitor.reset();
      return '// Error generating state model: $e';
    }
  }
}
