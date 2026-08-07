import 'dart:async';
import 'dart:convert';
import 'package:dragonfly/framework/form/dragonfly_validation_messages.dart';
import 'package:dragonfly/framework/logging/dragonfly_log_manager.dart';
import 'package:dragonfly/framework/session/session_storage.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart'
    show AccessLevel;

/// Session state enumeration.
enum SessionState {
  /// No session exists.
  unauthenticated,

  /// Session is being validated/restored.
  loading,

  /// Session is active and valid.
  authenticated,

  /// Session has expired.
  expired,
}

/// Configuration for the session manager.
class DragonflySessionConfiguration {
  /// Path to redirect unauthenticated users.
  final String loginPath;

  /// Path to redirect after successful login.
  final String homePath;

  /// Path to redirect when access is denied.
  final String unauthorizedPath;

  /// Storage key for the authentication token.
  final String tokenStorageKey;

  /// Storage key for the current user data.
  final String userStorageKey;

  /// Storage key for user roles.
  final String rolesStorageKey;

  /// Storage key for user permissions.
  final String permissionsStorageKey;

  /// Session timeout duration.
  final Duration? sessionTimeout;

  /// Whether to persist session across app restarts.
  final bool persistSession;

  /// Token type for Authorization header.
  final String tokenType;

  /// Header name for the authorization token.
  final String authHeaderName;

  const DragonflySessionConfiguration({
    this.loginPath = '/login',
    this.homePath = '/home',
    this.unauthorizedPath = '/unauthorized',
    this.tokenStorageKey = 'dragonfly_auth_token',
    this.userStorageKey = 'dragonfly_current_user',
    this.rolesStorageKey = 'dragonfly_user_roles',
    this.permissionsStorageKey = 'dragonfly_user_permissions',
    this.sessionTimeout,
    this.persistSession = true,
    this.tokenType = 'Bearer',
    this.authHeaderName = 'Authorization',
  });
}

/// Callback for session state changes.
typedef SessionStateCallback = void Function(SessionState state);

/// Callback for access denied events.
typedef AccessDeniedCallback = void Function(
    String reason, String? redirectPath);

/// The main session manager for Dragonfly applications.
///
/// Handles:
/// - User authentication state
/// - Token management
/// - Role-based access control (RBAC)
/// - Permission-based access control
/// - Session persistence
///
/// Example:
/// ```dart
/// // Initialize session manager with Hive storage
/// await DragonflySessionManager.instance.init(
///   config: DragonflySessionConfiguration(
///     loginPath: '/login',
///     homePath: '/home',
///   ),
///   storage: HiveSessionStorage(Hive.box('session')),
/// );
///
/// // Login
/// await session.login<User>(
///   token: 'jwt_token_here',
///   user: currentUser,
///   roles: ['user', 'premium'],
///   permissions: ['read', 'write'],
/// );
///
/// // Check access
/// if (session.hasRole('admin')) { ... }
/// if (session.hasPermission('delete_users')) { ... }
///
/// // Logout
/// await session.logout();
/// ```
class DragonflySessionManager {
  DragonflySessionManager._();

  static DragonflySessionManager? _instance;

  /// Internationalized validation messages for ACL access-denied reasons.
  ///
  /// Set during [DragonflyApp.init] from [DragonflyConfig.validationMessages].
  /// If null, English messages are used.
  static DragonflyValidationMessages? _messages;

  /// Sets the validation messages used for ACL access-denied reasons.
  static void setValidationMessages(DragonflyValidationMessages messages) {
    _messages = messages;
  }

  /// Get the singleton instance.
  static DragonflySessionManager get instance {
    _instance ??= DragonflySessionManager._();
    return _instance!;
  }

  /// Shorthand accessor.
  static DragonflySessionManager get I => instance;

  /// Session configuration.
  DragonflySessionConfiguration _config = const DragonflySessionConfiguration();

  /// Current session state.
  SessionState _state = SessionState.unauthenticated;

  /// Current authentication token.
  String? _token;

  /// Current user data (stored as JSON).
  Map<String, dynamic>? _userData;

  /// Current user roles.
  Set<String> _roles = {};

  /// Current user permissions.
  Set<String> _permissions = {};

  /// Session expiration time.
  DateTime? _expiresAt;

  /// Stream controller for session state changes.
  final _stateController = StreamController<SessionState>.broadcast();

  /// Listeners for state changes.
  final List<SessionStateCallback> _stateListeners = [];

  /// Access denied callback.
  AccessDeniedCallback? _onAccessDenied;

  /// Session storage instance.
  SessionStorage? _storage;

  /// Logger.
  DragonflyLogManager get _log => DragonflyLogManager.instance;

  // ─────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────

  /// Current session configuration.
  DragonflySessionConfiguration get config => _config;

  /// Current session state.
  SessionState get state => _state;

  /// Whether the user is authenticated.
  bool get isAuthenticated => _state == SessionState.authenticated;

  /// Whether the session is loading/restoring.
  bool get isLoading => _state == SessionState.loading;

  /// Current authentication token.
  String? get token => _token;

  /// Current user data as a map.
  Map<String, dynamic>? get userData => _userData;

  /// Current user roles.
  Set<String> get roles => Set.unmodifiable(_roles);

  /// Current user permissions.
  Set<String> get permissions => Set.unmodifiable(_permissions);

  /// Session expiration time.
  DateTime? get expiresAt => _expiresAt;

  /// Whether the session has expired.
  bool get isExpired {
    if (_expiresAt == null) return false;
    return DateTime.now().isAfter(_expiresAt!);
  }

  /// Stream of session state changes.
  Stream<SessionState> get stateStream => _stateController.stream;

  /// Authorization header value.
  String? get authorizationHeader {
    if (_token == null) return null;
    return '${_config.tokenType} $_token';
  }

  // ─────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────

  /// Initialize the session manager.
  ///
  /// [config] - Session configuration
  /// [storage] - Storage implementation (defaults to InMemorySessionStorage)
  /// [onAccessDenied] - Callback when access is denied
  Future<void> init({
    DragonflySessionConfiguration? config,
    SessionStorage? storage,
    AccessDeniedCallback? onAccessDenied,
  }) async {
    _config = config ?? const DragonflySessionConfiguration();
    _onAccessDenied = onAccessDenied;

    // Use provided storage or fallback to in-memory
    _storage = storage ?? InMemorySessionStorage();

    _log.info('Initializing Session Manager...', tag: 'Session');

    if (_config.persistSession) {
      await _restoreSession();
    }

    _log.success(
      'Session Manager initialized',
      tag: 'Session',
      data: {'state': _state.name, 'isAuthenticated': isAuthenticated},
    );
  }

  /// Restore session from persistent storage.
  Future<void> _restoreSession() async {
    if (_storage == null) return;

    _setState(SessionState.loading);

    try {
      final token = await _storage!.getString(_config.tokenStorageKey);
      final userJson = await _storage!.getString(_config.userStorageKey);
      final rolesJson = await _storage!.getStringList(_config.rolesStorageKey);
      final permissionsJson =
          await _storage!.getStringList(_config.permissionsStorageKey);
      final expiresAtMs =
          await _storage!.getInt('${_config.tokenStorageKey}_expires');

      if (token != null && token.isNotEmpty) {
        _token = token;

        if (userJson != null) {
          _userData = jsonDecode(userJson) as Map<String, dynamic>;
        }

        _roles = rolesJson?.toSet() ?? {};
        _permissions = permissionsJson?.toSet() ?? {};

        if (expiresAtMs != null) {
          _expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
        }

        // Check if session has expired
        if (isExpired) {
          _log.warning('Restored session has expired', tag: 'Session');
          await logout();
          return;
        }

        _setState(SessionState.authenticated);
        _log.success('Session restored', tag: 'Session');
      } else {
        _setState(SessionState.unauthenticated);
      }
    } catch (e, s) {
      _log.error('Failed to restore session',
          tag: 'Session', error: e, stackTrace: s);
      _setState(SessionState.unauthenticated);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Authentication
  // ─────────────────────────────────────────────────────────────────

  /// Login and create a new session.
  ///
  /// [token] - Authentication token (JWT, API key, etc.)
  /// [user] - User data (will be serialized to JSON)
  /// [roles] - User roles for RBAC
  /// [permissions] - User permissions for fine-grained access control
  /// [expiresIn] - Session expiration duration
  Future<void> login<T>({
    required String token,
    T? user,
    List<String>? roles,
    List<String>? permissions,
    Duration? expiresIn,
  }) async {
    _log.info('Creating session...', tag: 'Session');

    _token = token;
    _roles = roles?.toSet() ?? {};
    _permissions = permissions?.toSet() ?? {};

    // Handle user data
    if (user != null) {
      if (user is Map<String, dynamic>) {
        _userData = user;
      } else {
        // Try to call toJson if available
        try {
          _userData = (user as dynamic).toJson() as Map<String, dynamic>;
        } catch (_) {
          _userData = {'data': user.toString()};
        }
      }
    }

    // Set expiration
    if (expiresIn != null) {
      _expiresAt = DateTime.now().add(expiresIn);
    } else if (_config.sessionTimeout != null) {
      _expiresAt = DateTime.now().add(_config.sessionTimeout!);
    }

    // Persist if enabled
    if (_config.persistSession && _storage != null) {
      await _persistSession();
    }

    _setState(SessionState.authenticated);

    _log.success(
      'Session created',
      tag: 'Session',
      data: {
        'roles': _roles.toList(),
        'permissions': _permissions.length,
        'expiresAt': _expiresAt?.toIso8601String(),
      },
    );
  }

  /// Persist session to storage.
  Future<void> _persistSession() async {
    if (_storage == null) return;

    await _storage!.setString(_config.tokenStorageKey, _token ?? '');

    if (_userData != null) {
      await _storage!.setString(_config.userStorageKey, jsonEncode(_userData));
    }

    await _storage!.setStringList(_config.rolesStorageKey, _roles.toList());
    await _storage!
        .setStringList(_config.permissionsStorageKey, _permissions.toList());

    if (_expiresAt != null) {
      await _storage!.setInt(
        '${_config.tokenStorageKey}_expires',
        _expiresAt!.millisecondsSinceEpoch,
      );
    }
  }

  /// Logout and clear the session.
  Future<void> logout() async {
    _log.info('Logging out...', tag: 'Session');

    _token = null;
    _userData = null;
    _roles = {};
    _permissions = {};
    _expiresAt = null;

    // Clear persisted data
    if (_config.persistSession && _storage != null) {
      await _storage!.remove(_config.tokenStorageKey);
      await _storage!.remove(_config.userStorageKey);
      await _storage!.remove(_config.rolesStorageKey);
      await _storage!.remove(_config.permissionsStorageKey);
      await _storage!.remove('${_config.tokenStorageKey}_expires');
    }

    _setState(SessionState.unauthenticated);
    _log.success('Session cleared', tag: 'Session');
  }

  /// Refresh the session token.
  Future<void> refreshToken(String newToken, {Duration? expiresIn}) async {
    _token = newToken;

    if (expiresIn != null) {
      _expiresAt = DateTime.now().add(expiresIn);
    }

    if (_config.persistSession && _storage != null) {
      await _storage!.setString(_config.tokenStorageKey, newToken);
      if (_expiresAt != null) {
        await _storage!.setInt(
          '${_config.tokenStorageKey}_expires',
          _expiresAt!.millisecondsSinceEpoch,
        );
      }
    }

    _log.info('Token refreshed', tag: 'Session');
  }

  // ─────────────────────────────────────────────────────────────────
  // User Data
  // ─────────────────────────────────────────────────────────────────

  /// Get the current user as a typed object.
  ///
  /// Requires a fromJson factory constructor.
  T? getUser<T>(T Function(Map<String, dynamic>) fromJson) {
    if (_userData == null) return null;
    try {
      return fromJson(_userData!);
    } catch (e) {
      _log.error('Failed to parse user data', tag: 'Session', error: e);
      return null;
    }
  }

  /// Update user data.
  Future<void> updateUser<T>(T user) async {
    if (user is Map<String, dynamic>) {
      _userData = user;
    } else {
      try {
        _userData = (user as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        _userData = {'data': user.toString()};
      }
    }

    if (_config.persistSession && _storage != null) {
      await _storage!.setString(_config.userStorageKey, jsonEncode(_userData));
    }
  }

  /// Get a specific field from user data.
  T? getUserField<T>(String field) {
    return _userData?[field] as T?;
  }

  // ─────────────────────────────────────────────────────────────────
  // Access Control
  // ─────────────────────────────────────────────────────────────────

  /// Check if the user has a specific role.
  bool hasRole(String role) => _roles.contains(role);

  /// Check if the user has any of the specified roles.
  bool hasAnyRole(List<String> requiredRoles) {
    return requiredRoles.any((role) => _roles.contains(role));
  }

  /// Check if the user has all of the specified roles.
  bool hasAllRoles(List<String> requiredRoles) {
    return requiredRoles.every((role) => _roles.contains(role));
  }

  /// Check if the user has a specific permission.
  bool hasPermission(String permission) => _permissions.contains(permission);

  /// Check if the user has any of the specified permissions.
  bool hasAnyPermission(List<String> requiredPermissions) {
    return requiredPermissions.any((perm) => _permissions.contains(perm));
  }

  /// Check if the user has all of the specified permissions.
  bool hasAllPermissions(List<String> requiredPermissions) {
    return requiredPermissions.every((perm) => _permissions.contains(perm));
  }

  /// Add roles to the current session.
  Future<void> addRoles(List<String> newRoles) async {
    _roles.addAll(newRoles);
    if (_config.persistSession && _storage != null) {
      await _storage!.setStringList(_config.rolesStorageKey, _roles.toList());
    }
  }

  /// Remove roles from the current session.
  Future<void> removeRoles(List<String> rolesToRemove) async {
    _roles.removeAll(rolesToRemove);
    if (_config.persistSession && _storage != null) {
      await _storage!.setStringList(_config.rolesStorageKey, _roles.toList());
    }
  }

  /// Add permissions to the current session.
  Future<void> addPermissions(List<String> newPermissions) async {
    _permissions.addAll(newPermissions);
    if (_config.persistSession && _storage != null) {
      await _storage!
          .setStringList(_config.permissionsStorageKey, _permissions.toList());
    }
  }

  /// Remove permissions from the current session.
  Future<void> removePermissions(List<String> permsToRemove) async {
    _permissions.removeAll(permsToRemove);
    if (_config.persistSession && _storage != null) {
      await _storage!
          .setStringList(_config.permissionsStorageKey, _permissions.toList());
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Route Guards
  // ─────────────────────────────────────────────────────────────────

  /// Check if the user can access a route with the given access requirements.
  ///
  /// Returns the redirect path if access is denied, null if access is granted.
  String? checkAccess({
    required AccessLevel accessLevel,
    List<String> requiredRoles = const [],
    List<String> requiredPermissions = const [],
    String? customRedirectOnDenied,
    String? customRedirectOnUnauthenticated,
  }) {
    switch (accessLevel) {
      case AccessLevel.guest:
        // Anyone can access
        return null;

      case AccessLevel.authenticated:
        if (!isAuthenticated) {
          _notifyAccessDenied(
            _messages?.authenticationRequired ?? 'Authentication required',
            customRedirectOnUnauthenticated ?? _config.loginPath,
          );
          return customRedirectOnUnauthenticated ?? _config.loginPath;
        }
        return null;

      case AccessLevel.rolesRequired:
        if (!isAuthenticated) {
          _notifyAccessDenied(
            _messages?.authenticationRequired ?? 'Authentication required',
            customRedirectOnUnauthenticated ?? _config.loginPath,
          );
          return customRedirectOnUnauthenticated ?? _config.loginPath;
        }
        if (!hasAnyRole(requiredRoles)) {
          _notifyAccessDenied(
            _messages?.requiredRoles(requiredRoles) ?? 'Required roles: ${requiredRoles.join(", ")}',
            customRedirectOnDenied ?? _config.unauthorizedPath,
          );
          return customRedirectOnDenied ?? _config.unauthorizedPath;
        }
        return null;

      case AccessLevel.permissionsRequired:
        if (!isAuthenticated) {
          _notifyAccessDenied(
            _messages?.authenticationRequired ?? 'Authentication required',
            customRedirectOnUnauthenticated ?? _config.loginPath,
          );
          return customRedirectOnUnauthenticated ?? _config.loginPath;
        }
        if (!hasAnyPermission(requiredPermissions)) {
          _notifyAccessDenied(
            _messages?.requiredPermissions(requiredPermissions) ?? 'Required permissions: ${requiredPermissions.join(", ")}',
            customRedirectOnDenied ?? _config.unauthorizedPath,
          );
          return customRedirectOnDenied ?? _config.unauthorizedPath;
        }
        return null;
    }
  }

  void _notifyAccessDenied(String reason, String? redirectPath) {
    _log.warning('Access denied: $reason', tag: 'Session');
    _onAccessDenied?.call(reason, redirectPath);
  }

  // ─────────────────────────────────────────────────────────────────
  // State Management
  // ─────────────────────────────────────────────────────────────────

  void _setState(SessionState newState) {
    if (_state == newState) return;

    _state = newState;
    _stateController.add(newState);

    for (final listener in _stateListeners) {
      listener(newState);
    }
  }

  /// Add a listener for session state changes.
  void addStateListener(SessionStateCallback listener) {
    _stateListeners.add(listener);
  }

  /// Remove a session state listener.
  void removeStateListener(SessionStateCallback listener) {
    _stateListeners.remove(listener);
  }

  /// Dispose the session manager.
  void dispose() {
    _stateController.close();
    _stateListeners.clear();
  }
}

/// Global accessor for the session manager.
DragonflySessionManager get dragonflySession =>
    DragonflySessionManager.instance;
