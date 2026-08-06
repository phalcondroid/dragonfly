# Publishing to pub.dev

This monorepo contains three packages. They are published **separately** to pub.dev but
developed together with `path:` dependencies. The publish order matters:
`dragonfly_annotations` goes first because the other two depend on it.

---

## One-time setup (already done for 0.0.1)

Each package needs these files in good shape before the first publish:

- **`pubspec.yaml`** — `homepage`, `repository`, and `issue_tracker` fields set
- **`CHANGELOG.md`** — real release notes (not the `TODO` placeholder)
- **`LICENSE`** — license text (MIT)

If adding a new major feature or fix, bump the `version` in `pubspec.yaml` and add
a new section to `CHANGELOG.md` **before** publishing.

---

## Step 1 — Publish `dragonfly_annotations`

```bash
cd dragonfly_annotations

# Validate without uploading
dart pub publish --dry-run

# Upload to pub.dev
dart pub publish
```

> Use `dart pub publish` — this is a pure Dart package (no Flutter SDK).

---

## Step 2 — Swap path → hosted dependency

Before publishing `dragonfly` and `dragonfly_builder`, their `dragonfly_annotations`
dependency must point to the live pub.dev package. Edit both pubspecs:

### In `dragonfly/pubspec.yaml`

```yaml
# Change from:
dragonfly_annotations:
  path: ../dragonfly_annotations

# To:
dragonfly_annotations: ^0.0.1
```

### In `dragonfly_builder/pubspec.yaml`

```yaml
# Same change:
dragonfly_annotations:
  path: ../dragonfly_annotations

# To:
dragonfly_annotations: ^0.0.1
```

---

## Step 3 — Publish the other two (order doesn't matter)

```bash
# Pure Dart — uses dart pub publish
cd dragonfly_builder
dart pub publish --dry-run
dart pub publish

# Flutter package — uses flutter pub publish
cd ../dragonfly
flutter pub publish --dry-run
flutter pub publish
```

---

## Step 4 — Restore `path:` for local dev

After publishing, **revert** both pubspecs so the monorepo keeps working:

```yaml
# Back to:
dragonfly_annotations:
  path: ../dragonfly_annotations
```

If you don't revert, `pub get` will fetch the hosted version instead of your local
changes, and you won't be able to develop across packages.

---

## Quick reference

| # | Package | Command | Depends on |
|---|---------|---------|-----------|
| 1 | `dragonfly_annotations` | `dart pub publish` | nothing |
| 2 | `dragonfly_builder` | `dart pub publish` | step 1 |
| 2 | `dragonfly` | `flutter pub publish` | step 1 |

---

## For future releases

1. Bump `version` in the relevant `pubspec.yaml`
2. Add release notes to the relevant `CHANGELOG.md`
3. Follow the same order: annotations first, then swap deps, then publish the rest
4. Revert `path:` dependencies when done

Make sure `dart analyze` / `flutter analyze` passes before every publish.
`pub publish --dry-run` catches most issues before upload.

---

## CI pipeline

On every push and PR to `main`, GitHub Actions runs (free for public repos):

| Job | What it runs |
|-----|-------------|
| `dart-packages` | `dart format`, `dart analyze`, `dart test` on both `dragonfly_annotations` and `dragonfly_builder` |
| `flutter-runtime` | `flutter analyze`, `flutter test` on `dragonfly` |
| `example` | `build_runner build` → `flutter analyze` → `flutter test` (widget + golden) on `example/` |

The workflow file is at `.github/workflows/ci.yaml`.

### Running tests locally

```bash
# Unit & widget tests (all packages)
cd dragonfly_annotations && dart test
cd dragonfly_builder    && dart test
cd dragonfly            && flutter test
cd example              && flutter test

# Example: full build + analyze gate (the real signal)
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze

# Golden tests — regenerate reference images after UI changes
cd dragonfly && flutter test --update-goldens
cd example   && flutter test --update-goldens
```

### Test structure

```
dragonfly/test/
├── dragonfly_test.dart
├── state/
│   ├── state_controller_test.dart        # DragonflyController unit tests
│   └── action_scheduler_test.dart        # ActionScheduler debounce/throttle
├── network/
│   └── web_socket_adapter_test.dart      # WebSocket adapter unit tests
├── goldens/
│   ├── dragonfly_state_builder_golden_test.dart
│   └── *.png                             # Committed reference images
└── test_helpers/
    └── mock_controller.dart              # Reusable mock DragonflyController

example/test/
├── widget_test.dart                      # Integration smoke test (app builds)
├── goldens/
│   ├── example_material_golden_test.dart
│   └── *.png
└── test_helpers/
    └── mock_controller.dart
```

### What's still needed (future work)

- **Builder tests**: Test that each generator emits correct code for given annotations
  (e.g., `@FactoryModel` with `toJson: true` produces a `toJson()` method).
  Currently only a smoke test verifies factory functions exist.
- **Expanded example golden tests**: Test screens like `CharacterScreen` after
  DI container initialization with mocked network adapters.
- **Coverage reporting**: Add `--coverage` and upload to codecov.io (free for public repos).
