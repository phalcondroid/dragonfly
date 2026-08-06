# ADR 0002 — Repository parameter binding (@Path/@Query/@Body/@Header/@Authenticated)

**Date:** 2026-08-05
**Amended:** 2026-08-06 (pluggable adapter system)
**Status:** Accepted
**Deciders:** Gap-fix pass (see `docs/ai/known-gaps.md` #2)

## Context

`RepositoryGenerator.buildHttpMethod` hardcoded `null` for both the `params` and
`options` arguments to the network adapter. `@Path`, `@Query`, `@Body`, `@Header`,
and `@Authenticated` were exported by `dragonfly_annotations` but **no generator
read them**. This was the most consequential gap in the framework — every `@Post`,
`@Put`, and `@Patch` sent an empty body, every `@Get(path: '/{id}')` sent the
literal `{id}` to the server, and `@Authenticated` did nothing.

## Decision

**Wire all five binding annotations** through the generator, with a richer runtime
API that separates query, body, and headers instead of the old single `Map?` params
argument.

### Runtime — new request API

`DragonflyBaseNetworkAdapter` gained `requestObject`/`requestList` methods with
separate `{query, body, headers}` named parameters. The old `callForObject`/`callForList`
delegate to the new methods (query for GET/DELETE, body for POST/PUT/PATCH).

`DragonflyNetworkHttpAdapter` was refactored with protected hooks —
`buildHeaders(Map<String,String>?)`, `beforeRequest()`, `afterResponse()` — so that
`AuthenticatedNetworkAdapter` could override them without duplicating
250 lines of HTTP logic. *[Amended 2026-08-06: the hooks now live on
`DragonflyBaseNetworkAdapter`, and `DragonflyAuthenticatedAdapter` wraps any adapter
as a decorator rather than extending the HTTP one. See Amendment below.]*

### Generator

| Annotation | Emitted |
|-----------|---------|
| `@Path('name')` | Substitutes `{name}` with `${name}` in the path template |
| `@Query('name')` | Builds a `{'name': name}` query map; unannotated params default to query |
| `@Body()` | Single model param emits `param.toJson()`; multiple merge by name into a map |
| `@Header(item:)` | Merges static entries with method-level `@Get(headers:)` into a headers map |
| `@Authenticated()` | Resolves `'<conn>:authenticated'` adapter name instead of `'<conn>'` |

`@Subscribe` params pass a real map instead of `const <String, dynamic>{}`.

## Consequences

- `DragonflyNetworkHttpAdapter` is now the HTTP base; `DragonflyAuthenticatedAdapter`
  wraps any `DragonflyBaseNetworkAdapter` as a decorator (SRP — no duplication).
  *[Amended 2026-08-06: originally `AuthenticatedNetworkAdapter` extended
  `DragonflyNetworkHttpAdapter`; the current decorator pattern makes authentication
  transport-agnostic.]*
- Config registers both adapters per connection via `DragonflyHttpAdapterConfig`
  (interface + authenticated variant). The pluggable `DragonflyAdapterConfig` system
  lets community adapters register themselves the same way.
- `@Path`/`@Query` annotations made positional (`const Path('id')`) to match README
  form.

## References

- `dragonfly/lib/framework/network/adapter/dragonfly_base_network_adapter.dart`
- `dragonfly/lib/framework/session/authenticated_network_adapter.dart`
- `dragonfly/lib/framework/config/dragonfly_config.dart`
- `dragonfly_builder/lib/builder/generators/repository_generator.dart`
- `dragonfly_builder/lib/builder/visitor/parameter_helper.dart`

## Amendment — Pluggable adapter system (2026-08-06)

The original decision had `AuthenticatedNetworkAdapter` extending
`DragonflyNetworkHttpAdapter` via inheritance. This worked for HTTP but made
authentication unavailable for other transport types.

The amendment introduces three changes:

1. **Hook methods on the base interface.** `beforeRequest()`, `afterResponse()`,
   and `buildHeaders()` were moved from `DragonflyNetworkHttpAdapter` up to
   `DragonflyBaseNetworkAdapter` with no-op defaults.

2. **Decorator instead of inheritance.** `DragonflyAuthenticatedAdapter` is a
   standalone class that wraps any `DragonflyBaseNetworkAdapter` — HTTP,
   WebSocket, or custom (WebRTC, gRPC, etc.). The old `AuthenticatedNetworkAdapter`
   (which extends `DragonflyNetworkHttpAdapter`) is kept as a deprecated alias.

3. **Pluggable config system.** `DragonflyAdapterConfig` is an abstract class
   with a single method `initConfig(DragonflyContainer)`. Community adapters
   subclass it and are added to `DragonflyConfig.adapters`. Built-in subclasses
   (`DragonflyHttpAdapterConfig`, `DragonflyWebSocketAdapterConfig`) replace
   the deprecated `DragonflyInstanceConfig` / `DragonflyRealtimeInstanceConfig`.
