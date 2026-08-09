import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestMessages extends DragonflyValidationMessages {
  @override
  String get required => 'REQUIRED_CUSTOM';
}

void main() {
  setUp(() async {
    await DragonflyContainer.I.reset();
  });

  tearDown(() async {
    await DragonflyContainer.I.reset();
  });

  group('DragonflyApp', () {
    test('constructor with minimal config', () {
      final app = DragonflyApp(config: const DragonflyConfig());
      expect(app.config, isA<DragonflyConfig>());
    });

    test('version returns a non-empty string', () {
      expect(DragonflyApp.version, isNotEmpty);
    });

    test('showBanner defaults to true', () {
      final app = DragonflyApp(config: const DragonflyConfig());
      expect(app.showBanner, isTrue);
    });

    test('enableLogging defaults to true', () {
      final app = DragonflyApp(config: const DragonflyConfig());
      expect(app.enableLogging, isTrue);
    });

    test('showBanner can be set to false', () {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
      );
      expect(app.showBanner, isFalse);
    });

    test('enableLogging can be set to false', () {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        enableLogging: false,
      );
      expect(app.enableLogging, isFalse);
    });

    test('init with minimal config completes without error', () async {
      final app = DragonflyApp(
        config: const DragonflyConfig(),
        showBanner: false,
        enableLogging: false,
      );
      await expectLater(app.init(), completes);
    });

    test('init sets validation messages when provided in config', () async {
      final messages = _TestMessages();
      final config = DragonflyConfig(validationMessages: messages);
      final app = DragonflyApp(
        config: config,
        showBanner: false,
        enableLogging: false,
      );
      await app.init();

      final validate = Validators.required<String>();
      expect(validate(null), 'REQUIRED_CUSTOM');
    });
  });
}
