import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Annotation for generating the Dragonfly Router configuration.
///
/// Annotate a class with this to trigger the router generation.
/// The generator will scan for [DragonflyRoute] annotations
/// and generate a router map.
///
/// Example:
/// ```dart
/// part 'router_config.router.dart';
///
/// @DragonflyRouterConfig()
/// class AppRouterConfig with $AppRouterConfig {}
/// ```
@immutable
class DragonflyRouterConfig {
  const DragonflyRouterConfig();
}

/// Annotation for defining a route in the Dragonfly Router.
///
/// Apply this annotation to a StatelessWidget or StatefulWidget
/// to register it as a route.
///
/// Example:
/// ```dart
/// @DragonflyRoute(path: '/home', initial: true)
/// class HomeScreen extends StatelessWidget {
///   const HomeScreen({super.key});
///   // ...
/// }
///
/// // With a Feature provider (auto-wraps screen with provider)
/// @DragonflyRoute(
///   path: '/character',
///   name: 'character',
///   provider: CharacterFeature,
/// )
/// class CharacterScreen extends StatelessWidget {
///   const CharacterScreen({super.key});
///   // ...
/// }
/// ```
@immutable
@Target({TargetKind.classType})
class DragonflyRoute {
  /// The path for this route (e.g., '/home', '/character/:id').
  final String path;

  /// Optional name for this route, used for named navigation.
  final String? name;

  /// Whether this is the initial route of the application.
  final bool initial;

  /// Optional page transition type.
  final RouteTransition transition;

  /// Optional duration for the transition animation.
  final Duration? transitionDuration;

  /// Optional Feature type to wrap the screen with its generated Provider.
  ///
  /// When specified, the router will wrap the screen with `{FeatureName}Provider`.
  /// For example, if `provider: CharacterFeature`, the screen will be wrapped with
  /// `CharacterFeatureProvider(child: CharacterScreen())`.
  final Type? provider;

  const DragonflyRoute({
    required this.path,
    this.name,
    this.initial = false,
    this.transition = RouteTransition.fade,
    this.transitionDuration,
    this.provider,
  });
}

/// Available route transitions.
enum RouteTransition {
  /// Fade transition (default).
  fade,

  /// Slide from right.
  slideRight,

  /// Slide from bottom.
  slideUp,

  /// Scale transition.
  scale,

  /// No transition (instant).
  none,

  /// Platform default (Material/Cupertino).
  platform,
}

/// Annotation for extracting path parameters from the route.
///
/// Example:
/// ```dart
/// @DragonflyRoute(path: '/character/:id')
/// class CharacterScreen extends StatelessWidget {
///   @PathParam('id')
///   final int id;
///   // ...
/// }
/// ```
@immutable
@Target({TargetKind.field, TargetKind.parameter})
class PathParam {
  /// The name of the path parameter.
  final String name;

  const PathParam([this.name = '']);
}

/// Annotation for extracting query parameters from the route.
///
/// Example:
/// ```dart
/// @DragonflyRoute(path: '/search')
/// class SearchScreen extends StatelessWidget {
///   @QueryParam('q')
///   final String? query;
///   // ...
/// }
/// ```
@immutable
@Target({TargetKind.field, TargetKind.parameter})
class QueryParam {
  /// The name of the query parameter.
  final String name;

  const QueryParam([this.name = '']);
}
