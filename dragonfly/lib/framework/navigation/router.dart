import 'package:flutter/widgets.dart';

/// A simple router for Dragonfly.
///
/// Holds the mapping of routes to widget builders.
class DragonflyRouter {
  DragonflyRouter._();

  static final DragonflyRouter instance = DragonflyRouter._();

  final Map<String, WidgetBuilder> _routes = {};
  String? _initialRoute;

  /// Configures the router with the given routes.
  void configure(Map<String, WidgetBuilder> routes, {String? initialRoute}) {
    _routes.clear();
    _routes.addAll(routes);
    if (initialRoute != null) {
      _initialRoute = initialRoute;
    }
  }

  /// Gets the registered routes.
  Map<String, WidgetBuilder> get routes => Map.unmodifiable(_routes);

  /// Gets the initial route, if any.
  String? get initialRoute => _initialRoute;

  /// Generates a route for the given settings.
  ///
  /// Returns a [PageRouteBuilder] if the route is found.
  /// Customize this if you need different transitions or route types.
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Simple exact match
    final builder = _routes[settings.name];
    if (builder != null) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    }
    return null;
  }
}
