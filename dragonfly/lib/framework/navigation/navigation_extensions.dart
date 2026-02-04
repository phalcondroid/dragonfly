import 'package:flutter/widgets.dart';

/// Navigation extensions for [BuildContext].
extension ContextNavigation on BuildContext {
  /// Push a named route to the navigator.
  Future<T?> push<T extends Object?>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace the current route with a named route.
  Future<T?> replace<T extends Object?>(String routeName, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed<T, dynamic>(routeName, arguments: arguments);
  }

  /// Remove all routes and push a named route.
  Future<T?> pushAndRemoveUntil<T extends Object?>(String routeName,
      {Object? arguments}) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(
        routeName, (route) => false,
        arguments: arguments);
  }

  /// Pop the current route.
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// Check if can pop.
  bool canPop() => Navigator.of(this).canPop();

  /// Go back (alias for pop).
  void goBack<T extends Object?>([T? result]) => pop<T>(result);
}
