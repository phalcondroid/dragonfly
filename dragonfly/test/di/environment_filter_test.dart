import 'package:dragonfly/framework/di/environment_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoEnvOrContains', () {
    test('noEnvOrContains dev passes when env is dev', () {
      final filter = NoEnvOrContains('dev');
      expect(filter.canRegister({'dev'}), isTrue);
    });

    test('noEnvOrContains dev passes when env is test', () {
      final filter = NoEnvOrContains('dev');
      expect(filter.canRegister({'test', 'dev'}), isTrue);
    });

    test('noEnvOrContains dev passes when env list is empty', () {
      final filter = NoEnvOrContains('dev');
      expect(filter.canRegister(<String>{}), isTrue);
    });

    test('noEnvOrContains prod fails when env is dev', () {
      final filter = NoEnvOrContains('prod');
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('environments property stores passed value', () {
      final filter = NoEnvOrContains('staging');
      expect(filter.environments, contains('staging'));
    });

    test('null env passed — empty depEnvironments returns true', () {
      final filter = NoEnvOrContains(null);
      expect(filter.canRegister(<String>{}), isTrue);
    });

    test('null env passed — non-empty depEnvironments returns false', () {
      final filter = NoEnvOrContains(null);
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('null env passed — environments set is empty', () {
      final filter = NoEnvOrContains(null);
      expect(filter.environments, isEmpty);
    });
  });
}
