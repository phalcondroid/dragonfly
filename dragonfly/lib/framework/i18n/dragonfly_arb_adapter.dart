import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';

import 'dragonfly_i18n_adapter.dart';

/// Loads translations from ARB (Application Resource Bundle) files.
///
/// ARB is Flutter's native translation format. Files are JSON with `@`-prefixed
/// metadata keys:
///
/// ```json
/// {
///   "helloWorld": "Hello World",
///   "@helloWorld": { "description": "Greeting shown on the home page" },
///   "pageTitle": "Page {page}",
///   "@pageTitle": { "placeholders": { "page": { "type": "int" } } }
/// }
/// ```
///
/// Placeholder interpolation uses `{param}` syntax. ICU plurals are parsed
/// from `=N{...}`, `one{...}`, `other{...}` syntax per the ARB spec.
class DragonflyArbAdapter extends DragonflyI18nAdapter {
  DragonflyArbAdapter({
    this.path = 'assets/i18n',
    this.templateLocale = const Locale('en'),
    List<Locale> supportedLocales = const [Locale('en')],
  }) : _supported = {for (final l in supportedLocales) l.languageCode};

  final String path;
  final Locale templateLocale;
  final Set<String> _supported;

  @override
  bool supports(Locale locale) =>
      _supported.contains(locale.languageCode);

  @override
  Future<Map<String, String>> load(Locale locale) async {
    final filePath = '$path/app_${locale.languageCode}.arb';
    final data = await rootBundle.loadString(filePath);
    final raw = json.decode(data) as Map<String, dynamic>;
    final strings = <String, String>{};

    for (final entry in raw.entries) {
      if (entry.key.startsWith('@')) continue;
      strings[entry.key] = entry.value.toString();
    }

    return strings;
  }
}
