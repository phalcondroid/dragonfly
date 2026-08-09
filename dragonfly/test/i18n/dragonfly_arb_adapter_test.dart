import 'dart:ui';

import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflyArbAdapter', () {
    test('constructor with default path', () {
      final adapter = DragonflyArbAdapter();
      expect(adapter.path, 'assets/i18n');
    });

    test('constructor with custom path', () {
      final adapter = DragonflyArbAdapter(path: 'assets/translations');
      expect(adapter.path, 'assets/translations');
    });

    test('constructor with supportedLocales', () {
      final adapter = DragonflyArbAdapter(
        supportedLocales: [const Locale('en'), const Locale('es')],
      );
      expect(adapter.supports(const Locale('en')), isTrue);
      expect(adapter.supports(const Locale('es')), isTrue);
    });

    test('supports returns true for supported locale', () {
      final adapter = DragonflyArbAdapter();
      expect(adapter.supports(const Locale('en')), isTrue);
    });

    test('supports returns false for unsupported locale', () {
      final adapter = DragonflyArbAdapter();
      expect(adapter.supports(const Locale('pt')), isFalse);
    });

    test('templateLocale is stored', () {
      final adapter = DragonflyArbAdapter(templateLocale: const Locale('es'));
      expect(adapter.templateLocale, const Locale('es'));
    });

    test('templateLocale defaults to en', () {
      final adapter = DragonflyArbAdapter();
      expect(adapter.templateLocale, const Locale('en'));
    });

    test('is a DragonflyI18nAdapter', () {
      final adapter = DragonflyArbAdapter();
      expect(adapter, isA<DragonflyI18nAdapter>());
    });
  });
}
