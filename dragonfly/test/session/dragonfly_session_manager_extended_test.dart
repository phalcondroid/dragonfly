// ignore_for_file: inference_failure_on_function_invocation, strict_raw_type

import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart' show AccessLevel;
import 'package:flutter_test/flutter_test.dart';

class _SpanishMessages extends DragonflyValidationMessages {
  const _SpanishMessages();

  @override
  String get authenticationRequired => 'Autenticación requerida';

  @override
  String requiredRoles(List<String> roles) =>
      'Roles requeridos: ${roles.join(', ')}';
}

void main() {
  group('DragonflySessionManagerExtended', () {
    setUp(() async {
      await DragonflySessionManager.instance.init(
        config: const DragonflySessionConfiguration(persistSession: false),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    group('multiple login/logout cycles', () {
      test('repeated login/logout cycles work correctly', () async {
        for (var i = 0; i < 3; i++) {
          await DragonflySessionManager.I.login(
            token: 'token-$i',
            user: {'id': i},
            roles: ['role-$i'],
            permissions: ['perm-$i'],
          );

          expect(DragonflySessionManager.I.token, 'token-$i');
          expect(DragonflySessionManager.I.isAuthenticated, isTrue);
          expect(DragonflySessionManager.I.hasRole('role-$i'), isTrue);
          expect(DragonflySessionManager.I.hasPermission('perm-$i'), isTrue);

          await DragonflySessionManager.I.logout();

          expect(DragonflySessionManager.I.token, isNull);
          expect(DragonflySessionManager.I.isAuthenticated, isFalse);
          expect(DragonflySessionManager.I.roles, isEmpty);
          expect(DragonflySessionManager.I.permissions, isEmpty);
        }
      });

      test('login values do not leak between cycles', () async {
        await DragonflySessionManager.I.login(
          token: 'first-token',
          roles: ['admin'],
          permissions: ['write'],
        );

        await DragonflySessionManager.I.logout();

        await DragonflySessionManager.I.login(
          token: 'second-token',
          roles: ['user'],
        );

        expect(DragonflySessionManager.I.token, 'second-token');
        expect(DragonflySessionManager.I.roles, {'user'});
        expect(DragonflySessionManager.I.permissions, isEmpty);
        expect(DragonflySessionManager.I.hasRole('admin'), isFalse);
      });
    });

    group('refreshToken', () {
      test('refreshToken updates token without changing user/roles', () async {
        await DragonflySessionManager.I.login(
          token: 'original-token',
          user: {'id': 1, 'name': 'Alice'},
          roles: ['admin'],
          permissions: ['read', 'write'],
        );

        await DragonflySessionManager.I.refreshToken('new-token');

        expect(DragonflySessionManager.I.token, 'new-token');
        expect(
            DragonflySessionManager.I.userData, {'id': 1, 'name': 'Alice'});
        expect(DragonflySessionManager.I.roles, {'admin'});
        expect(DragonflySessionManager.I.permissions, {'read', 'write'});
        expect(DragonflySessionManager.I.isAuthenticated, isTrue);
      });

      test('refreshToken with expiresIn updates expiry', () async {
        await DragonflySessionManager.I.login(
          token: 'original-token',
          expiresIn: const Duration(minutes: 5),
        );

        final oldExpiry = DragonflySessionManager.I.expiresAt;
        await DragonflySessionManager.I.refreshToken(
          'refreshed-token',
          expiresIn: const Duration(hours: 2),
        );

        expect(DragonflySessionManager.I.token, 'refreshed-token');
        expect(
          DragonflySessionManager.I.expiresAt!.difference(oldExpiry!),
          greaterThan(const Duration(minutes: 100)),
        );
      });

      test('refreshToken without expiresIn leaves expiry unchanged', () async {
        await DragonflySessionManager.I.login(
          token: 'original-token',
          expiresIn: const Duration(minutes: 5),
        );

        final oldExpiry = DragonflySessionManager.I.expiresAt;
        await DragonflySessionManager.I.refreshToken('refreshed-token');

        expect(DragonflySessionManager.I.token, 'refreshed-token');
        expect(DragonflySessionManager.I.expiresAt, oldExpiry);
      });
    });

    group('isExpired', () {
      test('returns false when no expiry is set', () async {
        await DragonflySessionManager.I.login(token: 'token');

        expect(DragonflySessionManager.I.isExpired, isFalse);
      });

      test('returns false when expiry is in the future', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          expiresIn: const Duration(hours: 1),
        );

        expect(DragonflySessionManager.I.isExpired, isFalse);
      });

      test('returns true when expiry is in the past', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          expiresIn: const Duration(seconds: -1),
        );

        expect(DragonflySessionManager.I.isExpired, isTrue);
      });
    });

    group('userData', () {
      test('returns user data after login', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          user: {'username': 'test', 'email': 'test@example.com'},
        );

        expect(DragonflySessionManager.I.userData,
            {'username': 'test', 'email': 'test@example.com'});
      });

      test('is null when not logged in', () {
        expect(DragonflySessionManager.I.userData, isNull);
      });
    });

    group('roles', () {
      test('returns set of roles', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['admin', 'user', 'editor'],
        );

        expect(DragonflySessionManager.I.roles, {'admin', 'user', 'editor'});
      });

      test('returns empty set when no roles', () async {
        await DragonflySessionManager.I.login(token: 'token');

        expect(DragonflySessionManager.I.roles, isEmpty);
      });

      test('returned set is unmodifiable', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['admin'],
        );

        expect(
          () => DragonflySessionManager.I.roles.add('user'),
          throwsUnsupportedError,
        );
      });
    });

    group('permissions', () {
      test('returns set of permissions', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          permissions: ['read', 'write', 'delete'],
        );

        expect(DragonflySessionManager.I.permissions,
            {'read', 'write', 'delete'});
      });

      test('returns empty set when no permissions', () async {
        await DragonflySessionManager.I.login(token: 'token');

        expect(DragonflySessionManager.I.permissions, isEmpty);
      });

      test('returned set is unmodifiable', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          permissions: ['read'],
        );

        expect(
          () => DragonflySessionManager.I.permissions.add('write'),
          throwsUnsupportedError,
        );
      });
    });

    group('sessionState', () {
      test('sessionState is unauthenticated initially', () {
        expect(
            DragonflySessionManager.I.state, SessionState.unauthenticated);
      });

      test('sessionState changes to authenticated after login', () async {
        await DragonflySessionManager.I.login(token: 'token');

        expect(DragonflySessionManager.I.state, SessionState.authenticated);
      });

      test('sessionState changes to unauthenticated after logout', () async {
        await DragonflySessionManager.I.login(token: 'token');
        await DragonflySessionManager.I.logout();

        expect(
            DragonflySessionManager.I.state, SessionState.unauthenticated);
      });
    });

    group('init() with null config and null storage', () {
      test('does not throw with null config and null storage', () async {
        await DragonflySessionManager.instance.init();

        expect(
            DragonflySessionManager.I.state, SessionState.unauthenticated);
      });
    });

    group('setValidationMessages i18n', () {
      test('access denied uses custom i18n messages', () async {
        DragonflySessionManager.setValidationMessages(
            const _SpanishMessages());

        await DragonflySessionManager.I.init(
          config: const DragonflySessionConfiguration(persistSession: false),
          storage: InMemorySessionStorage(),
          onAccessDenied: (reason, redirectPath) {
            expect(reason, 'Autenticación requerida');
          },
        );

        DragonflySessionManager.instance.checkAccess(
          accessLevel: AccessLevel.authenticated,
        );
      });
    });

    group('checkAccess', () {
      test(
          'AccessLevel.authenticated when authenticated returns null',
          () async {
        await DragonflySessionManager.I.login(token: 'token');

        final result = DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.authenticated,
        );

        expect(result, isNull);
      });

      test(
          'AccessLevel.authenticated when unauthenticated returns redirect',
          () {
        final result = DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.authenticated,
        );

        expect(result, '/login');
      });

      test(
          'AccessLevel.rolesRequired with matching role returns null',
          () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['admin'],
        );

        final result = DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.rolesRequired,
          requiredRoles: ['admin'],
        );

        expect(result, isNull);
      });

      test(
          'AccessLevel.rolesRequired with non-matching role returns redirect',
          () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['user'],
        );

        final result = DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.rolesRequired,
          requiredRoles: ['admin'],
        );

        expect(result, isNotNull);
      });

      test(
          'AccessLevel.rolesRequired when unauthenticated returns login redirect',
          () {
        final result = DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.rolesRequired,
          requiredRoles: ['admin'],
        );

        expect(result, '/login');
      });

      test(
          'AccessLevel.permissionsRequired with matching permission returns null',
          () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          permissions: ['delete_users'],
        );

        final result = DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.permissionsRequired,
          requiredPermissions: ['delete_users'],
        );

        expect(result, isNull);
      });

      test(
          'AccessLevel.guest always returns null', () {
        final result = DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.guest,
        );

        expect(result, isNull);
      });
    });

    group('state listener callbacks', () {
      test('addStateListener receives state changes', () async {
        final states = <SessionState>[];
        void listener(SessionState s) => states.add(s);

        DragonflySessionManager.I.addStateListener(listener);

        await DragonflySessionManager.I.login(token: 'token');
        await DragonflySessionManager.I.logout();

        expect(states.length, 2);
        expect(states[0], SessionState.authenticated);
        expect(states[1], SessionState.unauthenticated);

        DragonflySessionManager.I.removeStateListener(listener);
      });

      test('removeStateListener stops receiving state changes', () async {
        var callCount = 0;
        void listener(SessionState s) {
          callCount++;
        }

        DragonflySessionManager.I.addStateListener(listener);
        await DragonflySessionManager.I.login(token: 'token');

        expect(callCount, 1);

        DragonflySessionManager.I.removeStateListener(listener);
        await DragonflySessionManager.I.logout();

        expect(callCount, 1);
      });

      test('stateStream emits state changes', () async {
        final emittedStates = <SessionState>[];
        final sub =
            DragonflySessionManager.I.stateStream.listen(emittedStates.add);

        await DragonflySessionManager.I.login(token: 'token');
        await DragonflySessionManager.I.logout();

        expect(emittedStates, [
          SessionState.authenticated,
          SessionState.unauthenticated,
        ]);

        await sub.cancel();
      });
    });

    group('onAccessDenied callback', () {
      test('onAccessDenied is called when access is denied', () async {
        String? deniedReason;
        String? deniedRedirect;

        await DragonflySessionManager.instance.init(
          config: const DragonflySessionConfiguration(persistSession: false),
          storage: InMemorySessionStorage(),
          onAccessDenied: (reason, redirectPath) {
            deniedReason = reason;
            deniedRedirect = redirectPath;
          },
        );

        DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.authenticated,
        );

        expect(deniedReason, isNotNull);
        expect(deniedRedirect, '/login');
      });

      test('onAccessDenied receives custom redirect path', () async {
        String? deniedRedirect;

        await DragonflySessionManager.instance.init(
          config: const DragonflySessionConfiguration(persistSession: false),
          storage: InMemorySessionStorage(),
          onAccessDenied: (reason, redirectPath) {
            deniedRedirect = redirectPath;
          },
        );

        DragonflySessionManager.I.checkAccess(
          accessLevel: AccessLevel.authenticated,
          customRedirectOnUnauthenticated: '/custom-login',
        );

        expect(deniedRedirect, '/custom-login');
      });
    });

    group('post-logout checks', () {
      test('hasRole returns false after logout', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['admin'],
        );

        expect(DragonflySessionManager.I.hasRole('admin'), isTrue);

        await DragonflySessionManager.I.logout();

        expect(DragonflySessionManager.I.hasRole('admin'), isFalse);
      });

      test('hasPermission returns false after logout', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          permissions: ['write'],
        );

        expect(DragonflySessionManager.I.hasPermission('write'), isTrue);

        await DragonflySessionManager.I.logout();

        expect(DragonflySessionManager.I.hasPermission('write'), isFalse);
      });
    });

    group('role helpers', () {
      test('hasAnyRole returns true when user has at least one', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['user', 'editor'],
        );

        expect(
            DragonflySessionManager.I.hasAnyRole(['admin', 'editor']), isTrue);
        expect(DragonflySessionManager.I.hasAnyRole(['admin', 'super']), isFalse);
      });

      test('hasAllRoles returns true when user has all required', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['user', 'editor', 'reviewer'],
        );

        expect(
            DragonflySessionManager.I.hasAllRoles(['user', 'editor']), isTrue);
        expect(
            DragonflySessionManager.I.hasAllRoles(['user', 'admin']), isFalse);
      });

      test('addRoles adds new roles', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['user'],
        );

        await DragonflySessionManager.I.addRoles(['admin', 'editor']);

        expect(DragonflySessionManager.I.roles, {'user', 'admin', 'editor'});
      });

      test('removeRoles removes roles', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          roles: ['user', 'admin', 'editor'],
        );

        await DragonflySessionManager.I.removeRoles(['admin']);

        expect(DragonflySessionManager.I.roles, {'user', 'editor'});
      });
    });

    group('permission helpers', () {
      test('hasAnyPermission returns true when user has at least one',
          () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          permissions: ['read', 'comment'],
        );

        expect(
            DragonflySessionManager.I.hasAnyPermission(['write', 'comment']),
            isTrue);
        expect(
            DragonflySessionManager.I.hasAnyPermission(['write', 'delete']),
            isFalse);
      });

      test('hasAllPermissions returns true when user has all required',
          () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          permissions: ['read', 'write', 'delete'],
        );

        expect(
            DragonflySessionManager.I.hasAllPermissions(['read', 'write']),
            isTrue);
        expect(
            DragonflySessionManager.I.hasAllPermissions(['read', 'admin']),
            isFalse);
      });

      test('addPermissions adds new permissions', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          permissions: ['read'],
        );

        await DragonflySessionManager.I.addPermissions(['write', 'delete']);

        expect(DragonflySessionManager.I.permissions,
            {'read', 'write', 'delete'});
      });

      test('removePermissions removes permissions', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          permissions: ['read', 'write', 'delete'],
        );

        await DragonflySessionManager.I.removePermissions(['write']);

        expect(DragonflySessionManager.I.permissions, {'read', 'delete'});
      });
    });

    group('isLoading', () {
      test('isLoading is false after init', () {
        expect(DragonflySessionManager.I.isLoading, isFalse);
      });

      test('isLoading is false when authenticated', () async {
        await DragonflySessionManager.I.login(token: 'token');

        expect(DragonflySessionManager.I.isLoading, isFalse);
      });
    });

    group('authorizationHeader', () {
      test('returns null when not authenticated', () {
        expect(DragonflySessionManager.I.authorizationHeader, isNull);
      });

      test('returns token with Bearer prefix when authenticated', () async {
        await DragonflySessionManager.I.login(token: 'jwt-token-123');

        expect(DragonflySessionManager.I.authorizationHeader,
            'Bearer jwt-token-123');
      });

      test('respects custom tokenType from config', () async {
        await DragonflySessionManager.instance.init(
          config: const DragonflySessionConfiguration(
            tokenType: 'JWT',
            persistSession: false,
          ),
          storage: InMemorySessionStorage(),
        );

        await DragonflySessionManager.I.login(token: 'secret');

        expect(DragonflySessionManager.I.authorizationHeader, 'JWT secret');
      });
    });

    group('getUser typed', () {
      test('getUser returns typed user via fromJson', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          user: {'name': 'Alice', 'age': 30},
        );

        final user = DragonflySessionManager.I.getUser<Map>(
            (json) => json);
        expect(user?['name'], 'Alice');
      });

      test('getUser returns null when not authenticated', () {
        expect(
          DragonflySessionManager.I.getUser((json) => json),
          isNull,
        );
      });
    });

    group('getUserField', () {
      test('getUserField returns specific field', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          user: {'name': 'Alice', 'age': 30},
        );

        expect(DragonflySessionManager.I.getUserField<String>('name'), 'Alice');
        expect(DragonflySessionManager.I.getUserField<int>('age'), 30);
      });

      test('getUserField returns null when not authenticated', () {
        expect(DragonflySessionManager.I.getUserField<String>('name'), isNull);
      });
    });

    group('updateUser', () {
      test('updateUser replaces userData', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          user: {'name': 'Alice'},
        );

        await DragonflySessionManager.I.updateUser({'name': 'Bob', 'age': 25});

        expect(DragonflySessionManager.I.userData,
            {'name': 'Bob', 'age': 25});
      });

      test('updateUser with Map object works', () async {
        await DragonflySessionManager.I.login(
          token: 'token',
          user: {'name': 'Alice'},
        );

        await DragonflySessionManager.I.updateUser<Map<String, dynamic>>(
            {'name': 'Bob'});

        expect(DragonflySessionManager.I.userData, {'name': 'Bob'});
      });
    });

    group('storage persistence', () {
      test('login persists session and can be restored by re-init', () async {
        final storage = InMemorySessionStorage();

        await DragonflySessionManager.instance.init(
          config: const DragonflySessionConfiguration(persistSession: true),
          storage: storage,
        );

        await DragonflySessionManager.I.login(
          token: 'persisted-token',
          user: {'name': 'Persistent User'},
          roles: ['admin'],
          permissions: ['read'],
        );

        await DragonflySessionManager.instance.init(
          config: const DragonflySessionConfiguration(persistSession: true),
          storage: storage,
        );

        expect(DragonflySessionManager.I.token, 'persisted-token');
        expect(DragonflySessionManager.I.userData,
            {'name': 'Persistent User'});
        expect(DragonflySessionManager.I.roles, {'admin'});
        expect(DragonflySessionManager.I.permissions, {'read'});
        expect(DragonflySessionManager.I.isAuthenticated, isTrue);
      });
    });
  });
}
