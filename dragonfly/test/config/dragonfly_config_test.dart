import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflyHttpBaseOptions', () {
    test('default values', () {
      const options = DragonflyHttpBaseOptions();

      expect(options.baseUrl, '');
      expect(options.connectTimeout, const Duration(seconds: 5));
      expect(options.receiveTimeout, const Duration(seconds: 3));
    });

    test('custom values', () {
      const options = DragonflyHttpBaseOptions(
        baseUrl: 'https://api.example.com',
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 8),
      );

      expect(options.baseUrl, 'https://api.example.com');
      expect(options.connectTimeout, const Duration(seconds: 10));
      expect(options.receiveTimeout, const Duration(seconds: 8));
    });
  });

  group('DragonflyHttpAdapterConfig', () {
    test('constructor stores all fields', () {
      const options = DragonflyHttpBaseOptions(
        baseUrl: 'https://example.com',
      );
      const config = DragonflyHttpAdapterConfig(
        options: options,
      );

      expect(config.options, options);
      expect(config.interceptor, isNotNull);
    });

    test('connectionName defaults to defaultHttpNetwork', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(),
      );

      expect(config.connectionName, defaultHttpNetwork);
    });

    test('custom connectionName', () {
      const config = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(),
        connectionName: 'customHttp',
      );

      expect(config.connectionName, 'customHttp');
    });
  });

  group('DragonflyWebSocketAdapterConfig', () {
    test('constructor stores all fields', () {
      final realtimeConfig = DragonflyRealtimeConfig(
        url: 'wss://example.com/ws',
      );
      final config = DragonflyWebSocketAdapterConfig(
        config: realtimeConfig,
      );

      expect(config.config, realtimeConfig);
      expect(config.connectionName, defaultRealtimeNetwork);
      expect(config.enableLogging, isTrue);
      expect(config.connectEagerly, isFalse);
    });
  });

  group('DragonflyConfig', () {
    test('adapters list defaults to empty', () {
      const config = DragonflyConfig();

      expect(config.adapters, isEmpty);
    });

    test('validationMessages defaults to null', () {
      const config = DragonflyConfig();

      expect(config.validationMessages, isNull);
    });

    test('deprecated instanceConfigs defaults to empty', () {
      const config = DragonflyConfig();

      expect(config.instanceConfigs, isEmpty);
    });

    test('deprecated realtimeConfigs defaults to empty', () {
      const config = DragonflyConfig();

      expect(config.realtimeConfigs, isEmpty);
    });

    test('accepts adapters list', () {
      const httpConfig = DragonflyHttpAdapterConfig(
        options: DragonflyHttpBaseOptions(),
      );
      const config = DragonflyConfig(
        adapters: [httpConfig],
      );

      expect(config.adapters, hasLength(1));
      expect(config.adapters.first, isA<DragonflyHttpAdapterConfig>());
    });
  });

  group('DragonflyInjector', () {
    test('inject can be null', () {
      const injector = DragonflyInjector();

      expect(injector.inject, isNull);
    });

    test('inject can be non-null', () {
      Future<void> fn(DragonflyContainer c) async {}
      final injector = DragonflyInjector(inject: fn);

      expect(injector.inject, isNotNull);
      expect(injector.inject, same(fn));
    });
  });

  group('DragonflyAdapterConfig', () {
    test('abstract class exists', () {
      expect(DragonflyAdapterConfig, isA<Object>());
    });
  });

  group('DragonflyValidationMessages default instance', () {
    test('all getters return non-null strings', () {
      const messages = DragonflyValidationMessages();

      expect(messages.required, isA<String>());
      expect(messages.invalidEmail, isA<String>());
      expect(messages.invalidFormat, isA<String>());
      expect(messages.invalidUrl, isA<String>());
      expect(messages.invalidPhone, isA<String>());
      expect(messages.notAlphanumeric, isA<String>());
      expect(messages.notAlpha, isA<String>());
      expect(messages.notNumeric, isA<String>());
      expect(messages.notPositive, isA<String>());
      expect(messages.notNegative, isA<String>());
      expect(messages.mustBeTrue, isA<String>());
      expect(messages.mustBeFalse, isA<String>());
      expect(messages.dateInPast, isA<String>());
      expect(messages.dateInFuture, isA<String>());
      expect(messages.fieldsMustMatch, isA<String>());
      expect(messages.fieldsMustDiffer, isA<String>());
      expect(messages.requiredConditional, isA<String>());
      expect(messages.invalidCreditCard, isA<String>());
      expect(messages.invalidCvv, isA<String>());
      expect(messages.invalidExpiryDate, isA<String>());
      expect(messages.weakPassword, isA<String>());
      expect(messages.submitButtonLabel, isA<String>());
      expect(messages.authenticationRequired, isA<String>());

      expect(messages.passwordUppercase, isA<String>());
      expect(messages.passwordLowercase, isA<String>());
      expect(messages.passwordNumber, isA<String>());
      expect(messages.passwordSpecial, isA<String>());
    });

    test('methods return non-null strings', () {
      const messages = DragonflyValidationMessages();

      expect(messages.minLength(3), isA<String>());
      expect(messages.maxLength(10), isA<String>());
      expect(messages.tooLow(0), isA<String>());
      expect(messages.tooHigh(100), isA<String>());
      expect(messages.outOfRange(0, 100), isA<String>());
      expect(messages.tooYoung(18), isA<String>());
      expect(messages.tooFewItems(1), isA<String>());
      expect(messages.tooManyItems(5), isA<String>());
      expect(messages.passwordChars(8), isA<String>());
      expect(messages.passwordRequirements(['a', 'b']), isA<String>());
      expect(messages.requiredRoles(['admin']), isA<String>());
      expect(messages.requiredPermissions(['write']), isA<String>());
    });
  });

  group('DragonflyNetworkConfig', () {
    test('constructor stores fields', () {
      const config = DragonflyNetworkConfig(
        baseUrl: 'https://api.example.com',
      );

      expect(config.baseUrl, 'https://api.example.com');
      expect(config.connectionTimeout, 2000);
      expect(config.isSingleton, isTrue);
      expect(config.headers, isEmpty);
      expect(config.extra, isEmpty);
    });
  });
}
