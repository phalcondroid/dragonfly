import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';

import 'dragonfly_i18n_adapter.dart';

/// Base class for generated i18n classes.
///
/// Extends `LocalizationsDelegate<DragonflyI18n>` so the generated subclass
/// integrates directly with Flutter's `Localizations` widget. Use
/// `AppI18n.of(context)` to access translations anywhere in the widget tree.
///
/// ### Without code generation (manual)
///
/// ```dart
/// class AppI18n extends DragonflyI18n {
///   AppI18n({required super.adapter, required super.supportedLocales});
///
///   static AppI18n of(BuildContext context) =>
///       Localizations.of<AppI18n>(context, AppI18n)!;
///
///   String get helloWorld => translate('helloWorld');
///   String pageTitle(int page) =>
///       translate('pageTitle', args: {'page': '$page'});
/// }
/// ```
///
/// ### With `@I18n` annotation (generated)
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
class DragonflyI18n extends LocalizationsDelegate<DragonflyI18n> {
  DragonflyI18n({
    required this.adapter,
    required this.supportedLocales,
  })  : _translations = {},
        _currentLocale = supportedLocales.first;

  /// The adapter that loads translations.
  final DragonflyI18nAdapter adapter;

  /// Locales this i18n instance supports.
  final List<Locale> supportedLocales;

  Map<String, String> _translations;
  Locale _currentLocale;

  /// The currently active locale.
  Locale get currentLocale => _currentLocale;

  /// Whether translations for [locale] have been loaded.
  bool isLoaded(Locale locale) =>
      _currentLocale == locale && _translations.isNotEmpty;

  /// Looks up a translation by [key]. If the key is not found, returns
  /// the key itself as a fallback (never throws).
  ///
  /// [args] are interpolated into `{param}` placeholders in the
  /// translation value.
  String translate(String key, {Map<String, String>? args}) {
    var text = _translations[key] ?? key;
    if (args != null) {
      for (final entry in args.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return text;
  }

  /// Typed accessor for the generated `of` static method.
  ///
  /// Generated subclasses override this:
  /// ```dart
  /// static AppI18n of(BuildContext context) =>
  ///     Localizations.of<AppI18n>(context, AppI18n)!;
  /// ```
  static DragonflyI18n of(BuildContext context) =>
      Localizations.of<DragonflyI18n>(context, DragonflyI18n)!;

  // ── LocalizationsDelegate ─────────────────────────────────────────────────

  @override
  bool isSupported(Locale locale) =>
      supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<DragonflyI18n> load(Locale locale) async {
    _translations = await adapter.load(locale);
    _currentLocale = locale;
    return SynchronousFuture(this);
  }

  @override
  bool shouldReload(covariant DragonflyI18n old) =>
      adapter.shouldReload || old.adapter.shouldReload;

  @override
  Type get type => DragonflyI18n;
}
