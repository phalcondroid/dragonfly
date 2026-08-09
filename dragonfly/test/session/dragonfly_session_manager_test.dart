import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart' show AccessLevel;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflySessionConfiguration', () {
    test('default values are correct', () {
      const config = DragonflySessionConfiguration();

      expect(config.loginPath, '/login');
      expect(config.homePath, '/home');
      expect(config.unauthorizedPath, '/unauthorized');
      expect(config.tokenStorageKey, 'dragonfly_auth_token');
      expect(config.userStorageKey, 'dragonfly_current_user');
      expect(config.rolesStorageKey, 'dragonfly_user_roles');
      expect(config.permissionsStorageKey, 'dragonfly_user_permissions');
      expect(config.sessionTimeout, isNull);
      expect(config.persistSession, isTrue);
      expect(config.tokenType, 'Bearer');
      expect(config.authHeaderName, 'Authorization');
    });
  });

  group('DragonflySessionManager', () {
    setUp(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflySessionManager.instance.init(
        config: const DragonflySessionConfiguration(),
        storage: InMemorySessionStorage(),
      );
    });

    tearDown(() async {
      await DragonflySessionManager.instance.logout();
      await DragonflyContainer.I.reset();
    });

    test('singleton pattern works (same instance)', () {
      final a = DragonflySessionManager.instance;
      final b = DragonflySessionManager.instance;
      expect(identical(a, b), isTrue);
    });

    test('I shorthand returns same instance', () {
      expect(
        identical(DragonflySessionManager.I, DragonflySessionManager.instance),
        isTrue,
      );
    });

    test('init() with config and storage — initializes without error', () async {
      final storage = InMemorySessionStorage();
      await DragonflySessionManager.instance.init(
        config: const DragonflySessionConfiguration(),
        storage: storage,
      );
    });

    test('after init, session starts not authenticated', () {
      expect(DragonflySessionManager.I.isAuthenticated, isFalse);
    });

    test('login() sets token, user, roles, permissions; state becomes authenticated',
        () async {
      await DragonflySessionManager.I.login(
        token: 'abc123',
        user: {'id': 1, 'name': 'Test User'},
        roles: ['admin'],
        permissions: ['write'],
      );

      expect(DragonflySessionManager.I.token, 'abc123');
      expect(DragonflySessionManager.I.userData, {'id': 1, 'name': 'Test User'});
      expect(DragonflySessionManager.I.roles, {'admin'});
      expect(DragonflySessionManager.I.permissions, {'write'});
      expect(DragonflySessionManager.I.isAuthenticated, isTrue);
    });

    test('after login, isAuthenticated returns true', () async {
      await DragonflySessionManager.I.login(
        token: 'abc123',
        user: {'id': 1},
      );

      expect(DragonflySessionManager.I.isAuthenticated, isTrue);
    });

    test("hasRole('admin') returns true after login with that role", () async {
      await DragonflySessionManager.I.login(
        token: 'abc123',
        roles: ['admin'],
      );

      expect(DragonflySessionManager.I.hasRole('admin'), isTrue);
      expect(DragonflySessionManager.I.hasRole('user'), isFalse);
    });

    test("hasPermission('write') returns true after login with that permission",
        () async {
      await DragonflySessionManager.I.login(
        token: 'abc123',
        permissions: ['write'],
      );

      expect(DragonflySessionManager.I.hasPermission('write'), isTrue);
      expect(DragonflySessionManager.I.hasPermission('delete'), isFalse);
    });

    test(
        'logout() clears token, user, roles, permissions; state becomes unauthenticated',
        () async {
      await DragonflySessionManager.I.login(
        token: 'abc123',
        user: {'id': 1},
        roles: ['admin'],
        permissions: ['write'],
      );

      await DragonflySessionManager.I.logout();

      expect(DragonflySessionManager.I.token, isNull);
      expect(DragonflySessionManager.I.userData, isNull);
      expect(DragonflySessionManager.I.roles, isEmpty);
      expect(DragonflySessionManager.I.permissions, isEmpty);
      expect(DragonflySessionManager.I.isAuthenticated, isFalse);
    });

    test('token getter returns the stored token', () async {
      await DragonflySessionManager.I.login(token: 'secret-token');

      expect(DragonflySessionManager.I.token, 'secret-token');
    });

    test('userData returns the stored user data', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        user: {'name': 'Alice', 'role': 'editor'},
      );

      expect(
        DragonflySessionManager.I.userData,
        {'name': 'Alice', 'role': 'editor'},
      );
    });

    test('config returns the stored config', () {
      final config = DragonflySessionManager.I.config;
      expect(config.loginPath, '/login');
      expect(config.homePath, '/home');
    });

    test('setValidationMessages() stores messages', () {
      expect(
        () => DragonflySessionManager.setValidationMessages(
          const DragonflyValidationMessages(),
        ),
        returnsNormally,
      );
    });

    test('ACL error messages use validation messages when set', () async {
      await DragonflySessionManager.I.login(
        token: 'abc',
        roles: ['user'],
      );

      final messages = DragonflyValidationMessages();
      DragonflySessionManager.setValidationMessages(messages);

      final result = DragonflySessionManager.instance.checkAccess(
        accessLevel: AccessLevel.rolesRequired,
        requiredRoles: ['admin'],
      );

      expect(result, isNotNull);
    });
  });
}
