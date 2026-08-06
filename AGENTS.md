# AGENTS.md

Instructions for AI coding agents working on the **Dragonfly framework** (this repo).
Tool-agnostic mirror of `CLAUDE.md`; that file and `docs/ai/` hold the full detail.

## Philosophy — the framework's reason to exist

0. **Reduce, don't add.** Every feature, annotation, and generated line must decrease
   the user's code, complexity, and boilerplate. If a feature adds more ceremony than
   it removes, it does not belong. The framework exists to make building Flutter apps
   **easier for both developers and AI agents** — strong architecture, nice performance,
   zero unnecessary ceremony.

## What this repo is

A Flutter framework that replaces the usual stack (freezed, injectable, get_it, retrofit,
bloc, fpdart) with one annotation set and one code generator suite, so that app authors
write only use cases and UI. Three published packages plus an example app:

| Path                     | Role                                                        |
| ------------------------ | ----------------------------------------------------------- |
| `dragonfly/`             | Runtime: DI container, network, state management, session   |
| `dragonfly_annotations/` | Annotation classes only — no logic                          |
| `dragonfly_builder/`     | `source_gen` builders that read those annotations           |
| `example/`               | Flutter app; the de-facto integration test for the builders |

`dragonfly_builder` must never import `package:dragonfly`. It emits references to
runtime types as strings.

## Build and verify

```bash
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

**`build_runner` reporting success proves nothing.** Generators swallow their own
exceptions (`catch (e) { print(...); return ""; }`) and emit empty output on failure
while the build still reports `Succeeded`. `dart analyze` is the real signal. Always
run it after generating, and read the generated file to confirm it has real content.

## Rules

1. **Never hand-edit generated files.** `*.model.dart`, `*.state.dart`,
   `*.repository.dart`, `*.form.dart`, `*.state_manager.dart`, `*.view.dart`,
   `*.config.dart`, `*.router.dart`, `*.dragonfly.dart`. Fix the generator instead.
2. **A new generator must be registered twice** — in `dragonfly_builder/lib/builder.dart`
   *and* in `dragonfly_builder/build.yaml`. Miss either and it silently never runs.
3. **Export new runtime types** from `dragonfly/lib/dragonfly.dart`. That barrel uses
   explicit `show` clauses, so an unexported type is invisible to consumers.
4. **State management is v2 only.** `@StateManager` on a plain class (no base class),
   `@Event` methods returning values (never `emit`), `@StateView(Manager)` widgets with
   the `$Manager` mixin. The old `StateManager<S>`/`Feature` stack, `framework/bloc/`,
   `@StateAction`, `@EventModel` and friends were deleted in a clean break — do not
   reintroduce them. Renamed annotations (`@UseCase`, `@InjectableInit`, `@Screen`,
   `@SessionConfig`, `@RouterConfig`) keep live deprecated aliases; never emit the old
   names in new code.
5. **The historical typos were fixed in August 2026** — `MetadataExtractor`,
   `repository/`, `inject.dart`, `unknown`. If you encounter the old spellings
   in legacy references, update them. Do not reintroduce the old spellings.
6. **Routing lives on the config class.** `@RouterConfig()` goes on the `DragonflyConfig` subclass — never in a separate file. One config object delivers DI, network, session, and routing.

7. **Trust the source over `README.md`.** The README documents an API that in several
   places does not exist. `docs/ai/known-gaps.md` lists every verified discrepancy.
8. **Every change updates the docs.** After any framework change, run the
   checklist in `.claude/skills/dragonfly-docs-sync/SKILL.md`. Documentation is
   not optional — an outdated doc is a bug. The change isn't done until all
   affected docs match the new reality and the full verification gate passes.

## Current state

- `example/`'s `characters` component builds and analyzes clean (**0 errors**) — the
  reference implementation, demonstrating both state-manager modes
  (`CharacterStateManager` StateModel mode, `CharacterSearchStateManager` easy mode).
- `example/`'s `auth` component (form validation) does **not** compile (224 errors,
  confined to `components/auth`). Known broken.
- `analyzer` is capped at 8.x because the Flutter SDK pins `meta 1.18.0` (see
  `CLAUDE.md` "Environment").

## Network adapter architecture (pluggable since Aug 2026)

Network adapters follow an ORM-dialect pattern — a common interface with
pluggable implementations. Built-in adapters handle HTTP and WebSocket;
the community can add WebRTC, gRPC, GraphQL, MQTT, etc.

### Core types

| Type | File | Role |
|------|------|------|
| `DragonflyBaseNetworkAdapter` | `framework/network/adapter/dragonfly_base_network_adapter.dart` | Abstract contract: `requestObject`, `requestList`, `callForList`, `callForObject` + hooks (`beforeRequest`, `afterResponse`, `buildHeaders`) + lifecycle (`connect`, `disconnect`) |
| `DragonflyRealtimeAdapter` | `framework/network/adapter/dragonfly_realtime_adapter.dart` | Streaming contract: `subscribeToObject`, `subscribeToList`, `publish` |
| `DragonflyNetworkHttpAdapter` | `framework/network/adapter/dragonfly_network_http_adapter.dart` | HTTP transport (implements `DragonflyBaseNetworkAdapter`) |
| `DragonflyWebSocketAdapter` | `framework/network/adapter/dragonfly_web_socket_adapter.dart` | WebSocket transport (implements `DragonflyRealtimeAdapter`) |
| `DragonflyAuthenticatedAdapter` | `framework/session/authenticated_network_adapter.dart` | Generic decorator wrapping any `DragonflyBaseNetworkAdapter` to inject auth |
| `DragonflyAdapterConfig` | `framework/config/dragonfly_config.dart` | Abstract base for adapter configs — users subclass to register custom adapters |
| `DragonflyHttpAdapterConfig` | `framework/config/dragonfly_config.dart` | Registers HTTP + authenticated adapters |
| `DragonflyWebSocketAdapterConfig` | `framework/config/dragonfly_config.dart` | Registers WebSocket adapter |

### How adapters are resolved

Generated repositories resolve adapters from the DI container by type + name:
- HTTP methods → `DragonflyContainer.I.get<DragonflyBaseNetworkAdapter>(instanceName: connectionName)`
- `@Authenticated` methods → `instanceName: '$connectionName:authenticated'`
- `@Subscribe` methods → `DragonflyContainer.I.get<DragonflyRealtimeAdapter>(instanceName: realtimeConnection)`

### Registering a custom adapter

```dart
class WebRTCAdapterConfig extends DragonflyAdapterConfig {
  final String connectionName;
  const WebRTCAdapterConfig({required this.connectionName});

  @override
  void initConfig(DragonflyContainer container) {
    container.registerSingleton<DragonflyBaseNetworkAdapter>(
      WebRTCAdapter(),
      instanceName: connectionName,
    );
  }
}

// In AppConfig:
@override
List<DragonflyAdapterConfig> get adapters => [
  DragonflyHttpAdapterConfig(...),
  WebRTCAdapterConfig(connectionName: 'webrtc'),
];
```

### Migration from deprecated config

| Old (deprecated) | New (preferred) |
|---|---|
| `DragonflyInstanceConfig` | `DragonflyHttpAdapterConfig` |
| `DragonflyRealtimeInstanceConfig` | `DragonflyWebSocketAdapterConfig` |
| `config.instanceConfigs` | `config.adapters` |
| `config.realtimeConfigs` | `config.adapters` |
| `AuthenticatedNetworkAdapter` | `DragonflyAuthenticatedAdapter` (for custom adapters) |

See `example/lib/components/characters/config/app_config.dart` for the new pattern.

A complete gRPC adapter example is in `docs/topics/adapters.md`.

Details: `docs/ai/known-gaps.md`.
