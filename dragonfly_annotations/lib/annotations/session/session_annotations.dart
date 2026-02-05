import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

// Re-export AccessLevel enum for use in annotations
// Note: AccessLevel is defined in dragonfly package (session/access_level.dart)
// and re-exported here for annotation convenience.
enum AccessLevel {
  /// Anyone can access (no authentication required).
  guest,

  /// Only authenticated users can access.
  authenticated,

  /// Only users with specific roles can access.
  rolesRequired,

  /// Only users with specific permissions can access.
  permissionsRequired,
}

/// Annotation for defining a screen in the Dragonfly Router with session support.
///
/// This replaces `@DragonflyRoute` and adds session/ACL capabilities.
///
/// Example:
/// ```dart
/// // Public screen (no auth required)
/// @DragonflyScreen(path: '/login', access: AccessLevel.guest)
/// class LoginScreen extends StatelessWidget { ... }
///
/// // Protected screen (auth required)
/// @DragonflyScreen(
///   path: '/home',
///   access: AccessLevel.authenticated,
///   provider: HomeFeature,
/// )
/// class HomeScreen extends StatelessWidget { ... }
///
/// // Role-based access
/// @DragonflyScreen(
///   path: '/admin',
///   access: AccessLevel.rolesRequired,
///   roles: ['admin', 'superadmin'],
/// )
/// class AdminScreen extends StatelessWidget { ... }
///
/// // Permission-based access
/// @DragonflyScreen(
///   path: '/reports',
///   access: AccessLevel.permissionsRequired,
///   permissions: ['view_reports', 'export_data'],
/// )
/// class ReportsScreen extends StatelessWidget { ... }
/// ```
@immutable
@Target({TargetKind.classType})
class DragonflyScreen {
  /// The path for this screen (e.g., '/home', '/character/:id').
  final String path;

  /// Optional name for this screen, used for named navigation.
  final String? name;

  /// Whether this is the initial screen of the application.
  final bool initial;

  /// Optional page transition type.
  final ScreenTransition transition;

  /// Optional duration for the transition animation.
  final Duration? transitionDuration;

  /// Optional Feature type to wrap the screen with its generated Provider.
  final Type? provider;

  /// Access level for this screen.
  final AccessLevel access;

  /// Required roles for accessing this screen (when access = rolesRequired).
  final List<String> roles;

  /// Required permissions for accessing this screen (when access = permissionsRequired).
  final List<String> permissions;

  /// Redirect path when access is denied (defaults to session config).
  final String? redirectOnDenied;

  /// Redirect path when not authenticated (defaults to session config).
  final String? redirectOnUnauthenticated;

  const DragonflyScreen({
    required this.path,
    this.name,
    this.initial = false,
    this.transition = ScreenTransition.fade,
    this.transitionDuration,
    this.provider,
    this.access = AccessLevel.guest,
    this.roles = const [],
    this.permissions = const [],
    this.redirectOnDenied,
    this.redirectOnUnauthenticated,
  });
}

/// Available screen transitions.
enum ScreenTransition {
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

/// Configuration for the Dragonfly Session Manager.
///
/// Define this in your app's configuration to set up session behavior.
///
/// Example:
/// ```dart
/// @DragonflySessionConfig(
///   loginPath: '/login',
///   homePath: '/home',
///   unauthorizedPath: '/unauthorized',
///   tokenStorageKey: 'auth_token',
///   userStorageKey: 'current_user',
///   sessionTimeout: Duration(hours: 24),
/// )
/// class AppSessionConfig {}
/// ```
@immutable
@Target({TargetKind.classType})
class DragonflySessionConfig {
  /// Path to redirect unauthenticated users.
  final String loginPath;

  /// Path to redirect after successful login.
  final String homePath;

  /// Path to redirect when access is denied (unauthorized).
  final String unauthorizedPath;

  /// Storage key for the authentication token.
  final String tokenStorageKey;

  /// Storage key for the current user data.
  final String userStorageKey;

  /// Session timeout duration.
  final Duration? sessionTimeout;

  /// Whether to persist session across app restarts.
  final bool persistSession;

  /// Token type for Authorization header (e.g., 'Bearer', 'Basic').
  final String tokenType;

  /// Header name for the authorization token.
  final String authHeaderName;

  const DragonflySessionConfig({
    this.loginPath = '/login',
    this.homePath = '/home',
    this.unauthorizedPath = '/unauthorized',
    this.tokenStorageKey = 'dragonfly_auth_token',
    this.userStorageKey = 'dragonfly_current_user',
    this.sessionTimeout,
    this.persistSession = true,
    this.tokenType = 'Bearer',
    this.authHeaderName = 'Authorization',
  });
}

/// Marks a network endpoint as requiring authentication.
///
/// When applied, the session token will be automatically added to requests.
///
/// Example:
/// ```dart
/// @Repository(url: '/api')
/// abstract class UserRepository {
///   @Get('/profile')
///   @Authenticated()
///   Future<User> getProfile();
///
///   @Post('/login')
///   Future<AuthResponse> login(@Body() LoginRequest request);
/// }
/// ```
@immutable
@Target({TargetKind.method})
class Authenticated {
  /// Custom token type override (defaults to session config).
  final String? tokenType;

  /// Custom header name override (defaults to session config).
  final String? headerName;

  const Authenticated({
    this.tokenType,
    this.headerName,
  });
}

/// Annotation for extracting path parameters from the route.
@immutable
@Target({TargetKind.field, TargetKind.parameter})
class PathParam {
  final String name;
  const PathParam([this.name = '']);
}

/// Annotation for extracting query parameters from the route.
@immutable
@Target({TargetKind.field, TargetKind.parameter})
class QueryParam {
  final String name;
  const QueryParam([this.name = '']);
}
