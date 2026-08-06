# Logging

`DragonflyLogManager.instance` provides structured logging with emoji icons,
duration tracking, request/response correlation IDs, and colourised output:

```dart
final log = DragonflyLogManager.instance;

log.info('User logged in', source: 'AuthManager', data: {'userId': 42});
log.error('Network timeout', error: e, stackTrace: s, source: 'Repo');
```

Generated repositories and controllers log automatically when the annotation
sets `logging: true`.

[Back to README](../../README.md)
