---
name: Feature request
about: Propose a new feature or enhancement for Dragonfly
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

### Problem statement

What problem does this feature solve? Is it related to boilerplate reduction,
a missing integration, or a developer experience gap?

### Proposed solution

Describe the feature you'd like. For example:
- A new annotation like `@GraphQL` or `@Paginated`
- A new generated file (`.http.dart`, `.grpc.dart`)
- A runtime utility or widget

```dart
// Show example usage of the proposed API
@MyNewAnnotation()
abstract class MyRepository { ... }
```

### Does this follow the Dragonfly philosophy?

- [ ] Reduces boilerplate / ceremony (Rule 0: Reduce, don't add)
- [ ] Integrates with existing annotations (`@Repository`, `@StateManager`, etc.)
- [ ] Generates code rather than requiring hand-written plumbing
- [ ] Works for AI agents (deterministic, few parameters, predictable output)

### Alternatives considered

Are there workarounds today? What would a user do without this feature?

### Additional context

Links to similar features in other frameworks, prior art, or design documents.
