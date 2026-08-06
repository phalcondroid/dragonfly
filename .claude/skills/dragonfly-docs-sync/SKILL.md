---
name: dragonfly-docs-sync
description: After ANY change to the Dragonfly framework — annotations, runtime, builder,
  generators, example, or config — update the corresponding documentation artifacts
  so AI agents and users always see reality. This skill fires automatically when
  you modify framework code; it is the single source of truth for "what docs exist
  and when to update them."
---

# Documentation-sync — the rule

Every change to the Dragonfly framework **must** update the documentation that
describes it. The framework has two audiences — AI agents (`.claude/`,
`docs/ai/`, `AGENTS.md`, `CLAUDE.md`) and human users (`README.md`,
`dragonfly/ai/skills/dragonfly-app/SKILL.md`, `example/README.md`) — and both
must stay in sync with the source code. An outdated doc is a bug.

## The checklist (run after every change)

### 1. Framework developer docs (agent-facing)

| Artifact | When to update |
|----------|---------------|
| `CLAUDE.md` | Changed a naming convention, a hard rule, the environment, the repository layout, or the build/verify commands |
| `AGENTS.md` | Same as `CLAUDE.md` — it is the tool-agnostic mirror; keep them identical in substance |
| `docs/ai/architecture.md` | Changed the runtime layer: DI, network, state management, session, router, logging, forms, or bootstrap |
| `docs/ai/codegen-pipeline.md` | Added/removed/renamed a builder or generator, changed how `build.yaml`/`builder.dart` wiring works, changed the visitor or emission patterns |
| `docs/ai/annotation-matrix.md` | Added, removed, renamed, or changed what an annotation produces — including making a dead annotation live or vice versa |
| `docs/ai/known-gaps.md` | Fixed a gap, discovered a new one, or changed an error count |
| `.claude/skills/dragonfly-codegen/SKILL.md` | Changed how generators work or what rules codegen changes must follow |
| `.claude/skills/dragonfly-build-debug/SKILL.md` | Changed the build/analyze flow, error messages, or diagnostic patterns |
| `.claude/skills/dragonfly-runtime/SKILL.md` | Changed the runtime API surface, subsystem cautions, or the deprecation/deletion pattern |
| `.claude/skills/dragonfly-docs-sync/SKILL.md` | Changed the documentation landscape itself (new doc files, renamed artifacts, new checklist items) |
| `.claude/agents/dragonfly-generator-dev.md` | Changed the generator-dev agent's scope, rules, or verification steps |
| `.claude/agents/dragonfly-runtime-dev.md` | Changed the runtime-dev agent's scope, rules, or verification steps |

### 2. Consumer docs (user-facing)

| Artifact | When to update |
|----------|---------------|
| `README.md` | Changed any public API — annotations, runtime types, the project layout, build commands, configuration, or added/removed a subsystem |
| `dragonfly/ai/skills/dragonfly-app/SKILL.md` | Changed anything a consumer app's AI agent would need to know: annotation shapes, layer conventions, generated output names, form patterns, DI registration rules, known limitations |
| `dragonfly/ai/README.md` | Changed the bundle structure, installation instructions, or the contents list |
| `example/README.md` | Changed the example app's structure, the components it demonstrates, or the verification commands |

### 3. Routing rule

| Artifact | Rule |
|----------|------|
| `AppConfig` subclass | `@RouterConfig()` must be on the `DragonflyConfig` subclass — the same class that declares `adapters`, `instanceConfigs`, `realtimeConfigs`, and `injector`. Never create a separate `router_config.dart` file. The generated `.router.dart` is imported (not `part`-ed). `main.dart` passes the config instance to both `DragonflyApp.init()` and `MaterialApp`. |

### 4. Example (integration test)

| Artifact | When to update |
|----------|---------------|
| `example/lib/**/*.dart` | The example is the only integration test. Any API change must be exercised in the `characters` or `auth` components — or a new component if the feature is standalone. Regenerate and verify `dart analyze` reports 0 errors across the entire `example/` package |

### 4. Verification — the final gate

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
dart analyze 2>&1 | grep "error -" | wc -l   # must be 0

cd ../dragonfly
flutter analyze && flutter test

cd ../dragonfly_annotations
flutter analyze && dart test

cd ../dragonfly_builder
flutter analyze && dart test
```

If the error count changed, update the baseline in `docs/ai/known-gaps.md` and
`CLAUDE.md`/`AGENTS.md`.

## How it fires

This skill's `description` matches on broad framework-change intent: "change",
"update", "add", "remove", "fix", "refactor", "rename", "delete" combined with
framework terms. It fires alongside the domain-specific skills
(`dragonfly-codegen`, `dragonfly-runtime`, `dragonfly-build-debug`) so the
checklist is always in context.

## Hard rules

- **Don't defer doc updates.** "I'll update the docs later" is how drift starts.
  Every commit that changes framework behaviour must include the doc update in
  the same change.
- **Trust the source, not the docs.** If `README.md` and source disagree, the
  source wins — but that disagreement must be recorded in `known-gaps.md` or
  fixed immediately. Never let a verified discrepancy linger undocumented.
- **Verification commands in docs must be reproducible.** Every doc that
  includes a shell command (`grep`, `dart analyze`, `build_runner`) must have
  commands that actually run and produce the stated output. If you change an
  error count, grep count, or command flag, update the doc.
- **Generated files are not the source of truth.** Never update docs based on
  reading a generated file alone — read the generator that produced it. The doc
  describes what the generator emits, not what one specific output looks like.
