---
name: Bug report
about: Report a bug in the Dragonfly framework
title: '[BUG] '
labels: bug
assignees: ''
---

### Describe the bug

A clear and concise description of what the bug is.

### To Reproduce

Steps to reproduce the behavior:
1. Create a `@Repository` / `@StateManager` / `@FactoryModel` class with '...'
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Run `dart analyze`
4. See error

### Expected behavior

A clear and concise description of what you expected to happen.

### Actual output

```
Paste the generated code, analysis error, or stack trace here.
```

### Which package?

- [ ] `dragonfly` (runtime)
- [ ] `dragonfly_annotations`
- [ ] `dragonfly_builder` (code generation)

### Environment

- Dragonfly version: `0.0.1`
- Dart SDK version: `dart --version`
- Flutter SDK version: `flutter --version` (if applicable)
- OS: [e.g. Ubuntu 24.04, macOS 15]

### Additional context

Add any other context about the problem here — related annotations,
`analysis_options.yaml` overrides, custom adapter configs, etc.
