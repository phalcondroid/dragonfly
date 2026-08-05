// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// RouterGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart'
    show AccessLevel;
import 'package:example/components/auth/presentation/screens/login_screen.dart';
import 'package:example/components/auth/presentation/features/login_state_manager.dart';
import 'package:example/components/characters/presentation/screens/character_screen.dart';
import 'package:example/components/characters/presentation/features/character_feature.dart';

/// Generated router configuration with session/ACL support.
mixin $AppRouterConfig {
  /// Map of route paths to widget builders.
  Map<String, WidgetBuilder> get routes => {
    '/login': (context) =>
        LoginStateManagerProvider(child: const LoginScreen()),
    '/': (context) => CharacterFeatureProvider(child: const CharacterScreen()),
    '/character-alt': (context) =>
        CharacterFeatureProvider(child: const CharacterScreenAlternative()),
  };

  /// Route access configurations.
  Map<String, _RouteAccessConfig> get routeConfigs => {
    '/login': _RouteAccessConfig(
      accessLevel: AccessLevel.guest,
      roles: const [],
      permissions: const [],
    ),
    '/': _RouteAccessConfig(
      accessLevel: AccessLevel.guest,
      roles: const [],
      permissions: const [],
    ),
    '/character-alt': _RouteAccessConfig(
      accessLevel: AccessLevel.guest,
      roles: const [],
      permissions: const [],
    ),
  };

  /// Map of route names to paths.
  Map<String, String> get namedRoutes => {
    'login': '/login',
    'characters': '/',
    'characters-alt': '/character-alt',
  };

  /// The initial route for the application.
  String get initialRoute => '/';

  /// Get the session manager.
  DragonflySessionManager get session => DragonflySessionManager.instance;

  /// Generates a route for the given settings with ACL checks.
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null) return null;

    // Get route config
    final config = routeConfigs[routeName];
    final builder = routes[routeName];

    // Check access if config exists
    if (config != null) {
      final redirectPath = session.checkAccess(
        accessLevel: config.accessLevel,
        requiredRoles: config.roles,
        requiredPermissions: config.permissions,
        customRedirectOnDenied: config.redirectOnDenied,
        customRedirectOnUnauthenticated: config.redirectOnUnauthenticated,
      );

      if (redirectPath != null && redirectPath != routeName) {
        // Redirect to login/unauthorized
        return _buildRoute(
          RouteSettings(name: redirectPath),
          routes[redirectPath] ?? (context) => const SizedBox(),
          'fade',
        );
      }
    }

    // Build the route if access granted
    if (builder != null) {
      return _buildRoute(settings, builder, _getTransition(routeName));
    }

    // Try pattern matching for dynamic routes
    for (final entry in routes.entries) {
      if (entry.key.contains(':')) {
        final match = _matchRoute(entry.key, routeName);
        if (match != null) {
          // Check access for dynamic routes
          final dynamicConfig = routeConfigs[entry.key];
          if (dynamicConfig != null) {
            final redirectPath = session.checkAccess(
              accessLevel: dynamicConfig.accessLevel,
              requiredRoles: dynamicConfig.roles,
              requiredPermissions: dynamicConfig.permissions,
            );
            if (redirectPath != null) {
              return _buildRoute(
                RouteSettings(name: redirectPath),
                routes[redirectPath] ?? (context) => const SizedBox(),
                'fade',
              );
            }
          }
          return _buildRoute(
            RouteSettings(name: routeName, arguments: match),
            entry.value,
            _getTransition(entry.key),
          );
        }
      }
    }

    return null;
  }

  /// Gets the transition type for a route.
  String _getTransition(String path) {
    switch (path) {
      case '/login':
        return 'fade';
      case '/':
        return 'fade';
      case '/character-alt':
        return 'fade';
      default:
        return 'fade';
    }
  }

  /// Builds a route with the specified transition.
  Route<dynamic> _buildRoute(
    RouteSettings settings,
    WidgetBuilder builder,
    String transition,
  ) {
    switch (transition) {
      case 'none':
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, _, __) => builder(context),
          transitionDuration: Duration.zero,
        );
      case 'slideRight':
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            );
          },
        );
      case 'slideUp':
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            );
          },
        );
      case 'scale':
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
          },
        );
      case 'platform':
        return MaterialPageRoute(settings: settings, builder: builder);
      case 'fade':
      default:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
    }
  }

  /// Matches a route pattern against a path.
  Map<String, String>? _matchRoute(String pattern, String path) {
    final patternSegments = pattern.split('/');
    final pathSegments = path.split('/');

    if (patternSegments.length != pathSegments.length) return null;

    final params = <String, String>{};

    for (var i = 0; i < patternSegments.length; i++) {
      final patternSeg = patternSegments[i];
      final pathSeg = pathSegments[i];

      if (patternSeg.startsWith(':')) {
        final paramName = patternSeg.substring(1);
        params[paramName] = pathSeg;
      } else if (patternSeg != pathSeg) {
        return null;
      }
    }

    return params;
  }

  /// Navigates to a route by name (with ACL check).
  void navigateTo(BuildContext context, String name, {Object? arguments}) {
    final path = namedRoutes[name];
    if (path != null) {
      Navigator.of(context).pushNamed(path, arguments: arguments);
    }
  }

  /// Navigates to a path directly.
  void navigateToPath(BuildContext context, String path, {Object? arguments}) {
    Navigator.of(context).pushNamed(path, arguments: arguments);
  }

  /// Replaces the current route with a new one.
  void replaceTo(BuildContext context, String name, {Object? arguments}) {
    final path = namedRoutes[name];
    if (path != null) {
      Navigator.of(context).pushReplacementNamed(path, arguments: arguments);
    }
  }

  /// Pops all routes and pushes a new one.
  void resetTo(BuildContext context, String name, {Object? arguments}) {
    final path = namedRoutes[name];
    if (path != null) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(path, (_) => false, arguments: arguments);
    }
  }

  /// Navigate to home (after login).
  void navigateToHome(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(session.config.homePath, (_) => false);
  }

  /// Navigate to login (after logout).
  void navigateToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(session.config.loginPath, (_) => false);
  }
}

/// Internal route access configuration.
class _RouteAccessConfig {
  final AccessLevel accessLevel;
  final List<String> roles;
  final List<String> permissions;
  final String? redirectOnDenied;
  final String? redirectOnUnauthenticated;

  const _RouteAccessConfig({
    required this.accessLevel,
    this.roles = const [],
    this.permissions = const [],
    this.redirectOnDenied,
    this.redirectOnUnauthenticated,
  });
}
