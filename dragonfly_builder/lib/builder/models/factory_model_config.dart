/// Configuration for factory model generation.
///
/// This class holds the options from the @FactoryModel annotation
/// that control which methods are generated.
class FactoryModelConfig {
  /// Whether the model uses generic type parameters.
  final bool isGeneric;

  /// Whether the model represents a list type.
  final bool isList;

  /// Whether to generate a copyWith method.
  final bool copyWith;

  /// Whether to generate a toJson method.
  final bool toJson;

  /// Whether to generate a toMap method.
  final bool toMap;

  /// Whether to generate equality operators.
  final bool equals;

  /// Whether to generate a toString method.
  final bool toStringMethod;

  const FactoryModelConfig({
    this.isGeneric = false,
    this.isList = false,
    this.copyWith = false,
    this.toJson = true,
    this.toMap = true,
    this.equals = true,
    this.toStringMethod = true,
  });

  /// Creates a config from annotation values.
  factory FactoryModelConfig.fromAnnotation({
    bool? generic,
    bool? isList,
    bool? copyWith,
    bool? toJson,
    bool? toMap,
    bool? equals,
    bool? toStringMethod,
  }) {
    return FactoryModelConfig(
      isGeneric: generic ?? false,
      isList: isList ?? false,
      copyWith: copyWith ?? false,
      toJson: toJson ?? true,
      toMap: toMap ?? true,
      equals: equals ?? true,
      toStringMethod: toStringMethod ?? true,
    );
  }
}

/// Configuration for event model generation.
class EventModelConfig {
  /// Whether to generate a copyWith method.
  final bool copyWith;

  /// Whether to generate equality operators.
  final bool equals;

  /// Whether to generate a toString method.
  final bool toStringMethod;

  /// Whether to generate when/maybeWhen methods.
  final bool whenMethods;

  /// Whether to generate map/maybeMap methods.
  final bool mapMethods;

  const EventModelConfig({
    this.copyWith = true,
    this.equals = true,
    this.toStringMethod = true,
    this.whenMethods = true,
    this.mapMethods = true,
  });

  factory EventModelConfig.fromAnnotation({
    bool? copyWith,
    bool? equals,
    bool? toStringMethod,
    bool? whenMethods,
    bool? mapMethods,
  }) {
    return EventModelConfig(
      copyWith: copyWith ?? true,
      equals: equals ?? true,
      toStringMethod: toStringMethod ?? true,
      whenMethods: whenMethods ?? true,
      mapMethods: mapMethods ?? true,
    );
  }
}

/// Configuration for state model generation.
class StateModelConfig {
  /// Whether to generate a copyWith method.
  final bool copyWith;

  /// Whether to generate a toJson method.
  final bool toJson;

  /// Whether to generate a toMap method.
  final bool toMap;

  /// Whether to generate equality operators.
  final bool equals;

  /// Whether to generate a toString method.
  final bool toStringMethod;

  /// Whether to generate when/maybeWhen methods.
  final bool whenMethods;

  /// Whether to generate map/maybeMap methods.
  final bool mapMethods;

  const StateModelConfig({
    this.copyWith = true,
    this.toJson = false,
    this.toMap = false,
    this.equals = true,
    this.toStringMethod = true,
    this.whenMethods = true,
    this.mapMethods = true,
  });

  factory StateModelConfig.fromAnnotation({
    bool? copyWith,
    bool? toJson,
    bool? toMap,
    bool? equals,
    bool? toStringMethod,
    bool? whenMethods,
    bool? mapMethods,
  }) {
    return StateModelConfig(
      copyWith: copyWith ?? true,
      toJson: toJson ?? false,
      toMap: toMap ?? false,
      equals: equals ?? true,
      toStringMethod: toStringMethod ?? true,
      whenMethods: whenMethods ?? true,
      mapMethods: mapMethods ?? true,
    );
  }
}
