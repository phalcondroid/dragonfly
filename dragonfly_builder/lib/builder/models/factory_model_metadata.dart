/// How a generic type parameter is used in a field
enum GenericUsage {
  /// Not using generic type (e.g., `String name`)
  none,

  /// Direct usage of generic type (e.g., `T data`)
  direct,

  /// Generic type wrapped in a List (e.g., `List<T> items`)
  list,

  /// Generic type wrapped in a Map value (e.g., `Map<String, T> data`)
  mapValue,

  /// Generic type wrapped in a Map key (e.g., `Map<T, String> data`)
  mapKey,

  /// Generic type wrapped in a Set (e.g., `Set<T> items`)
  set,
}

/// Metadata for a generic type parameter (e.g., T, E, K, V)
class GenericTypeParamMetadata {
  /// The name of the generic parameter (e.g., "T", "E")
  final String name;

  /// The bound of the generic if any (e.g., "Object" for `T extends Object`)
  final String? bound;

  /// Position/index of this generic parameter (0-based)
  final int index;

  const GenericTypeParamMetadata({
    required this.name,
    this.bound,
    required this.index,
  });
}

/// Metadata for a fromJson factory parameter
class FromJsonParamMetadata {
  final String name;
  final String type;
  final bool isRequired;
  final bool isPositional;

  /// True if this is the JSON map parameter
  final bool isJsonParam;

  /// True if this is a converter function for a generic type (e.g., `T Function(Object?) fromJsonT`)
  final bool isGenericConverter;

  /// The generic type this converter handles (e.g., "T")
  final String? converterForGeneric;

  const FromJsonParamMetadata({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isPositional,
    this.isJsonParam = false,
    this.isGenericConverter = false,
    this.converterForGeneric,
  });
}

/// Metadata structure for FactoryModel that can be shared across generators
class FactoryModelMetadata {
  final String modelName;
  final String importPath;
  final bool isGeneric;
  final bool isList;
  final List<FactoryModelFieldMetadata> fields;
  final bool hasFromJson;

  /// All generic type parameters for this model (e.g., [T], [K, V])
  final List<GenericTypeParamMetadata> genericTypeParams;

  /// Number of generic type parameters
  int get genericCount => genericTypeParams.length;

  /// True if model has multiple generic type parameters
  bool get hasMultipleGenerics => genericTypeParams.length > 1;

  /// First generic type parameter name (for convenience)
  String? get firstGenericParam =>
      genericTypeParams.isNotEmpty ? genericTypeParams.first.name : null;

  /// Parameters of the fromJson factory constructor
  final List<FromJsonParamMetadata> fromJsonParams;

  /// True if fromJson requires converter function(s) for generic type(s)
  final bool fromJsonRequiresConverter;

  /// Get fields that use any generic type parameter
  List<FactoryModelFieldMetadata> get genericFields =>
      fields.where((f) => f.usesGenericType).toList();

  /// Check if any field uses generic as a list
  bool get hasGenericListField =>
      fields.any((f) => f.genericUsage == GenericUsage.list);

  /// Check if any field uses generic directly
  bool get hasDirectGenericField =>
      fields.any((f) => f.genericUsage == GenericUsage.direct);

  const FactoryModelMetadata({
    required this.modelName,
    required this.importPath,
    required this.isGeneric,
    required this.isList,
    required this.fields,
    required this.hasFromJson,
    this.genericTypeParams = const [],
    this.fromJsonParams = const [],
    this.fromJsonRequiresConverter = false,
  });
}

class FactoryModelFieldMetadata {
  final String name;
  final String type;
  final bool isClass;
  final bool isList;
  final bool isMap;
  final bool isSet;
  final bool isNullable;
  final String? listInnerType;

  /// True if this field uses a generic type parameter (T, List<T>, etc.)
  final bool usesGenericType;

  /// How the generic type is used in this field
  final GenericUsage genericUsage;

  /// Which generic parameter this field uses (e.g., "T", "K", "V")
  final String? genericParamName;

  /// The inner type when using collections (e.g., for List<T> this is "T", for Map<String, T> the value type)
  final String? innerType;

  /// True if the inner type is a class/model (not primitive)
  final bool innerTypeIsClass;

  const FactoryModelFieldMetadata({
    required this.name,
    required this.type,
    required this.isClass,
    required this.isList,
    this.isMap = false,
    this.isSet = false,
    this.isNullable = false,
    this.listInnerType,
    this.usesGenericType = false,
    this.genericUsage = GenericUsage.none,
    this.genericParamName,
    this.innerType,
    this.innerTypeIsClass = false,
  });
}
