# Sessions & ACL

Dragonfly provides built-in session management with role-based and permission-based
access control, automatic token injection, and route-level guard checks.

```dart
await DragonflySessionManager.instance.init(
  config: const DragonflySessionConfiguration(
    loginPath: '/login',
    homePath: '/home',
    unauthorizedPath: '/unauthorized',
  ),
  storage: InMemorySessionStorage(),
);

await dragonflySession.login<User>(
  token: token,
  user: user,
  roles: ['admin'],
  permissions: ['read', 'write'],
);

if (dragonflySession.hasRole('admin')) { ... }
if (dragonflySession.hasPermission('write')) { ... }

await dragonflySession.logout();
```

The generated router calls `session.checkAccess(...)` before building every route.
Session tokens are injected into network requests by `AuthenticatedNetworkAdapter`
when a repository method carries `@Authenticated()`.

[Back to README](../../README.md)
