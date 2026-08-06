# Routing

`@RouterConfig` triggers the router generator. `@Screen` registers each route with
optional ACL:

```dart
@RouterConfig()
class AppRouterConfig with $AppRouterConfig {}
```

```dart
@Screen(path: '/login',            access: AccessLevel.guest)
class LoginScreen extends StatelessWidget { ... }

@Screen(path: '/home',             access: AccessLevel.authenticated)
class HomeScreen extends StatelessWidget { ... }

@Screen(path: '/admin',            access: AccessLevel.rolesRequired,
        roles: ['admin', 'superadmin'])
class AdminScreen extends StatelessWidget { ... }

@Screen(path: '/character/:id',    name: 'character-detail',
        access: AccessLevel.guest)
class CharacterDetailScreen extends StatefulWidget {
  const CharacterDetailScreen({super.key, @PathParam('id') required this.id});
  final int id;
}
```

### Route parameters

`@PathParam` and `@QueryParam` on **constructor parameters** are extracted by the
generated router. Types `int`, `double` and `bool` are parsed automatically; `String`
is passed as-is. Query params are read from the URL query string.

### Wiring

```dart
class MyApp extends StatelessWidget {
  static final _router = AppRouterConfig();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: _router.onGenerateRoute,
      initialRoute: _router.initialRoute,
    );
  }
}
```

The generated router also produces `namedRoutes` for navigation (`/character/2`),
and `routeConfigs` with per-route ACL (`guest`/`authenticated`/`rolesRequired`/
`permissionsRequired`).

[← Back to README.md](../../README.md)
