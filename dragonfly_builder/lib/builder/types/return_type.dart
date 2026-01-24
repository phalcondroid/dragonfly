class ReturnType {
  /// The full model name with generics (e.g., "ServiceResponse<Character>")
  final String modelName;

  /// The main class name without generics (e.g., "ServiceResponse")
  final String name;

  /// The raw return type string (e.g., "Future<ServiceResponse<Character>>")
  final String raw;

  /// True if the return type is a List
  final bool isList;

  /// List of generic type arguments (e.g., ["Character"] for ServiceResponse<Character>)
  final List<String> generics;

  /// True if the return type has generic arguments
  bool get hasGenerics => generics.isNotEmpty;

  /// Get the first generic argument (most common case)
  String? get firstGeneric => generics.isNotEmpty ? generics.first : null;

  const ReturnType({
    required this.modelName,
    required this.raw,
    required this.name,
    this.isList = false,
    this.generics = const [],
  });
}
