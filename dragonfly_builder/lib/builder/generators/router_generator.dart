import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for [RouterConfig].
///
/// This generator scans for [Screen] annotations
/// and creates a router configuration with session/ACL support.
class RouterGenerator extends GeneratorForAnnotation<RouterConfig> {
  final _formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
  static final _screenChecker = TypeChecker.typeNamed(Screen, inPackage: 'dragonfly_annotations');
  static final _pathParamChecker = TypeChecker.typeNamed(PathParam, inPackage: 'dragonfly_annotations');
  static final _queryParamChecker = TypeChecker.typeNamed(QueryParam, inPackage: 'dragonfly_annotations');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    String? initialRoute;
    final Set<String> imports = {};
    final Map<String, _RouteInfo> routes = {};

    final glob = Glob('lib/**.dart');

    // Collect routes (Screen annotations)
    await for (final assetId in buildStep.findAssets(glob)) {
      try {
        final library = await buildStep.resolver.libraryFor(assetId);
        final reader = LibraryReader(library);

        for (final annotatedElement in reader.annotatedWith(_screenChecker)) {
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

            // Parse access level
            final accessValue = annotationObj.read('access').objectValue;
            final accessName =
                accessValue.getField('_name')?.toStringValue() ?? 'guest';

            // Parse roles
            final rolesValue = annotationObj.read('roles').listValue;
            final roles = rolesValue
                .map((e) => e.toStringValue())
                .whereType<String>()
                .toList();

            // Parse permissions
            final permissionsValue =
                annotationObj.read('permissions').listValue;
            final permissions = permissionsValue
                .map((e) => e.toStringValue())
                .whereType<String>()
                .toList();

            // Parse redirect paths
            final redirectOnDenied =
                annotationObj.peek('redirectOnDenied')?.stringValue;
            final redirectOnUnauthenticated =
                annotationObj.peek('redirectOnUnauthenticated')?.stringValue;

            final className = classElement.name ?? '';
            final importUri = assetId.uri.toString();

            // Add screen import
            imports.add("import '$importUri';");

            routes[pathValue] = _RouteInfo(
              path: pathValue,
              className: className,
              name: nameValue,
              transition: transitionName,
              isInitial: isInitial,
              params: _extractScreenParams(classElement),
              accessLevel: accessName,
              roles: roles,
              permissions: permissions,
              redirectOnDenied: redirectOnDenied,
              redirectOnUnauthenticated: redirectOnUnauthenticated,
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
    buffer.writeln("import 'package:dragonfly/dragonfly.dart';");
    buffer.writeln("import 'package:dragonfly_annotations/dragonfly_annotations.dart' show AccessLevel;");
    for (final import in imports) {
      buffer.writeln(import);
    }
    buffer.writeln();

    // Generate mixin
    buffer.writeln('/// Generated router configuration with session/ACL support.');
    buffer.writeln('mixin \$${element.name} {');

    // Routes map (without guards for direct access)
    buffer.writeln('  /// Map of route paths to widget builders.');
    buffer.writeln('  Map<String, WidgetBuilder> get routes => {');
    for (final route in routes.values) {
      if (route.params.isEmpty) {
        buffer.writeln(
            "    '${route.path}': (context) => const ${route.className}(),");
      } else {
        buffer.writeln("    '${route.path}': (context) {");
        if (route.params.any((p) => p.isPath)) {
          buffer.writeln(
              '      final args = ModalRoute.of(context)?.settings.arguments;');
          buffer.writeln(
              '      final pathParams = args is Map<String, String> ? args : const <String, String>{};');
        }
        if (route.params.any((p) => !p.isPath)) {
          buffer.writeln(
              "      final queryParams = Uri.parse(ModalRoute.of(context)?.settings.name ?? '').queryParameters;");
        }
        buffer.writeln(
            '      return ${route.className}(${_ctorArgs(route.params)});');
        buffer.writeln('    },');
      }
    }
    buffer.writeln('  };');
    buffer.writeln();

    // Route configurations for ACL
    buffer.writeln('  /// Route access configurations.');
    buffer.writeln('  Map<String, _RouteAccessConfig> get routeConfigs => {');
    for (final route in routes.values) {
      buffer.writeln("    '${route.path}': _RouteAccessConfig(");
      buffer.writeln("      accessLevel: AccessLevel.${route.accessLevel},");
      buffer.writeln("      roles: const ${_listToString(route.roles)},");
      buffer.writeln("      permissions: const ${_listToString(route.permissions)},");
      if (route.redirectOnDenied != null) {
        buffer.writeln("      redirectOnDenied: '${route.redirectOnDenied}',");
      }
      if (route.redirectOnUnauthenticated != null) {
        buffer.writeln("      redirectOnUnauthenticated: '${route.redirectOnUnauthenticated}',");
      }
      buffer.writeln('    ),');
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

    // Session manager accessor
    buffer.writeln('  /// Get the session manager.');
    buffer.writeln(
        '  DragonflySessionManager get session => DragonflySessionManager.instance;');
    buffer.writeln();

    // Route generator method with ACL
    buffer.writeln('  /// Generates a route for the given settings with ACL checks.');
    buffer.writeln(
        '  Route<dynamic>? onGenerateRoute(RouteSettings settings) {');
    buffer.writeln('    final rawName = settings.name;');
    buffer.writeln('    if (rawName == null) return null;');
    buffer.writeln(
        "    // '/search?q=rick' matches the '/search' route; query params are");
    buffer.writeln('    // read from settings.name inside the route builder.');
    buffer.writeln('    final routeName = Uri.parse(rawName).path;');
    buffer.writeln();
    buffer.writeln('    // Get route config');
    buffer.writeln('    final config = routeConfigs[routeName];');
    buffer.writeln('    final builder = routes[routeName];');
    buffer.writeln();
    buffer.writeln('    // Check access if config exists');
    buffer.writeln('    if (config != null) {');
    buffer.writeln('      final redirectPath = session.checkAccess(');
    buffer.writeln('        accessLevel: config.accessLevel,');
    buffer.writeln('        requiredRoles: config.roles,');
    buffer.writeln('        requiredPermissions: config.permissions,');
    buffer.writeln('        customRedirectOnDenied: config.redirectOnDenied,');
    buffer.writeln('        customRedirectOnUnauthenticated: config.redirectOnUnauthenticated,');
    buffer.writeln('      );');
    buffer.writeln();
    buffer.writeln('      if (redirectPath != null && redirectPath != routeName) {');
    buffer.writeln('        // Redirect to login/unauthorized');
    buffer.writeln('        return _buildRoute(');
    buffer.writeln('          RouteSettings(name: redirectPath),');
    buffer.writeln('          routes[redirectPath] ?? (context) => const SizedBox(),');
    buffer.writeln("          'fade',");
    buffer.writeln('        );');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    // Build the route if access granted');
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
    buffer.writeln('          // Check access for dynamic routes');
    buffer.writeln('          final dynamicConfig = routeConfigs[entry.key];');
    buffer.writeln('          if (dynamicConfig != null) {');
    buffer.writeln('            final redirectPath = session.checkAccess(');
    buffer.writeln('              accessLevel: dynamicConfig.accessLevel,');
    buffer.writeln('              requiredRoles: dynamicConfig.roles,');
    buffer.writeln('              requiredPermissions: dynamicConfig.permissions,');
    buffer.writeln(
        '              customRedirectOnDenied: dynamicConfig.redirectOnDenied,');
    buffer.writeln(
        '              customRedirectOnUnauthenticated: dynamicConfig.redirectOnUnauthenticated,');
    buffer.writeln('            );');
    buffer.writeln('            if (redirectPath != null) {');
    buffer.writeln('              return _buildRoute(');
    buffer.writeln('                RouteSettings(name: redirectPath),');
    buffer.writeln('                routes[redirectPath] ?? (context) => const SizedBox(),');
    buffer.writeln("                'fade',");
    buffer.writeln('              );');
    buffer.writeln('            }');
    buffer.writeln('          }');
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
      buffer.writeln(
          "      case '${route.path}': return '${route.transition}';");
    }
    buffer.writeln("      default: return 'fade';");
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    // Route builder helper
    _generateRouteBuilder(buffer);

    // Route pattern matching helper
    _generateRouteMatching(buffer);

    // Navigation helpers with ACL checks
    _generateNavigationHelpers(buffer);

    buffer.writeln('}');
    buffer.writeln();

    // Generate route access config class
    _generateRouteAccessConfig(buffer);

    try {
      return _formatter.format(buffer.toString());
    } catch (e) {
      return buffer.toString();
    }
  }

  /// Constructor parameters of the screen carrying `@PathParam`/`@QueryParam`.
  List<_ScreenParam> _extractScreenParams(ClassElement screen) {
    if (screen.constructors.isEmpty) return const [];
    final params = <_ScreenParam>[];

    for (final p in screen.constructors.first.formalParameters) {
      final isPath = _pathParamChecker.hasAnnotationOfExact(p);
      final isQuery = !isPath && _queryParamChecker.hasAnnotationOfExact(p);
      if (!isPath && !isQuery) continue;

      final checker = isPath ? _pathParamChecker : _queryParamChecker;
      final annotation = ConstantReader(checker.firstAnnotationOfExact(p));
      final declared = annotation.peek('name')?.stringValue ?? '';
      final name = p.name ?? '';

      params.add(_ScreenParam(
        name: name,
        type: p.type.getDisplayString(),
        key: declared.isEmpty ? name : declared,
        isPath: isPath,
      ));
    }
    return params;
  }

  /// Builds the constructor argument list extracting each param from the
  /// path map or the query string.
  String _ctorArgs(List<_ScreenParam> params) {
    return params.map((p) {
      final source = p.isPath ? 'pathParams' : 'queryParams';
      final read = "$source['${p.key}']";
      final value = switch (p.type) {
        'int' => "int.tryParse($read ?? '') ?? 0",
        'int?' => "int.tryParse($read ?? '')",
        'double' => "double.tryParse($read ?? '') ?? 0.0",
        'double?' => "double.tryParse($read ?? '')",
        'bool' => "$read == 'true'",
        'bool?' => "$read == null ? null : $read == 'true'",
        _ => "$read ?? ''",
      };
      return '${p.name}: $value';
    }).join(', ');
  }

  String _listToString(List<String> list) {
    if (list.isEmpty) return '[]';
    return "[${list.map((e) => "'$e'").join(', ')}]";
  }

  void _generateRouteBuilder(StringBuffer buffer) {
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
    buffer.writeln('              scale: Tween<double>(begin: 0.0, end: 1.0).animate(');
    buffer.writeln('                CurvedAnimation(parent: animation, curve: Curves.easeInOut),');
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
    buffer.writeln('            return FadeTransition(opacity: animation, child: child);');
    buffer.writeln('          },');
    buffer.writeln('        );');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateRouteMatching(StringBuffer buffer) {
    buffer.writeln('  /// Matches a route pattern against a path.');
    buffer.writeln('  Map<String, String>? _matchRoute(String pattern, String path) {');
    buffer.writeln("    final patternSegments = pattern.split('/');");
    buffer.writeln("    final pathSegments = path.split('/');");
    buffer.writeln();
    buffer.writeln('    if (patternSegments.length != pathSegments.length) return null;');
    buffer.writeln();
    buffer.writeln('    final params = <String, String>{};');
    buffer.writeln();
    buffer.writeln('    for (var i = 0; i < patternSegments.length; i++) {');
    buffer.writeln('      final patternSeg = patternSegments[i];');
    buffer.writeln('      final pathSeg = pathSegments[i];');
    buffer.writeln();
    buffer.writeln("      if (patternSeg.startsWith(':')) {");
    buffer.writeln('        final paramName = patternSeg.substring(1);');
    buffer.writeln('        params[paramName] = pathSeg;');
    buffer.writeln('      } else if (patternSeg != pathSeg) {');
    buffer.writeln('        return null;');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    return params;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateNavigationHelpers(StringBuffer buffer) {
    buffer.writeln('  /// Navigates to a route by name (with ACL check).');
    buffer.writeln('  void navigateTo(BuildContext context, String name, {Object? arguments}) {');
    buffer.writeln('    final path = namedRoutes[name];');
    buffer.writeln('    if (path != null) {');
    buffer.writeln('      Navigator.of(context).pushNamed(path, arguments: arguments);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Navigates to a path directly.');
    buffer.writeln('  void navigateToPath(BuildContext context, String path, {Object? arguments}) {');
    buffer.writeln('    Navigator.of(context).pushNamed(path, arguments: arguments);');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Replaces the current route with a new one.');
    buffer.writeln('  void replaceTo(BuildContext context, String name, {Object? arguments}) {');
    buffer.writeln('    final path = namedRoutes[name];');
    buffer.writeln('    if (path != null) {');
    buffer.writeln('      Navigator.of(context).pushReplacementNamed(path, arguments: arguments);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Pops all routes and pushes a new one.');
    buffer.writeln('  void resetTo(BuildContext context, String name, {Object? arguments}) {');
    buffer.writeln('    final path = namedRoutes[name];');
    buffer.writeln('    if (path != null) {');
    buffer.writeln('      Navigator.of(context).pushNamedAndRemoveUntil(path, (_) => false, arguments: arguments);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Navigate to home (after login).');
    buffer.writeln('  void navigateToHome(BuildContext context) {');
    buffer.writeln('    Navigator.of(context).pushNamedAndRemoveUntil(');
    buffer.writeln('      session.config.homePath,');
    buffer.writeln('      (_) => false,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Navigate to login (after logout).');
    buffer.writeln('  void navigateToLogin(BuildContext context) {');
    buffer.writeln('    Navigator.of(context).pushNamedAndRemoveUntil(');
    buffer.writeln('      session.config.loginPath,');
    buffer.writeln('      (_) => false,');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  void _generateRouteAccessConfig(StringBuffer buffer) {
    buffer.writeln('/// Internal route access configuration.');
    buffer.writeln('class _RouteAccessConfig {');
    buffer.writeln('  final AccessLevel accessLevel;');
    buffer.writeln('  final List<String> roles;');
    buffer.writeln('  final List<String> permissions;');
    buffer.writeln('  final String? redirectOnDenied;');
    buffer.writeln('  final String? redirectOnUnauthenticated;');
    buffer.writeln();
    buffer.writeln('  const _RouteAccessConfig({');
    buffer.writeln('    required this.accessLevel,');
    buffer.writeln('    this.roles = const [],');
    buffer.writeln('    this.permissions = const [],');
    buffer.writeln('    this.redirectOnDenied,');
    buffer.writeln('    this.redirectOnUnauthenticated,');
    buffer.writeln('  });');
    buffer.writeln('}');
  }
}

class _RouteInfo {
  final String path;
  final String className;
  final String? name;
  final String transition;
  final bool isInitial;
  final List<_ScreenParam> params;
  final String accessLevel;
  final List<String> roles;
  final List<String> permissions;
  final String? redirectOnDenied;
  final String? redirectOnUnauthenticated;

  _RouteInfo({
    required this.path,
    required this.className,
    this.name,
    required this.transition,
    required this.isInitial,
    this.params = const [],
    required this.accessLevel,
    required this.roles,
    required this.permissions,
    this.redirectOnDenied,
    this.redirectOnUnauthenticated,
  });
}

/// A screen constructor parameter annotated with `@PathParam`/`@QueryParam`.
class _ScreenParam {
  final String name;
  final String type;
  final String key;
  final bool isPath;

  const _ScreenParam({
    required this.name,
    required this.type,
    required this.key,
    required this.isPath,
  });
}
