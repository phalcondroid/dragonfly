## 0.0.1

* Initial release — runtime library for the Dragonfly Flutter framework.
* Dependency injection container (`DragonflyContainer`) with singleton, lazy-singleton, factory, and scoped registrations.
* Networking (`DragonflyBaseNetworkAdapter`) with HTTP and WebSocket support, authenticated adapter, and session token injection.
* State management controller (`DragonflyController`) with synchronous state access, broadcast streams, and rate limiting (`ActionScheduler`).
* DDD primitives (`AggregateRoot<T>`, `AggregateRepository<T>`, `DomainEvent`, `AggregateException`).
* Functional `Either<L, R>` type with `fold`, `when`, `map`, `tryCatch`, and `tryCatchAsync`.
* Form state management with `DragonflyFormFieldState` and validated widgets (`ValidatedTextField`, `ValidatedDropdown`, etc.).
* Session manager (`DragonflySessionManager`) with role/permission-based ACL, login/logout, and persistence via `SessionStorage`.
* Structured logging (`DragonflyLogManager`) with levels, emoji icons, duration tracking, and request correlation IDs.
* Navigation extensions for generated routers.
