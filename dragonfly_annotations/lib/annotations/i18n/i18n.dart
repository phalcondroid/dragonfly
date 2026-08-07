/// Marks a class as the internationalization config for a Dragonfly app.
///
/// The annotated class must extend `DragonflyI18n` (or a generated `_$X` base)
/// and implement `LocalizationsDelegate`. The i18n generator produces typed
/// Dart getters for every translation key found in the adapter's source files.
///
/// ```dart
/// @I18n(
///   adapter: DragonflyArbAdapter(path: 'assets/i18n'),
///   supportedLocales: [Locale('en'), Locale('es')],
/// )
/// class AppI18n extends _$AppI18n {
///   const AppI18n();
/// }
/// ```
///
/// After generation, use `AppI18n.of(context).helloWorld` for typed access.
class I18n {
  /// The adapter that loads translations. Built-in options:
  /// - `DragonflyArbAdapter(path:)` — ARB files (Flutter native format)
  /// - `DragonflyJsonAdapter(path:)` — JSON key-value files
  ///
  /// Custom adapters must implement `DragonflyI18nAdapter`.
  final String adapterType;

  /// Locales supported by this i18n config.
  final List<String> supportedLocales;

  /// Directory where translation files live. Default: `assets/i18n`.
  final String path;

  /// The template (source) locale. Default: `en`.
  final String templateLocale;

  const I18n({
    this.adapterType = 'DragonflyArbAdapter',
    this.supportedLocales = const ['en'],
    this.path = 'assets/i18n',
    this.templateLocale = 'en',
  });
}
