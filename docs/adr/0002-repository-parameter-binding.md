# ADR 0002 — Repository parameter binding (@Path/@Query/@Body/@Header/@Authenticated)

**Date:** 2026-08-05
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
`AuthenticatedNetworkAdapter` **extends** it overriding these hooks instead of
duplicating 250 lines of HTTP logic.

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

- `DragonflyNetworkHttpAdapter` is now the base; `AuthenticatedNetworkAdapter extends`
  it (SRP — no duplication).
- Config registers both adapters per connection (interface + authenticated variant).
- `@Path`/`@Query` annotations made positional (`const Path('id')`) to match README
  form.

## References

- `dragonfly/lib/framework/network/adapter/dragonfly_base_network_adapter.dart`
- `dragonfly/lib/framework/session/authenticated_network_adapter.dart`
- `dragonfly_builder/lib/builder/generators/repository_generator.dart`
- `dragonfly_builder/lib/builder/visitor/parameter_helper.dart`
