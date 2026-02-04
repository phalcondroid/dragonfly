// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RouterGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:example/components/characters/presentation/screens/character_screen.dart';
import 'package:example/components/characters/presentation/features/character_feature.dart';

/// Generated router configuration.
mixin $AppRouterConfig {
  /// Map of route paths to widget builders.
  Map<String, WidgetBuilder> get routes => {
        '/': (context) =>
            CharacterFeatureProvider(child: const CharacterScreen()),
      };

  /// Map of route names to paths.
  Map<String, String> get namedRoutes => {
        'characters': '/',
      };

  /// The initial route for the application.
  String get initialRoute => '/';

  /// Generates a route for the given settings.
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null) return null;

    // First, try exact match
    final builder = routes[routeName];
    if (builder != null) {
      return _buildRoute(settings, builder, _getTransition(routeName));
    }

    // Try pattern matching for dynamic routes
    for (final entry in routes.entries) {
      if (entry.key.contains(':')) {
        final match = _matchRoute(entry.key, routeName);
        if (match != null) {
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
      case '/':
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
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
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
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
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
        return MaterialPageRoute(
          settings: settings,
          builder: builder,
        );
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
  /// Returns the extracted parameters if matched, null otherwise.
  Map<String, String>? _matchRoute(String pattern, String path) {
    final patternSegments = pattern.split('/');
    final pathSegments = path.split('/');

    if (patternSegments.length != pathSegments.length) return null;

    final params = <String, String>{};

    for (var i = 0; i < patternSegments.length; i++) {
      final patternSeg = patternSegments[i];
      final pathSeg = pathSegments[i];

      if (patternSeg.startsWith(':')) {
        // Dynamic segment
        final paramName = patternSeg.substring(1);
        params[paramName] = pathSeg;
      } else if (patternSeg != pathSeg) {
        // Static segment mismatch
        return null;
      }
    }

    return params;
  }

  /// Navigates to a route by name.
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
      Navigator.of(context)
          .pushNamedAndRemoveUntil(path, (_) => false, arguments: arguments);
    }
  }
}
