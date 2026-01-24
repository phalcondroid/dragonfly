class ReturnHelper {
  String getTypeFromReturn(String name) {
    var sanitized = name.replaceAll('*', '').replaceAll('?', '').trim();
    sanitized = _unwrapGeneric(sanitized, 'Future');
    sanitized = _unwrapGeneric(sanitized, 'List');
    return sanitized;
  }

  String getMainClassName(String name) {
    var sanitized = name.replaceAll('*', '').replaceAll('?', '').trim();
    // Unwrap Future first
    sanitized = _unwrapGeneric(sanitized, 'Future');
    // Get the base class name (before any generic brackets)
    return _getBaseClassName(sanitized);
  }

  String _getBaseClassName(String type) {
    final bracketIndex = type.indexOf('<');
    if (bracketIndex == -1) {
      return type;
    }
    return type.substring(0, bracketIndex);
  }

  bool isReturnList(String name) {
    return name.contains('List<');
  }

  List<String> extractGenerics(String name) {
    var sanitized = name.replaceAll('*', '').replaceAll('?', '').trim();
    // Unwrap Future first
    sanitized = _unwrapGeneric(sanitized, 'Future');

    // If no generics, return empty list
    final bracketIndex = sanitized.indexOf('<');
    if (bracketIndex == -1) {
      return [];
    }

    // Extract the content between < and >
    final genericsContent =
        sanitized.substring(bracketIndex + 1, sanitized.length - 1);

    // Parse comma-separated type arguments, handling nested generics
    return _parseTypeArguments(genericsContent);
  }

  List<String> _parseTypeArguments(String content) {
    final args = <String>[];
    var depth = 0;
    var current = StringBuffer();

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '<') {
        depth++;
        current.write(char);
      } else if (char == '>') {
        depth--;
        current.write(char);
      } else if (char == ',' && depth == 0) {
        final arg = current.toString().trim();
        if (arg.isNotEmpty) {
          args.add(arg);
        }
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }

    // Add the last argument
    final lastArg = current.toString().trim();
    if (lastArg.isNotEmpty) {
      args.add(lastArg);
    }

    return args;
  }

  String _unwrapGeneric(String type, String wrapper) {
    final prefix = '$wrapper<';
    if (!type.startsWith(prefix)) {
      return type;
    }

    var depth = 0;
    for (var i = prefix.length; i < type.length; i++) {
      final char = type[i];
      if (char == '<') {
        depth++;
      } else if (char == '>') {
        if (depth == 0) {
          return type.substring(prefix.length, i);
        }
        depth--;
      }
    }
    return type;
  }
}
