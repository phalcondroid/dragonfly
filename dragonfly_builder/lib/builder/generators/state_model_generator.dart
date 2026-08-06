import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly_builder/builder/code_builder/sealed_model/sealed_model_builder.dart';
import 'package:dragonfly_builder/builder/helper/syntactic_param_reader.dart';
import 'package:dragonfly_builder/builder/models/factory_model_config.dart';
import 'package:dragonfly_builder/builder/models/factory_model_field.dart';
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
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final visitor = SealedClassVisitor();
    element.visitChildren(visitor);

    // Types declared in other generated files resolve to InvalidType at build
    // time; substitute the source-text names so variants may reference e.g.
    // generated form states.
    if (element is ClassElement) {
      await _patchInvalidTypes(element, visitor, buildStep);
    }

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

  Future<void> _patchInvalidTypes(ClassElement element,
      SealedClassVisitor visitor, BuildStep buildStep) async {
    final needsPatch = visitor.variants
        .any((v) => v.parameters.any((p) => p.type == 'InvalidType'));
    if (!needsPatch) return;

    final syntactic = await SyntacticParamReader.readFactoryParams(
      buildStep,
      element.library.uri,
      element.name ?? '',
    );
    if (syntactic.isEmpty) return;

    for (var i = 0; i < visitor.variants.length; i++) {
      final variant = visitor.variants[i];
      final syntacticParams = syntactic[variant.name];
      if (syntacticParams == null) continue;

      visitor.variants[i] = SealedVariant(
        name: variant.name,
        className: variant.className,
        isDefault: variant.isDefault,
        parameters: [
          for (var j = 0; j < variant.parameters.length; j++)
            _patchedField(variant.parameters[j],
                j < syntacticParams.length ? syntacticParams[j] : null),
        ],
      );
    }
  }

  FactoryModelField _patchedField(FactoryModelField field, SyntacticParam? syn) {
    if (syn == null || field.type != 'InvalidType') return field;

    final type = syn.type;
    final isList = type.startsWith('List<');
    final listType = isList
        ? type.substring(5, type.length - 1).replaceAll('?', '')
        : '';
    final bare = type.replaceAll('?', '');
    const primitives = {'bool', 'double', 'int', 'num', 'String', 'dynamic', 'Object'};

    return FactoryModelField(
      name: field.name,
      fieldName: field.fieldName,
      isFieldName: field.isFieldName,
      value: field.value,
      type: type,
      isDartList: isList,
      isDartMap: type.startsWith('Map<'),
      isDartSet: type.startsWith('Set<'),
      isFinal: field.isFinal,
      isNullable: type.endsWith('?'),
      isClass: !primitives.contains(bare) &&
          !isList &&
          !type.startsWith('Map<') &&
          !type.startsWith('Set<'),
      isRequired: field.isRequired,
      rawType: field.rawType,
      listType: listType,
      listTypeIsClass:
          listType.isNotEmpty && !primitives.contains(listType),
    );
  }
}
