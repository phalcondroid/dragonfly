import 'dart:ui';

import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubAdapter extends DragonflyI18nAdapter {
  final Map<String, String> _data;
  final bool _shouldReload;

  _StubAdapter(this._data, {bool shouldReload = false})
    : _shouldReload = shouldReload;

  @override
  Future<Map<String, String>> load(Locale locale) async => _data;

  @override
  bool supports(Locale locale) => _data.isNotEmpty;

  @override
  bool get shouldReload => _shouldReload;
}

void main() {
  group('DragonflyI18nAdapter (abstract)', () {
    test('stub adapter load() returns map', () async {
      final adapter = _StubAdapter({'hello': 'Hello'});
      final result = await adapter.load(const Locale('en'));
      expect(result, {'hello': 'Hello'});
    });

    test('stub adapter supports() returns bool', () {
      final withData = _StubAdapter({'hello': 'Hello'});
      final empty = _StubAdapter({});

      expect(withData.supports(const Locale('en')), isTrue);
      expect(empty.supports(const Locale('en')), isFalse);
    });

    test('stub adapter shouldReload returns false by default', () {
      final adapter = _StubAdapter({'hello': 'Hello'});
      expect(adapter.shouldReload, isFalse);
    });
  });

  group('DragonflyI18n (runtime)', () {
    late DragonflyI18n i18n;

    setUp(() {
      i18n = DragonflyI18n(
        adapter: _StubAdapter({
          'hello': 'Hello',
          'greeting': 'Hello {name}!',
          'info': '{name} has {count} items',
        }),
        supportedLocales: const [Locale('en'), Locale('es')],
      );
    });

    test("translate('key') returns value from adapter", () async {
      await i18n.load(const Locale('en'));

      expect(i18n.translate('hello'), 'Hello');
    });

    test("translate('missing_key') returns the key itself as fallback", () async {
      await i18n.load(const Locale('en'));

      expect(i18n.translate('missing_key'), 'missing_key');
    });

    test("translate('hello', args: {'name': 'Rick'}) does placeholder interpolation",
        () async {
      await i18n.load(const Locale('en'));

      expect(
        i18n.translate('greeting', args: {'name': 'Rick'}),
        'Hello Rick!',
      );
    });

    test(
        "translate('hello', args: {'name': 'Rick', 'count': '5'}) does multiple interpolations",
        () async {
      await i18n.load(const Locale('en'));

      expect(
        i18n.translate('info', args: {'name': 'Rick', 'count': '5'}),
        'Rick has 5 items',
      );
    });

    test("isSupported(Locale('en')) returns true for supported locale", () {
      expect(i18n.isSupported(const Locale('en')), isTrue);
    });

    test("isSupported(Locale('pt')) returns false for unsupported", () {
      expect(i18n.isSupported(const Locale('pt')), isFalse);
    });

    test("isSupported(Locale('en', 'US')) returns true (language code match)", () {
      expect(i18n.isSupported(const Locale('en', 'US')), isTrue);
    });

    test('currentLocale getter', () async {
      expect(i18n.currentLocale, const Locale('en'));

      await i18n.load(const Locale('es'));

      expect(i18n.currentLocale, const Locale('es'));
    });

    test('isLoaded() returns true after load', () async {
      expect(i18n.isLoaded(const Locale('en')), isFalse);

      await i18n.load(const Locale('en'));

      expect(i18n.isLoaded(const Locale('en')), isTrue);
    });

    test('type getter returns DragonflyI18n', () {
      expect(i18n.type, DragonflyI18n);
    });

    test('shouldReload() returns false when adapter.shouldReload is false', () {
      final old = DragonflyI18n(
        adapter: _StubAdapter({'hello': 'Hello'}),
        supportedLocales: const [Locale('en')],
      );

      expect(i18n.shouldReload(old), isFalse);
    });
  });

  group('DragonflyJsonAdapter', () {
    test('constructor and supports() method', () {
      final adapter = DragonflyJsonAdapter(
        path: 'assets/i18n',
        supportedLocales: const [Locale('en'), Locale('pt')],
      );

      expect(adapter.supports(const Locale('en')), isTrue);
      expect(adapter.supports(const Locale('pt')), isTrue);
      expect(adapter.supports(const Locale('fr')), isFalse);
    });

    test('default path is assets/i18n', () {
      final adapter = DragonflyJsonAdapter();
      expect(adapter.supports(const Locale('en')), isTrue);
    });

    test('type check — is a DragonflyI18nAdapter', () {
      final adapter = DragonflyJsonAdapter();
      expect(adapter, isA<DragonflyI18nAdapter>());
    });
  });
}
