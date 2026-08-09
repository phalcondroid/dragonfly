// ---------------------------------------------------------------------------
// Final round of session manager tests — config with all fields, edge
// cases for toJson / toString user objects, empty-list ACL helpers,
// double-logout safety, dispose, and redirect-on-denied override paths.
// ---------------------------------------------------------------------------

// ignore_for_file: inference_failure_on_function_invocation, strict_raw_type

import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart' show AccessLevel;
import 'package:flutter_test/flutter_test.dart';

// ── Test user types ─────────────────────────────────────────────────────────

class _UserWithToJson {
  const _UserWithToJson(this.name, this.age);

  final String name;
  final int age;

  Map<String, dynamic> toJson() => {'name': name, 'age': age};
}

class _UserWithoutToJson {
  const _UserWithoutToJson(this.name);

  final String name;

  @override
  String toString() => 'User: $name';
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('DragonflySessionConfiguration all fields', () {
    test('all custom fields stored correctly', () {
      const config = DragonflySessionConfiguration(
        loginPath: '/sign-in',
        homePath: '/dashboard',
        unauthorizedPath: '/403',
        tokenStorageKey: 'my_token',
        userStorageKey: 'my_user',
        rolesStorageKey: 'my_roles',
        permissionsStorageKey: 'my_perms',
        sessionTimeout: Duration(minutes: 30),
        persistSession: false,
        tokenType: 'JWT',
        authHeaderName: 'X-Auth-Token',
      );

      expect(config.loginPath, '/sign-in');
      expect(config.homePath, '/dashboard');
      expect(config.unauthorizedPath, '/403');
      expect(config.tokenStorageKey, 'my_token');
      expect(config.userStorageKey, 'my_user');
      expect(config.rolesStorageKey, 'my_roles');
      expect(config.permissionsStorageKey, 'my_perms');
      expect(config.sessionTimeout, const Duration(minutes: 30));
      expect(config.persistSession, isFalse);
      expect(config.tokenType, 'JWT');
      expect(config.authHeaderName, 'X-Auth-Token');
    });

    test('custom tokenType and authHeaderName', () {
      const config = DragonflySessionConfiguration(
        tokenType: 'ApiKey',
        authHeaderName: 'X-API-Key',
      );

      expect(config.tokenType, 'ApiKey');
      expect(config.authHeaderName, 'X-API-Key');
    });

    test('custom sessionTimeout is stored', () {
      const config = DragonflySessionConfiguration(
        sessionTimeout: Duration(hours: 2),
      );

      expect(config.sessionTimeout, const Duration(hours: 2));
    });
  });

  group('init() with custom config', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('config getter returns the custom config', () async {
      const customConfig = DragonflySessionConfiguration(
        loginPath: '/auth',
        homePath: '/main',
        tokenType: 'JWT',
        authHeaderName: 'X-Token',
      );

      await DragonflySessionManager.I.init(
        config: customConfig,
        storage: InMemorySessionStorage(),
      );

      expect(DragonflySessionManager.I.config.loginPath, '/auth');
      expect(DragonflySessionManager.I.config.homePath, '/main');
      expect(DragonflySessionManager.I.config.tokenType, 'JWT');
      expect(DragonflySessionManager.I.config.authHeaderName, 'X-Token');
    });

    test('after init, isLoading is false', () async {
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );

      expect(DragonflySessionManager.I.isLoading, isFalse);
    });
  });

  group('onSessionStateChanged via listener', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('state listener receives transitions during login/logout', () async {
      final states = <SessionState>[];

      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );

      void listener(SessionState s) => states.add(s);
      DragonflySessionManager.I.addStateListener(listener);

      await DragonflySessionManager.I.login(token: 'abc');
      await DragonflySessionManager.I.logout();

      expect(states, [SessionState.authenticated, SessionState.unauthenticated]);

      DragonflySessionManager.I.removeStateListener(listener);
    });
  });

  group('onAccessDenied callback', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('receives reason string and redirect path', () async {
      String? capturedReason;
      String? capturedRedirect;

      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
        onAccessDenied: (reason, redirectPath) {
          capturedReason = reason;
          capturedRedirect = redirectPath;
        },
      );

      DragonflySessionManager.I.checkAccess(
        accessLevel: AccessLevel.authenticated,
      );

      expect(capturedReason, isNotNull);
      expect(capturedRedirect, '/login');
    });

    test(
        'permissionsRequired with customRedirectOnDenied uses custom path',
        () async {
      await DragonflySessionManager.I.login(
        token: 'token',
        permissions: ['read'],
      );

      final result = DragonflySessionManager.I.checkAccess(
        accessLevel: AccessLevel.permissionsRequired,
        requiredPermissions: ['write'],
        customRedirectOnDenied: '/custom-denied',
      );

      expect(result, '/custom-denied');
    });

    test('rolesRequired with customRedirectOnDenied uses custom path', () async {
      await DragonflySessionManager.I.login(
        token: 'token',
        roles: ['user'],
      );

      final result = DragonflySessionManager.I.checkAccess(
        accessLevel: AccessLevel.rolesRequired,
        requiredRoles: ['admin'],
        customRedirectOnDenied: '/role-denied',
      );

      expect(result, '/role-denied');
    });
  });

  group('addRoles and removeRoles', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('addRoles adds a single editor role', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['user'],
      );

      await DragonflySessionManager.I.addRoles(['editor']);

      expect(DragonflySessionManager.I.hasRole('editor'), isTrue);
      expect(DragonflySessionManager.I.roles, {'user', 'editor'});
    });

    test('removeRoles removes admin role', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['user', 'admin'],
      );

      await DragonflySessionManager.I.removeRoles(['admin']);

      expect(DragonflySessionManager.I.hasRole('admin'), isFalse);
      expect(DragonflySessionManager.I.roles, {'user'});
    });

    test('removeRoles on non-existent role does not throw', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['user'],
      );

      await DragonflySessionManager.I.removeRoles(['nonexistent']);

      expect(DragonflySessionManager.I.roles, {'user'});
    });

    test('addRoles with duplicate does not create duplicates', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['user'],
      );

      await DragonflySessionManager.I.addRoles(['user']);

      expect(DragonflySessionManager.I.roles, {'user'});
    });
  });

  group('addPermissions and removePermissions', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('addPermissions adds delete permission', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read'],
      );

      await DragonflySessionManager.I.addPermissions(['delete']);

      expect(DragonflySessionManager.I.hasPermission('delete'), isTrue);
      expect(DragonflySessionManager.I.permissions, {'read', 'delete'});
    });

    test('removePermissions removes write permission', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read', 'write'],
      );

      await DragonflySessionManager.I.removePermissions(['write']);

      expect(DragonflySessionManager.I.hasPermission('write'), isFalse);
      expect(DragonflySessionManager.I.permissions, {'read'});
    });

    test('removePermissions on non-existent permission does not throw', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read'],
      );

      await DragonflySessionManager.I.removePermissions(['nonexistent']);

      expect(DragonflySessionManager.I.permissions, {'read'});
    });

    test('addPermissions with duplicate does not create duplicates', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read'],
      );

      await DragonflySessionManager.I.addPermissions(['read']);

      expect(DragonflySessionManager.I.permissions, {'read'});
    });
  });

  // ── getUser / getUserField / updateUser ────────────────────────────────────

  group('getUser with custom type', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('getUser<T> returns typed user from fromJson', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: {'name': 'Alice', 'age': 30},
      );

      final user = DragonflySessionManager.I
          .getUser<Map<String, dynamic>>((json) => json);
      expect(user?['name'], 'Alice');
      expect(user?['age'], 30);
    });

    test('getUser returns null when not authenticated', () {
      final user = DragonflySessionManager.I
          .getUser<Map>((json) => json);
      expect(user, isNull);
    });
  });

  group('getUserField', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test("getUserField('email') returns field value", () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: {'email': 'test@example.com', 'id': 1},
      );

      expect(
        DragonflySessionManager.I.getUserField<String>('email'),
        'test@example.com',
      );
    });

    test('getUserField returns null for missing field', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: {'name': 'Alice'},
      );

      expect(
        DragonflySessionManager.I.getUserField<String>('email'),
        isNull,
      );
    });
  });

  group('updateUser', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test("updateUser({'name': 'Morty'}) updates user data", () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: {'name': 'Rick'},
      );

      await DragonflySessionManager.I.updateUser({'name': 'Morty'});

      expect(
        DragonflySessionManager.I.userData,
        {'name': 'Morty'},
      );
    });

    test('updateUser with custom object having toJson', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: {'name': 'Old'},
      );

      await DragonflySessionManager.I
          .updateUser(const _UserWithToJson('NewName', 25));

      expect(
        DragonflySessionManager.I.userData,
        {'name': 'NewName', 'age': 25},
      );
    });

    test('updateUser with object without toJson', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: {'name': 'Old'},
      );

      await DragonflySessionManager.I
          .updateUser(const _UserWithoutToJson('Bob'));

      expect(DragonflySessionManager.I.userData?['data'], 'User: Bob');
    });
  });

  // ── hasAllRoles / hasAllPermissions ────────────────────────────────────────

  group('hasAllRoles', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('returns true when user has all roles', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['admin', 'editor'],
      );

      expect(
        DragonflySessionManager.I.hasAllRoles(['admin', 'editor']),
        isTrue,
      );
    });

    test('returns false when user lacks one role', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['admin'],
      );

      expect(
        DragonflySessionManager.I.hasAllRoles(['admin', 'missing']),
        isFalse,
      );
    });

    test('returns true for empty required list', () {
      expect(DragonflySessionManager.I.hasAllRoles([]), isTrue);
    });

    test('returns false when not logged in', () {
      expect(
        DragonflySessionManager.I.hasAllRoles(['admin']),
        isFalse,
      );
    });
  });

  group('hasAllPermissions', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('returns true when user has all permissions', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read', 'write'],
      );

      expect(
        DragonflySessionManager.I.hasAllPermissions(['read', 'write']),
        isTrue,
      );
    });

    test('returns false when user lacks one permission', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read'],
      );

      expect(
        DragonflySessionManager.I.hasAllPermissions(['read', 'admin']),
        isFalse,
      );
    });

    test('returns true for empty required list', () {
      expect(DragonflySessionManager.I.hasAllPermissions([]), isTrue);
    });

    test('returns false when not logged in', () {
      expect(
        DragonflySessionManager.I.hasAllPermissions(['read']),
        isFalse,
      );
    });
  });

  // ── hasAnyRole / hasAnyPermission ──────────────────────────────────────────

  group('hasAnyRole', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('returns false for empty required list', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['admin'],
      );

      expect(DragonflySessionManager.I.hasAnyRole([]), isFalse);
    });
  });

  group('hasAnyPermission', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('returns false for empty required list', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read'],
      );

      expect(DragonflySessionManager.I.hasAnyPermission([]), isFalse);
    });
  });

  // ── login with object user types ───────────────────────────────────────────

  group('login with custom user types', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('login with object having toJson stores parsed data', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: const _UserWithToJson('Charlie', 28),
      );

      expect(
        DragonflySessionManager.I.userData,
        {'name': 'Charlie', 'age': 28},
      );
    });

    test('login with object without toJson falls back to toString', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: const _UserWithoutToJson('Dave'),
      );

      expect(DragonflySessionManager.I.userData?['data'], 'User: Dave');
    });

    test('login with null user leaves userData null', () async {
      await DragonflySessionManager.I.login(token: 'abc');

      expect(DragonflySessionManager.I.userData, isNull);
    });
  });

  // ── expiry interplay ───────────────────────────────────────────────────────

  group('session expiry interplay', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('login expiresIn overrides config sessionTimeout', () async {
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(
          sessionTimeout: Duration(minutes: 10),
          persistSession: false,
        ),
        storage: InMemorySessionStorage(),
      );

      await DragonflySessionManager.I.login(
        token: 'abc',
        expiresIn: const Duration(minutes: 60),
      );

      expect(DragonflySessionManager.I.expiresAt, isNotNull);
      final diff =
          DragonflySessionManager.I.expiresAt!.difference(DateTime.now());
      expect(diff.inMinutes, greaterThanOrEqualTo(59));
    });

    test('login without expiresIn uses config sessionTimeout', () async {
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(
          sessionTimeout: Duration(minutes: 30),
          persistSession: false,
        ),
        storage: InMemorySessionStorage(),
      );

      await DragonflySessionManager.I.login(token: 'abc');

      expect(DragonflySessionManager.I.expiresAt, isNotNull);
      final diff =
          DragonflySessionManager.I.expiresAt!.difference(DateTime.now());
      expect(diff.inMinutes, greaterThanOrEqualTo(29));
    });

    test('login with no expiresIn and no config sessionTimeout sets no expiry',
        () async {
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(
          sessionTimeout: null,
          persistSession: false,
        ),
        storage: InMemorySessionStorage(),
      );

      await DragonflySessionManager.I.login(token: 'abc');

      expect(DragonflySessionManager.I.expiresAt, isNull);
    });
  });

  // ── logout safety ──────────────────────────────────────────────────────────

  group('logout safety', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('double logout does not throw', () async {
      await DragonflySessionManager.I.login(token: 'abc');
      await DragonflySessionManager.I.logout();
      await DragonflySessionManager.I.logout();
    });

    test('logout when never logged in does not throw', () async {
      await DragonflySessionManager.I.logout();
    });

    test('state is unauthenticated after logout', () async {
      await DragonflySessionManager.I.login(token: 'abc');
      await DragonflySessionManager.I.logout();

      expect(
          DragonflySessionManager.I.state, SessionState.unauthenticated);
    });
  });

  // ── checkAccess: custom redirect on denied ─────────────────────────────────

  group('checkAccess custom redirect on denied', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
      await DragonflySessionManager.I.init(
        config: const DragonflySessionConfiguration(
          persistSession: false,
          unauthorizedPath: '/default-unauthorized',
        ),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('rolesRequired denied uses customRedirectOnDenied', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['user'],
      );

      final result = DragonflySessionManager.I.checkAccess(
        accessLevel: AccessLevel.rolesRequired,
        requiredRoles: ['admin'],
        customRedirectOnDenied: '/custom-403',
      );

      expect(result, '/custom-403');
    });

    test('rolesRequired denied uses default unauthorizedPath', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['user'],
      );

      final result = DragonflySessionManager.I.checkAccess(
        accessLevel: AccessLevel.rolesRequired,
        requiredRoles: ['admin'],
      );

      expect(result, '/default-unauthorized');
    });

    test('permissionsRequired denied uses customRedirectOnDenied', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read'],
      );

      final result = DragonflySessionManager.I.checkAccess(
        accessLevel: AccessLevel.permissionsRequired,
        requiredPermissions: ['delete'],
        customRedirectOnDenied: '/custom-perm-denied',
      );

      expect(result, '/custom-perm-denied');
    });

    test('permissionsRequired denied uses default unauthorizedPath', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        permissions: ['read'],
      );

      final result = DragonflySessionManager.I.checkAccess(
        accessLevel: AccessLevel.permissionsRequired,
        requiredPermissions: ['delete'],
      );

      expect(result, '/default-unauthorized');
    });
  });

  // ── global accessor ────────────────────────────────────────────────────────

  group('dragonflySession global accessor', () {
    test('dragonflySession returns the same instance', () {
      expect(
        identical(dragonflySession, DragonflySessionManager.I),
        isTrue,
      );
    });
  });
}
