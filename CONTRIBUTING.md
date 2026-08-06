# Contributing to Dragonfly

## GitFlow branching model

```
main        ◄── stable, tagged releases only
  │
develop     ◄── integration branch, all PRs merge here
  │
  ├── feature/name       — new features and non-urgent fixes
  ├── release/x.y.z      — release candidates (freeze, QA, merge to main)
  └── hotfix/name        — urgent production fixes (branches from main)
```

### Branch naming

| Prefix    | Purpose                          | Example                          |
|-----------|----------------------------------|----------------------------------|
| `feature/`| New features and enhancements    | `feature/add-golden-tests`       |
| `fix/`    | Bug fixes merged into develop    | `fix/either-null-stacktrace`     |
| `release/`| Release candidates               | `release/0.1.0`                  |
| `hotfix/` | Urgent production fixes          | `hotfix/session-token-leak`      |
| `docs/`   | Documentation only               | `docs/api-reference-update`      |
| `ci/`     | CI / pipeline changes            | `ci/add-code-coverage`           |

### Workflow

1. Create a branch from `develop`: `feature/my-feature`
2. Work, commit, push — keep PRs small and focused
3. Open a PR to `develop`
4. CI must pass: format, analyze, build_runner, tests, golden tests
5. At least one reviewer approves
6. Squash-merge into `develop`
7. To release: branch `release/x.y.z` from `develop`, finalize, PR to `main`

### Branch protection (set in GitHub repo settings)

- `main`: require PR, require status checks, require approvals, no force-push
- `develop`: require PR, require status checks, no force-push

---

## Commit conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
type(scope): description

[optional body]

[optional footer]
```

### Types

| Type       | Use when                                           |
|------------|----------------------------------------------------|
| `feat`     | New feature or annotation                          |
| `fix`      | Bug fix                                            |
| `docs`     | Documentation only                                 |
| `style`    | Formatting, missing semicolons, whitespace         |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test`     | Adding or fixing tests                             |
| `chore`    | Maintenance, dependency bumps, build tasks         |
| `perf`     | Performance improvement                            |
| `ci`       | CI/CD configuration changes                        |
| `build`    | Build system or external dependencies              |
| `revert`   | Reverts a previous commit                          |

#### Breaking changes

Add `!` after the scope or a `BREAKING CHANGE:` footer:

```
feat(builder)!: remove deprecated @InjectableUseCase

BREAKING CHANGE: @InjectableUseCase has been removed. Use @UseCase instead.
```

### Scopes

| Scope         | Applies to                              |
|---------------|-----------------------------------------|
| `annotations` | `dragonfly_annotations` package         |
| `builder`     | `dragonfly_builder` package             |
| `runtime`     | `dragonfly` runtime library             |
| `example`     | `example/` app                          |
| `ci`          | CI/CD, GitHub Actions, hooks            |
| `docs`        | Documentation, README, comments         |
| `deps`        | Dependency updates                      |
| `release`     | Version bumps, changelog                |

### Examples

```
feat(builder): add sealed class visitor for @StateModel
fix(runtime): handle null in Either.fold
docs: add CONTRIBUTING.md
ci: add golden test job to pipeline
test(runtime): add ActionScheduler.dispose unit tests
chore(deps): bump analyzer to ^8.5.0
```

The commit message is validated by a git hook (`.githooks/commit-msg`) and on CI.

---

## Git hooks

Managed by [lefthook](https://github.com/evilmartians/lefthook) (`lefthook.yml`).

| Hook       | What runs                                | Bypass with         |
|------------|------------------------------------------|---------------------|
| pre-commit | `dart format --set-exit-if-changed`      | `git commit --no-verify` |
| commit-msg | Conventional commit format check         | (can't bypass)      |
| pre-push   | `dart analyze`, `dart test`, `flutter test` | `git push --no-verify` |

Install hooks:

```bash
bash tool/setup.sh
```

---

## Code style

All packages share a root `analysis_options.yaml` with strict rules:

- **Strict type system**: `strict-casts`, `strict-inference`, `strict-raw-types`
- **No dynamic calls**: `avoid_dynamic_calls`
- **Const everywhere**: `prefer_const_constructors`, `prefer_const_declarations`
- **Single quotes**: `prefer_single_quotes`
- **Trailing commas**: `require_trailing_commas`
- **Sorted constructors**: `sort_constructors_first`
- **No print statements**: `avoid_print` (use `DragonflyLogManager` instead)
- **Types on public API**: `always_declare_return_types`

Generated files (`*.model.dart`, `*.state.dart`, etc.) are excluded from analysis.

---

## Pull request checklist

Before opening a PR:

- [ ] Branch is up to date with `develop`
- [ ] All commits follow Conventional Commits
- [ ] `dart format` passes (pre-commit hook catches this)
- [ ] `dart analyze` / `flutter analyze` passes on all changed packages
- [ ] Tests pass on all changed packages
- [ ] For builder changes: `build_runner build` + analyze on `example/` passes
- [ ] Golden test images regenerated if UI changed: `flutter test --update-goldens`
- [ ] `CHANGELOG.md` updated for user-facing changes
- [ ] `pubspec.yaml` version bumped if needed
- [ ] Documentation updated (README, doc comments, `docs/`)
