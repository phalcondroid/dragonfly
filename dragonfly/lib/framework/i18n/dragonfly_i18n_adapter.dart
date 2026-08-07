import 'dart:ui';

/// Abstract contract for loading translations.
///
/// Implement this to add support for a new translation source — a file format,
/// a REST API, a database, or a headless CMS. Built-in implementations:
/// - [DragonflyArbAdapter] — ARB files (Flutter native)
/// - [DragonflyJsonAdapter] — JSON key-value files
///
/// Custom adapters are registered through [DragonflyI18nAdapterConfig] and
/// added to [DragonflyConfig.adapters].
///
/// ```dart
/// class LokaliseApiAdapter extends DragonflyI18nAdapter {
///   LokaliseApiAdapter({required this.apiKey});
///   final String apiKey;
///
///   @override
///   Future<Map<String, String>> load(Locale locale) async {
///     final body = await http.get(
///       Uri.parse('https://api.lokalise.com/projects/123/translations/${locale.languageCode}'),
///       headers: {'X-Api-Token': apiKey},
///     );
///     return parse(body.body);
///   }
///
///   @override
///   bool supports(Locale locale) => true;
/// }
/// ```
abstract class DragonflyI18nAdapter {
  /// Loads all translations for [locale].
  ///
  /// Returns a map of key → translated value. The generated i18n class calls
  /// this once per locale during `LocalizationsDelegate.load()`.
  Future<Map<String, String>> load(Locale locale);

  /// Whether this adapter has translations for [locale].
  bool supports(Locale locale);

  /// Whether translations should be reloaded when the adapter changes.
  bool get shouldReload => false;
}
