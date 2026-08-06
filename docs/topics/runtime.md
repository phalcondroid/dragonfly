# Runtime primitives

The foundation classes that generated code builds on top of — controllers,
state-builder widgets, and DDD primitives.

### `DragonflyController<S>`

The base class for all generated controllers. You never subclass it directly.
Provides:
- `state` — the current state, read synchronously
- `stream` — broadcast stream backing every `DragonflyStateBuilder`
- `emit(S)` — `@protected`; only generated code calls it
- `schedule(key, body, {debounce, throttle})` — rate-limiting backed by `ActionScheduler`
- `dispose()` — idempotent; closes the stream, cancels pending actions
- `loggingEnabled` — overridden by the generated subclass when `logging: true`

### `DragonflyStateBuilder<S>`

The widget every generated view-mixin builder returns. Reads the controller's
current state synchronously on creation (first frame is real state, not a blank),
then rebuilds from the stream, gated by an optional `buildWhen`:

```dart
DragonflyStateBuilder<CharacterState>(
  controller: myController,
  buildWhen: (prev, curr) => prev is! CharacterStateLoading,
  builder: (context, state) => state.maybeWhen(
    loading: () => const Spinner(),
    orElse: () => const SizedBox.shrink(),
  ),
)
```

### `AggregateRoot<T>` (`framework/ddd/`)

The contract interface for aggregate-root entities. Generated `@Aggregate` models
implement this automatically: `T get identity`, `bool get isNew`, and
`bool sameIdentityAs(Object other)`.

### `AggregateRepository<T>`

Base repository contract with `findById`, `save`, and `delete`. Implement the
methods in your `@Repository` abstract class and the generator wires the calls —
`isNew` determines POST vs PUT for `save`.

### `DomainEvent`

Marker interface for domain event records.

[Back to README](../../README.md)
