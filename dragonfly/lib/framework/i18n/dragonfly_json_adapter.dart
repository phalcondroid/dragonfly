import 'dart:convert';

import 'package:flutter/services.dart';
import 'dart:ui';

import 'dragonfly_i18n_adapter.dart';

/// Loads translations from plain JSON key-value files.
///
/// Files should be structured as a flat JSON object:
///
/// ```json
/// {
///   "helloWorld": "Hello World",
///   "pageTitle": "Page {page}",
///   "saveButton": "Save"
/// }
/// ```
///
/// Placeholder interpolation uses `{param}` syntax. No ICU plural support
/// in this adapter — use [DragonflyArbAdapter] for plural-aware translations.
class DragonflyJsonAdapter extends DragonflyI18nAdapter {
  DragonflyJsonAdapter({
    this.path = 'assets/i18n',
    List<Locale> supportedLocales = const [Locale('en')],
  }) : _supported = {for (final l in supportedLocales) l.languageCode};

  final String path;
  final Set<String> _supported;

  @override
  bool supports(Locale locale) =>
      _supported.contains(locale.languageCode);

  @override
  Future<Map<String, String>> load(Locale locale) async {
    final filePath = '$path/${locale.languageCode}.json';
    final data = await rootBundle.loadString(filePath);
    final raw = json.decode(data) as Map<String, dynamic>;
    return raw.map((key, value) => MapEntry(key, value.toString()));
  }
}
