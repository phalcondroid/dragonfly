# Dragonfly Demo

A Flutter app that serves as the de-facto integration test for the
[Dragonfly framework](https://github.com/nodelorien/dragonfly). Two components
demonstrate the full v2 state-management API:

## Characters (`/`)

StateModel-mode state manager (`CharacterStateManager`) bound to a sealed
`@StateModel` class (`CharacterState`). The main screen uses `when(...)` for
exhaustive state matching; the alternative screen (`/character-alt`) demonstrates
typed `build<Variant>` builders and the string-keyed `buildFor` escape hatch.

- **`CharacterDetailScreen`** (`/character/:id`) — mixed in on a `StatefulWidget`'s
  `State` class with `@PathParam`, dispatching a fetch in `initState`.

An easy-mode state manager (`CharacterSearchStateManager`, `/search`) shows
state-class generation from `@Event` methods — the search field is debounced at
300 ms in the generated controller.

## Auth (`/login`)

Form-validation demo on the v2 API: every `@Event` returns the next `LoginState`.
The generated `LoginFormState` manages field values and on-change/on-blur/full
validation. The query-string keyed escape hatch, and the component barrel.

## Build and verify

```bash
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

`dart analyze` is the real pass/fail. `build_runner` reports success even when
a generator wrote an empty file on error — grep the build log for `====>>` and
always analyze after generating.
