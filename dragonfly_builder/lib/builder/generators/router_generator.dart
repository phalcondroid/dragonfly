import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for [DragonflyRouterConfig].
///
/// This generator scans for [DragonflyRoute] annotations
/// and creates a router configuration.
///
/// When a route specifies a `provider`, the screen is automatically
/// wrapped with the Feature's generated Provider widget.
class RouterGenerator extends GeneratorForAnnotation<DragonflyRouterConfig> {
  final _formatter = DartFormatter();
  static final _routeChecker = TypeChecker.fromRuntime(DragonflyRoute);
  static final _stateManagerChecker =
      TypeChecker.fromRuntime(DragonflyStateManager);

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    String? initialRoute;
    final Set<String> imports = {};
    final Map<String, _RouteInfo> routes = {};

    // Map of Feature class names to their source file imports
    // (The Provider is generated as a part of the feature file)
    final Map<String, String> featureImports = {};

    final glob = Glob('lib/**.dart');

    // First pass: collect all Feature classes and their source file imports
    await for (final assetId in buildStep.findAssets(glob)) {
      try {
        final library = await buildStep.resolver.libraryFor(assetId);
        final reader = LibraryReader(library);

        for (final annotatedElement
            in reader.annotatedWith(_stateManagerChecker)) {
          if (annotatedElement.element is ClassElement) {
            final classElement = annotatedElement.element as ClassElement;
            final featureName = classElement.name;

            // Import the feature file itself (which includes the generated part)
            final featureImport = assetId.uri.toString();
            featureImports[featureName] = featureImport;
          }
        }
      } catch (_) {
        continue;
      }
    }

    // Second pass: collect routes
    await for (final assetId in buildStep.findAssets(glob)) {
      try {
        final library = await buildStep.resolver.libraryFor(assetId);
        final reader = LibraryReader(library);

        for (final annotatedElement in reader.annotatedWith(_routeChecker)) {
          if (annotatedElement.element is ClassElement) {
            final classElement = annotatedElement.element as ClassElement;
            final annotationObj = annotatedElement.annotation;

            final pathValue = annotationObj.read('path').stringValue;
            final nameValue = annotationObj.peek('name')?.stringValue;
            final isInitial = annotationObj.read('initial').boolValue;
            final transitionValue =
                annotationObj.read('transition').objectValue;

            // Parse transition enum
            final transitionName =
                transitionValue.getField('_name')?.toStringValue() ?? 'fade';

            // Parse provider type
            String? providerName;
            String? providerImport;
            final providerReader = annotationObj.peek('provider');
            if (providerReader != null && !providerReader.isNull) {
              final providerType = providerReader.typeValue;
              final providerTypeName =
                  providerType.getDisplayString(withNullability: false);
              providerName = '${providerTypeName}Provider';

              // Get the import for the feature file (which contains the Provider as a part)
              providerImport = featureImports[providerTypeName];

              // If we couldn't find it in the map, try to derive it from the type's source
              if (providerImport == null) {
                final providerElement = providerType.element;
                if (providerElement != null) {
                  providerImport = providerElement.librarySource?.uri.toString();
                }
              }
            }

            final className = classElement.name;
            final importUri = assetId.uri.toString();

            // Add screen import
            imports.add("import '$importUri';");

            // Add feature import if provider is specified
            if (providerImport != null) {
              imports.add("import '$providerImport';");
            }

            routes[pathValue] = _RouteInfo(
              path: pathValue,
              className: className,
              name: nameValue,
              transition: transitionName,
              isInitial: isInitial,
              providerName: providerName,
            );

            if (isInitial) {
              initialRoute = pathValue;
            }
          }
        }
      } catch (_) {
        continue;
      }
    }

    final buffer = StringBuffer();

    // Write imports
    buffer.writeln("import 'package:flutter/material.dart';");
    for (final import in imports) {
      buffer.writeln(import);
    }
    buffer.writeln();

    // Generate mixin
    buffer.writeln('/// Generated router configuration.');
    buffer.writeln('mixin \$${element.name} {');

    // Routes map
    buffer.writeln('  /// Map of route paths to widget builders.');
    buffer.writeln('  Map<String, WidgetBuilder> get routes => {');
    for (final route in routes.values) {
      if (route.providerName != null) {
        // Wrap with provider
        buffer.writeln(
            "    '${route.path}': (context) => ${route.providerName}(child: const ${route.className}()),");
      } else {
        buffer.writeln(
            "    '${route.path}': (context) => const ${route.className}(),");
      }
    }
    buffer.writeln('  };');
    buffer.writeln();

    // Named routes map
    buffer.writeln('  /// Map of route names to paths.');
    buffer.writeln('  Map<String, String> get namedRoutes => {');
    for (final route in routes.values) {
      if (route.name != null) {
        buffer.writeln("    '${route.name}': '${route.path}',");
      }
    }
    buffer.writeln('  };');
    buffer.writeln();

    // Initial route
    if (initialRoute != null) {
      buffer.writeln("  /// The initial route for the application.");
      buffer.writeln("  String get initialRoute => '$initialRoute';");
    } else {
      buffer.writeln("  /// The initial route for the application.");
      buffer.writeln("  String get initialRoute => '/';");
    }
    buffer.writeln();

    // Route generator method
    buffer.writeln('  /// Generates a route for the given settings.');
    buffer.writeln(
        '  Route<dynamic>? onGenerateRoute(RouteSettings settings) {');
    buffer.writeln('    final routeName = settings.name;');
    buffer.writeln('    if (routeName == null) return null;');
    buffer.writeln();
    buffer.writeln('    // First, try exact match');
    buffer.writeln('    final builder = routes[routeName];');
    buffer.writeln('    if (builder != null) {');
    buffer.writeln(
        '      return _buildRoute(settings, builder, _getTransition(routeName));');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    // Try pattern matching for dynamic routes');
    buffer.writeln('    for (final entry in routes.entries) {');
    buffer.writeln("      if (entry.key.contains(':')) {");
    buffer.writeln('        final match = _matchRoute(entry.key, routeName);');
    buffer.writeln('        if (match != null) {');
    buffer.writeln('          return _buildRoute(');
    buffer.writeln(
        '            RouteSettings(name: routeName, arguments: match),');
    buffer.writeln('            entry.value,');
    buffer.writeln('            _getTransition(entry.key),');
    buffer.writeln('          );');
    buffer.writeln('        }');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    return null;');
    buffer.writeln('  }');
    buffer.writeln();

    // Transition mapping
    buffer.writeln('  /// Gets the transition type for a route.');
    buffer.writeln('  String _getTransition(String path) {');
    buffer.writeln('    switch (path) {');
    for (final route in routes.values) {
      buffer.writeln("      case '${route.path}': return '${route.transition}';");
    }
    buffer.writeln("      default: return 'fade';");
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    // Route builder helper
    buffer.writeln('  /// Builds a route with the specified transition.');
    buffer.writeln('  Route<dynamic> _buildRoute(');
    buffer.writeln('    RouteSettings settings,');
    buffer.writeln('    WidgetBuilder builder,');
    buffer.writeln('    String transition,');
    buffer.writeln('  ) {');
    buffer.writeln('    switch (transition) {');
    buffer.writeln("      case 'none':");
    buffer.writeln('        return PageRouteBuilder(');
    buffer.writeln('          settings: settings,');
    buffer.writeln('          pageBuilder: (context, _, __) => builder(context),');
    buffer.writeln('          transitionDuration: Duration.zero,');
    buffer.writeln('        );');
    buffer.writeln("      case 'slideRight':");
    buffer.writeln('        return PageRouteBuilder(');
    buffer.writeln('          settings: settings,');
    buffer.writeln('          pageBuilder: (context, _, __) => builder(context),');
    buffer.writeln('          transitionsBuilder: (context, animation, _, child) {');
    buffer.writeln('            return SlideTransition(');
    buffer.writeln('              position: Tween<Offset>(');
    buffer.writeln('                begin: const Offset(1.0, 0.0),');
    buffer.writeln('                end: Offset.zero,');
    buffer.writeln('              ).animate(CurvedAnimation(');
    buffer.writeln('                parent: animation,');
    buffer.writeln('                curve: Curves.easeInOut,');
    buffer.writeln('              )),');
    buffer.writeln('              child: child,');
    buffer.writeln('            );');
    buffer.writeln('          },');
    buffer.writeln('        );');
    buffer.writeln("      case 'slideUp':");
    buffer.writeln('        return PageRouteBuilder(');
    buffer.writeln('          settings: settings,');
    buffer.writeln('          pageBuilder: (context, _, __) => builder(context),');
    buffer.writeln('          transitionsBuilder: (context, animation, _, child) {');
    buffer.writeln('            return SlideTransition(');
    buffer.writeln('              position: Tween<Offset>(');
    buffer.writeln('                begin: const Offset(0.0, 1.0),');
    buffer.writeln('                end: Offset.zero,');
    buffer.writeln('              ).animate(CurvedAnimation(');
    buffer.writeln('                parent: animation,');
    buffer.writeln('                curve: Curves.easeInOut,');
    buffer.writeln('              )),');
    buffer.writeln('              child: child,');
    buffer.writeln('            );');
    buffer.writeln('          },');
    buffer.writeln('        );');
    buffer.writeln("      case 'scale':");
    buffer.writeln('        return PageRouteBuilder(');
    buffer.writeln('          settings: settings,');
    buffer.writeln('          pageBuilder: (context, _, __) => builder(context),');
    buffer.writeln('          transitionsBuilder: (context, animation, _, child) {');
    buffer.writeln('            return ScaleTransition(');
    buffer.writeln(
        '              scale: Tween<double>(begin: 0.0, end: 1.0).animate(');
    buffer.writeln(
        '                CurvedAnimation(parent: animation, curve: Curves.easeInOut),');
    buffer.writeln('              ),');
    buffer.writeln('              child: child,');
    buffer.writeln('            );');
    buffer.writeln('          },');
    buffer.writeln('        );');
    buffer.writeln("      case 'platform':");
    buffer.writeln('        return MaterialPageRoute(');
    buffer.writeln('          settings: settings,');
    buffer.writeln('          builder: builder,');
    buffer.writeln('        );');
    buffer.writeln("      case 'fade':");
    buffer.writeln('      default:');
    buffer.writeln('        return PageRouteBuilder(');
    buffer.writeln('          settings: settings,');
    buffer.writeln('          pageBuilder: (context, _, __) => builder(context),');
    buffer.writeln('          transitionsBuilder: (context, animation, _, child) {');
    buffer.writeln(
        '            return FadeTransition(opacity: animation, child: child);');
    buffer.writeln('          },');
    buffer.writeln('        );');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    // Route pattern matching helper
    buffer.writeln('  /// Matches a route pattern against a path.');
    buffer.writeln(
        '  /// Returns the extracted parameters if matched, null otherwise.');
    buffer.writeln(
        '  Map<String, String>? _matchRoute(String pattern, String path) {');
    buffer.writeln("    final patternSegments = pattern.split('/');");
    buffer.writeln("    final pathSegments = path.split('/');");
    buffer.writeln();
    buffer.writeln(
        '    if (patternSegments.length != pathSegments.length) return null;');
    buffer.writeln();
    buffer.writeln('    final params = <String, String>{};');
    buffer.writeln();
    buffer.writeln('    for (var i = 0; i < patternSegments.length; i++) {');
    buffer.writeln('      final patternSeg = patternSegments[i];');
    buffer.writeln('      final pathSeg = pathSegments[i];');
    buffer.writeln();
    buffer.writeln("      if (patternSeg.startsWith(':')) {");
    buffer.writeln('        // Dynamic segment');
    buffer.writeln('        final paramName = patternSeg.substring(1);');
    buffer.writeln('        params[paramName] = pathSeg;');
    buffer.writeln('      } else if (patternSeg != pathSeg) {');
    buffer.writeln('        // Static segment mismatch');
    buffer.writeln('        return null;');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    return params;');
    buffer.writeln('  }');
    buffer.writeln();

    // Navigation helpers
    buffer.writeln('  /// Navigates to a route by name.');
    buffer.writeln(
        '  void navigateTo(BuildContext context, String name, {Object? arguments}) {');
    buffer.writeln('    final path = namedRoutes[name];');
    buffer.writeln('    if (path != null) {');
    buffer.writeln(
        '      Navigator.of(context).pushNamed(path, arguments: arguments);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln(
        '  /// Navigates to a path directly.');
    buffer.writeln(
        '  void navigateToPath(BuildContext context, String path, {Object? arguments}) {');
    buffer.writeln(
        '    Navigator.of(context).pushNamed(path, arguments: arguments);');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Replaces the current route with a new one.');
    buffer.writeln(
        '  void replaceTo(BuildContext context, String name, {Object? arguments}) {');
    buffer.writeln('    final path = namedRoutes[name];');
    buffer.writeln('    if (path != null) {');
    buffer.writeln(
        '      Navigator.of(context).pushReplacementNamed(path, arguments: arguments);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Pops all routes and pushes a new one.');
    buffer.writeln(
        '  void resetTo(BuildContext context, String name, {Object? arguments}) {');
    buffer.writeln('    final path = namedRoutes[name];');
    buffer.writeln('    if (path != null) {');
    buffer.writeln(
        '      Navigator.of(context).pushNamedAndRemoveUntil(path, (_) => false, arguments: arguments);');
    buffer.writeln('    }');
    buffer.writeln('  }');

    buffer.writeln('}');

    try {
      return _formatter.format(buffer.toString());
    } catch (e) {
      return buffer.toString();
    }
  }
}

class _RouteInfo {
  final String path;
  final String className;
  final String? name;
  final String transition;
  final bool isInitial;
  final String? providerName;

  _RouteInfo({
    required this.path,
    required this.className,
    this.name,
    required this.transition,
    required this.isInitial,
    this.providerName,
  });
}
