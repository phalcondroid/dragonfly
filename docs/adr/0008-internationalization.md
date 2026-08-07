# ADR 0008 — Internationalization (i18n) adapter system

**Date:** 2026-08-06
**Status:** Accepted
**Deciders:** Feature implementation following Dragonfly philosophy

## Context

Dragonfly needs an internationalization (i18n) system that:

1. Follows the **adapter pattern** established by network adapters (ADR 0002)
   — a common interface with pluggable implementations.
2. Supports **traditional formats** (.arb, .json) as built-in adapters.
3. Allows **custom adapters** — community can read translations from a web API,
   database, CMS, or any other source.
4. Respects the **Dragonfly philosophy** (AGENTS.md Rule 0): reduce boilerplate,
   no unnecessary ceremony, AI-friendly API.
5. Uses **only Flutter/Dart SDK dependencies** — no pub.dev packages required.

## Decision

**Adapter pattern for i18n, identical to network adapters.**

```
DragonflyI18nAdapter        ← abstract contract
    │
    ├── DragonflyArbAdapter   ← built-in: ARB files (Flutter native format)
    ├── DragonflyJsonAdapter  ← built-in: JSON key-value files
    └── CustomHttpAdapter     ← community: REST API translations
```

**Integration with DragonflyConfig:**

`DragonflyI18nAdapterConfig extends DragonflyAdapterConfig` — same pattern as
`DragonflyHttpAdapterConfig`. Declared in `DragonflyConfig.adapters`.

**Typed access via generated code (`@I18n`):**

A `@I18n` annotation on the config class triggers code generation that produces
typed Dart getters for every translation key. This eliminates magic strings and
provides IDE autocomplete:

```dart
@I18n()
class AppI18n extends _$AppI18n {}

// Generated:
// class _$AppI18n extends DragonflyI18n {
//   String get helloWorld => translate('helloWorld');
//   String pageTitle(int page) => translate('pageTitle', args: {'page': '$page'});
// }

// Usage:
Text(AppI18n.of(context).helloWorld);
```

**Runtime resolution:**

`DragonflyI18n extends LocalizationsDelegate` — integrates with Flutter's
`Localizations` widget so locale changes automatically rebuild the widget tree.

### Why not `gen_l10n` or `package:intl`?

- `gen_l10n` requires `package:intl` (a pub.dev dependency) and generates
  code that imports it in every file.
- `package:intl` adds DateFormat/NumberFormat/plural weight for a purpose
  (string translation) that doesn't need it.
- Dragonfly's adapter system is strictly more powerful — you can swap
  translation sources without changing a single line of UI code.
- Dragonfly avoids pub.dev dependencies that are not from the Dart/Flutter SDK
  (AI file rule: "you don't have to use packages if is not verified or is not
  from flutter or dart").

### Translation file format support

| Format | Adapter | Key interpolation | Plural support | Metadata |
|--------|---------|------------------|----------------|----------|
| ARB | `DragonflyArbAdapter` | `{param}` | ICU plural syntax | `@key.description`, `@key.placeholders` |
| JSON | `DragonflyJsonAdapter` | `{param}` | Not yet | None |

ARB is the preferred format because it is Flutter's native format and supports
ICU plurals out of the box.

### Custom adapter example

```dart
class LokaliseApiAdapter extends DragonflyI18nAdapter {
  LokaliseApiAdapter({required this.apiKey, required this.projectId});

  @override
  Future<Map<String, String>> load(Locale locale) async {
    final response = await http.get(
      Uri.parse('https://api.lokalise.com/api2/projects/$projectId/translations/${locale.languageCode}'),
      headers: {'X-Api-Token': apiKey},
    );
    return parseResponse(response.body);
  }

  @override
  bool supports(Locale locale) => true;
}
```

## Consequences

- All i18n adapters implement `DragonflyI18nAdapter`. The runtime resolves
  translations via `DragonflyI18n.of(context)` which delegates to the
  active adapter registered in `DragonflyConfig`.
- `@I18n` generates a typed wrapper per config class. The generator is a
  `source_gen` builder that scans `.arb`/`.json` files and emits Dart code.
- Custom adapters can be published as separate pub.dev packages
  (`dragonfly_lokalise_adapter`, `dragonfly_crowdin_adapter`).
- Zero pub.dev dependencies beyond `flutter` SDK. The system uses only
  `dart:convert` for JSON/ARB parsing and `package:flutter` for
  `LocalizationsDelegate` integration.

## References

- `dragonfly/lib/framework/i18n/dragonfly_i18n_adapter.dart`
- `dragonfly/lib/framework/i18n/dragonfly_arb_adapter.dart`
- `dragonfly/lib/framework/i18n/dragonfly_json_adapter.dart`
- `dragonfly/lib/framework/i18n/dragonfly_i18n.dart`
- `dragonfly_annotations/lib/annotations/i18n/i18n.dart`
- [ADR 0002](0002-repository-parameter-binding.md) — adapter pattern precedent
- [AGENTS.md](../../AGENTS.md) — Dragonfly philosophy (Rule 0)
