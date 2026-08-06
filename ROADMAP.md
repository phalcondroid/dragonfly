# Dragonfly Roadmap

> An opinionated Flutter framework — one annotation set, one code-generator suite.
> Replace freezed, injectable, get_it, retrofit, bloc, and fpdart with a single
> stack.

---

## Vision

Dragonfly exists to reduce the ceremony of building Flutter apps — for both
developers and AI agents. Every feature, annotation, and generated line must
decrease the user's code, complexity, and boilerplate.

**Three design principles:**

0. **Reduce, don't add.** If a feature adds more ceremony than it removes, it
   does not belong.
1. **One source of truth.** One annotation set drives every layer — models,
   repositories, state managers, screens, routing, and DI from a single
   config object.
2. **AI-native.** Every API is designed for deterministic AI code generation —
   minimal parameters, predictable output, no hidden lifecycle.

---

## Current release: `0.1.0` (in development)

**Status:** Pre-release. Three packages (`dragonfly`, `dragonfly_annotations`,
`dragonfly_builder`) at version `0.0.1`. Example app demonstrates the full stack
with a working `characters` component (0 errors).

---

## Feature completion matrix

| Feature | Status | Package | Notes |
|---------|--------|---------|-------|
| `@FactoryModel` — model generation | ✅ Stable | builder | fromJson, toJson, equals, copyWith, contracts |
| `@Field` — serialization control | ✅ Stable | annotations | rename, ignore, convertTo |
| `@Aggregate` — DDD aggregate roots | ✅ Stable | builder | identity equality, sameIdentityAs, isNew |
| `@ValueObject` — immutable values | ✅ Stable | builder | all-field equality |
| `@DomainEvent` — event records | ✅ Stable | builder | marker annotation |
| `@StateModel` — sealed state classes | ✅ Stable | builder | when/maybeWhen, variant subclasses |
| `@StateManager` — StateModel mode | ✅ Stable | builder | `@StateManager(state: X)` with user-defined state |
| `@StateManager` — Easy mode | ✅ Stable | builder | auto-generated sealed state from @Event returns |
| `@Event` — state-emitting methods | ✅ Stable | builder | auto loading/error dispatching |
| `@Event(debounce:/throttle:)` — rate limiting | ✅ Stable | runtime | ActionScheduler-backed |
| `@StateView` — screen-controller binding | ✅ Stable | builder | $Manager flattening mixin |
| `@Repository` — HTTP client generation | ✅ Stable | builder | @Get/@Post/@Put/@Patch/@Delete |
| `@Path/@Query/@Body/@Header` — parameter binding | ✅ Stable | builder | full binding resolution |
| `@Authenticated` — session-aware requests | ✅ Stable | builder + runtime | decorator wrapping any adapter |
| `@Subscribe` — WebSocket streaming | ✅ Stable | builder + runtime | envelope-aware, auto-reconnect |
| `@UseCase` — DI registration | ✅ Stable | builder | contract-free |
| `@InjectableInit` — DI configuration | ✅ Stable | builder | per-component scanning |
| `@RouterConfig` — router generation | ✅ Stable | builder | onGenerateRoute, namedRoutes, ACL |
| `@Screen` — route registration + ACL | ✅ Stable | builder | guest/authenticated/role/permission guards |
| `@FormSchema` — form state generation | ✅ Stable | builder | updateFieldValue, touch, validateAll |
| Validated widgets | 🟡 Stable | runtime | TextField, Dropdown, Checkbox, Switch, Date, Submit |
| `DragonflyContainer` — DI replacement | ✅ Stable | runtime | singletons, factories, scopes, async |
| `DragonflyBaseNetworkAdapter` — pluggable transports | ✅ Stable | runtime | HTTP, WebSocket built-in; gRPC, WebRTC etc. via community |
| `DragonflyAuthenticatedAdapter` — auth decorator | ✅ Stable | runtime | wraps any adapter |
| `DragonflySessionManager` — sessions/ACL | ✅ Stable | runtime | login/logout, roles, permissions |
| `DragonflyLogManager` — structured logging | ✅ Stable | runtime | emoji, correlation IDs, colorized |
| `Either<L, R>` — functional error handling | ✅ Stable | runtime | fold, when, map, tryCatch |
| `controllerTest` — TDD test API | ✅ Stable | runtime | 3-parameter, AI-optimized |
| `ControllerStates` — manual test lifecycle | ✅ Stable | runtime | interleaved act/assert |
| Auth component example | 🔴 Broken | example | 224 errors in `components/auth/` |
| Component barrel files | ✅ Stable | builder | `*.dragonfly.dart` per component |
| Golden tests | 🟡 Partial | test | framework widgets only, no screen integration |

---

## Roadmap phases

### Phase 0 — Stabilize (v0.1.0)

**Goal:** Ship the first pub.dev release with zero known regressions.

- [ ] **Fix auth component** — 224 compile errors in `example/components/auth/`.
  This is the gate for declaring form validation complete (see
  [ADR 0005](docs/adr/0005-form-validation-v2.md)).
- [ ] **Resolve dead annotations** — `@SessionConfig`, field-level
  `@PathParam`/`@QueryParam`. Either wire them or deprecate with migration
  guidance (see [known-gaps.md](docs/ai/known-gaps.md) #1).
- [ ] **Publish to pub.dev** — all three packages following
  [PUBLISHING.md](PUBLISHING.md) workflow.
- [ ] **Verify CI passes on all packages** — current `example` job skips golden
  tags; ensure full suite runs green.

### Phase 1 — Test coverage (v0.2.0)

**Goal:** Framework reliability through comprehensive testing.

- [ ] **Builder integration tests** — verify each generator emits correct output
  for given annotations. Critical gap: no test confirms `@FactoryModel` with
  `toJson: true` actually produces a `toJson()` method.
- [ ] **`DragonflyContainer` unit tests** — registration, resolution, scopes,
  duplicates, reset, async singletons.
- [ ] **`DragonflySessionManager` tests** — login/logout, token injection, ACL
  checks, storage persistence, expired token handling.
- [ ] **`Either<L, R>` unit tests** — fold, when, map, tryCatch, tryCatchAsync,
  edge cases (nested Either, null values).
- [ ] **Form controller tests** — field state tracking, validation, cross-field
  validation.
- [ ] **HTTP adapter tests** — request/response pipeline, error handling,
  header merging, interceptor hooks.
- [ ] **Add code coverage reporting** — `flutter test --coverage` + codecov.io
  integration in CI (free for public repos).
- [ ] **Screen golden tests** — DI-initialized screens with mocked adapters.

### Phase 2 — Documentation (v0.3.0)

**Goal:** Complete, AI-friendly documentation for every feature.

- [ ] **Sessions doc expansion** — storage interface examples, token refresh
  flow, role/permission model, ACL deep dive. Current: 33 lines.
- [ ] **Logging doc expansion** — custom formatters, log filtering, file output,
  structured data conventions. Current: 16 lines.
- [ ] **Routing doc expansion** — deep linking, redirect guards, nested routes,
  transition customization. Current: 56 lines.
- [ ] **Use cases doc expansion** — chaining, error model design, Either
  patterns, pagination. Current: 46 lines.
- [ ] **Code generation pipeline doc** — how builders work, debug techniques,
  common failure modes (from [codegen-pipeline.md](docs/ai/codegen-pipeline.md)).
- [ ] **Adapter-authoring guide** — how to publish a community adapter to
  pub.dev, with the gRPC example as a template.
- [ ] **Migration guide** — from freezed + injectable + retrofit + bloc to
  Dragonfly. Side-by-side code comparisons.

### Phase 3 — Community ecosystem (v0.4.0)

**Goal:** Make Dragonfly extensible and community-driven.

- [ ] **Community adapter packages** — reference implementations for gRPC,
  GraphQL, and MQTT as separate pub.dev packages demonstrating the
  `DragonflyAdapterConfig` pattern.
- [ ] **Adapter test kit** — `AdapterTestHarness` that verifies a community
  adapter fulfills the `DragonflyBaseNetworkAdapter` contract (request/response,
  hooks, lifecycle).
- [ ] **`.github/ISSUE_TEMPLATE/`** — bug report and feature request templates
  with Dragonfly-specific triage questions.
- [ ] **Dependabot configuration** — automated dependency updates for the three
  packages.
- [ ] **Contribution ladder** — `good first issue` labels, maintainer
  documentation for PR review, release checklist.

### Phase 4 — Production maturity (v1.0.0)

**Goal:** A framework you'd bet your startup on.

- [ ] **One-file-per-component code consolidation** — aggregate generated output
  into a single physical file per component, with cross-file import resolution
  (deferred from [ADR 0003](docs/adr/0003-component-layout-and-barrel.md)).
- [ ] **Analyzer toolchain upgrade** — blocked on Flutter SDK shipping
  `meta >=1.18.3`. Track [flutter/flutter#...](https://github.com/flutter/flutter)
- [ ] **Optimistic locking for aggregates** — version-tracking in generated
  `@Aggregate` models, conflict detection in `AggregateRepository.save()`.
- [ ] **Domain event publishing** — generated event bus, event handler
  registration, at-least-once delivery semantics.
- [ ] **Performance benchmarks** — build_runner regression suite, runtime
  benchmark harness for controller dispatch and state emission.
- [ ] **Null safety hardening** — eliminate all implicit dynamic calls in
  generated output (tracked by `strict-casts` / `strict-raw-types` in analysis
  options).
- [ ] **Documentation site** — a dedicated site (similar to Swagger/OpenAPI)
  that renders annotations and generated code interactively.

---

## Known issues tracker

Issues currently tracked in [`docs/ai/known-gaps.md`](docs/ai/known-gaps.md):

| # | Issue | Status | Target |
|---|-------|--------|--------|
| 1 | Dead annotations (`@SessionConfig`, field-level `@PathParam`/`@QueryParam`) | Open | v0.1.0 |
| 5 | One-file-per-component code consolidation | Deferred | v1.0.0 |
| 8 | Flutter SDK `meta` version pin caps `analyzer` at 8.x | Blocked upstream | v1.0.0 |

Resolved gaps: see [known-gaps.md](docs/ai/known-gaps.md) for the full list
(8 of 11 resolved as of 2026-08-06).

---

## Version history

| Version | Date | Highlights |
|---------|------|------------|
| `0.1.0` | (planned) | First pub.dev release, auth fix, dead annotation cleanup |
| `0.2.0` | (planned) | Builder integration tests, runtime unit tests, code coverage |
| `0.3.0` | (planned) | Complete documentation, migration guide, adapter-authoring guide |
| `0.4.0` | (planned) | Community adapters, issue templates, contribution workflow |
| `1.0.0` | (planned) | Code consolidation, analyzer upgrade, DDD maturity, benchmarks, doc site |

---

## How to contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow (GitFlow, commit
conventions, pre-push hooks, PR checklist).

Pick up an open issue or propose a feature by opening an issue with the
**Feature request** template. First-time contributors should look for issues
tagged `good first issue`.

---

## Related docs

- [CONTRIBUTING.md](CONTRIBUTING.md) — development workflow, GitFlow, commit conventions
- [PUBLISHING.md](PUBLISHING.md) — pub.dev release workflow
- [docs/adr/](docs/adr/) — Architecture Decision Records
- [docs/ai/known-gaps.md](docs/ai/known-gaps.md) — tracked issues and resolutions
- [docs/topics/](docs/topics/) — topic-based developer documentation
