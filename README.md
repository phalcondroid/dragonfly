# Dragonfly Framework

An opinionated Flutter framework that replaces your entire pubspec stack — freezed,
injectable, get_it, retrofit, bloc, fpdart, json_serializable — with **one annotation
set and one code-generator suite**. App authors write only models, use cases, state
managers and screens. Everything else is generated.

---

## Packages

| Package | Role | Dependencies |
|---------|------|-------------|
| `dragonfly` | Runtime: DI container, network, state management, session, logging, forms | Flutter SDK |
| `dragonfly_annotations` | Annotation classes only — no logic, no Flutter | `meta` |
| `dragonfly_builder` | `source_gen` builders that read those annotations | `analyzer`, `source_gen`, `build` |

Strict dependency direction:
```
dragonfly_builder ──▶ dragonfly_annotations ◀── dragonfly
                                                    ▲
example ───────────────────────────────────────────┘
```

`dragonfly_builder` must **never** import `package:dragonfly`. It emits references to
runtime types as string literals.

---

## Architecture

Data flows one direction through four layers:

```
Screen (Widget)                @Screen, @StateView + $Manager mixin
    │  dispatch events, rebuild from state
    ▼
State Manager (plain class)    @StateManager, @Event methods returning values
    │  business logic, orchestrates use cases
    ▼
Use Case (plain class)         @UseCase, hand-written call method
    │  data transformation, returns Either<Error, T>
    ▼
Repository (abstract)          @Repository, generated HTTP / realtime client
    │  network calls, model deserialization
    ▼
Network Adapter (runtime)      DragonflyBaseNetworkAdapter — pluggable
                                 (HTTP, WebSocket, gRPC, WebRTC, …)
```

Every layer is generated except the state manager delegate and the use case body.

---

## Getting started

> Full guide: [docs/topics/getting-started.md](docs/topics/getting-started.md)

```yaml
# pubspec.yaml
dependencies:
  dragonfly:
    path: ../dragonfly
  dragonfly_annotations:
    path: ../dragonfly_annotations

dev_dependencies:
  build_runner: ^2.15.0
  dragonfly_builder:
    path: ../dragonfly_builder
```

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze     # the real pass/fail signal — never trust build_runner alone
```

> **Warning:** Nearly every generator swallows its own exceptions
> (`catch (e) { print(...); return ""; }`). `build_runner` reports `Succeeded`
> while writing an **empty or partial file**. `dart analyze` is always the
> gate. Grep the build log for `====>>` to find hidden crashes.

---

## Documentation

| Topic | File |
|-------|------|
| Setup, project layout, build, debugging | [docs/topics/getting-started.md](docs/topics/getting-started.md) |
| `@FactoryModel`, `@Aggregate`, `@ValueObject`, `@DomainEvent` | [docs/topics/models.md](docs/topics/models.md) |
| `@StateModel` — sealed state classes | [docs/topics/state-management.md](docs/topics/state-management.md) |
| `@Repository` — HTTP, realtime, parameter binding | [docs/topics/repositories.md](docs/topics/repositories.md) |
| `@UseCase` and the `Either` type | [docs/topics/usecases.md](docs/topics/usecases.md) |
| `@StateManager`, `@Event`, `@StateView`, `@Screen` | [docs/topics/state-management.md](docs/topics/state-management.md) |
| `@RouterConfig`, routes, ACL | [docs/topics/routing.md](docs/topics/routing.md) |
| DI container, `@UseCase`, `@Injectable`, scopes | [docs/topics/dependency-injection.md](docs/topics/dependency-injection.md) |
| `DragonflyConfig`, `DragonflyApp`, adapter configs | [docs/topics/configuration.md](docs/topics/configuration.md) |
| Network adapters (HTTP, WebSocket, custom/gRPC) | [docs/topics/adapters.md](docs/topics/adapters.md) |
| `@FormSchema`, validators, validated widgets | [docs/topics/forms.md](docs/topics/forms.md) |
| Session manager, ACL, `@Authenticated` | [docs/topics/sessions.md](docs/topics/sessions.md) |
| Structured logging | [docs/topics/logging.md](docs/topics/logging.md) |
| Runtime primitives (`DragonflyController`, `Either`, aggregates) | [docs/topics/runtime.md](docs/topics/runtime.md) |
| Annotations reference, generated files | [docs/topics/reference.md](docs/topics/reference.md) |

> See also: [CONTRIBUTING.md](CONTRIBUTING.md), [PUBLISHING.md](PUBLISHING.md), [ADRs](docs/adr/)
