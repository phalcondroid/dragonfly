import 'package:dragonfly/framework/di/environment_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoEnvOrContains extended', () {
    test('passes when filterEnvs contains the value', () {
      final filter = NoEnvOrContains('dev');
      expect(filter.canRegister({'dev'}), isTrue);
    });

    test('passes when filterEnvs is empty list', () {
      final filter = NoEnvOrContains('dev');
      expect(filter.canRegister(<String>{}), isTrue);
    });

    test('passes when filterEnvs contains value among others', () {
      final filter = NoEnvOrContains('dev');
      expect(filter.canRegister({'prod', 'dev', 'staging'}), isTrue);
    });

    test('fails when filterEnvs contains only prod', () {
      final filter = NoEnvOrContains('dev');
      expect(filter.canRegister({'prod'}), isFalse);
    });

    test('fails when filterEnvs contains only unrelated values', () {
      final filter = NoEnvOrContains('dev');
      expect(filter.canRegister({'prod', 'staging'}), isFalse);
    });

    test('passes when filterEnvs contains staging (second param)', () {
      final filter = NoEnvOrContains('staging');
      expect(filter.canRegister({'staging'}), isTrue);
    });

    test('passes when filterEnvs contains staging among dev and prod', () {
      final filter = NoEnvOrContains('staging');
      expect(filter.canRegister({'dev', 'staging', 'prod'}), isTrue);
    });

    test('fails when filterEnvs is set with dev but filter expects staging', () {
      final filter = NoEnvOrContains('staging');
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('environments property stores the expected value', () {
      final filter = NoEnvOrContains('production');
      expect(filter.environments, {'production'});
    });

    test('environments is empty set when null is passed', () {
      final filter = NoEnvOrContains(null);
      expect(filter.environments, isEmpty);
    });

    test('null env — passes for empty depEnvironments', () {
      final filter = NoEnvOrContains(null);
      expect(filter.canRegister(<String>{}), isTrue);
    });

    test('null env — fails for any non-empty depEnvironments', () {
      final filter = NoEnvOrContains(null);
      expect(filter.canRegister({'dev'}), isFalse);
      expect(filter.canRegister({'prod'}), isFalse);
      expect(filter.canRegister({'dev', 'staging'}), isFalse);
    });
  });

  group('NoEnvOrContainsAll', () {
    test('passes when depEnvironments is empty', () {
      const filter = NoEnvOrContainsAll({'dev', 'staging'});
      expect(filter.canRegister(<String>{}), isTrue);
    });

    test('passes when depEnvironments contains all required environments', () {
      const filter = NoEnvOrContainsAll({'dev', 'staging'});
      expect(filter.canRegister({'dev', 'staging'}), isTrue);
    });

    test(
        'passes when depEnvironments contains all required plus extra',
        () {
      const filter = NoEnvOrContainsAll({'dev'});
      expect(filter.canRegister({'dev', 'staging', 'prod'}), isTrue);
    });

    test('fails when depEnvironments is missing one required environment', () {
      const filter = NoEnvOrContainsAll({'dev', 'staging'});
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('fails when depEnvironments has none of the required environments',
        () {
      const filter = NoEnvOrContainsAll({'dev', 'staging'});
      expect(filter.canRegister({'prod'}), isFalse);
    });

    test('environments property stores all provided environments', () {
      const filter = NoEnvOrContainsAll({'dev', 'staging', 'prod'});
      expect(filter.environments, {'dev', 'staging', 'prod'});
    });
  });

  group('NoEnvOrContainsAny', () {
    test('passes when depEnvironments is empty', () {
      const filter = NoEnvOrContainsAny({'dev', 'staging'});
      expect(filter.canRegister(<String>{}), isTrue);
    });

    test('passes when depEnvironments contains one of the environments', () {
      const filter = NoEnvOrContainsAny({'dev', 'staging'});
      expect(filter.canRegister({'dev'}), isTrue);
    });

    test('passes when depEnvironments contains another one', () {
      const filter = NoEnvOrContainsAny({'dev', 'staging'});
      expect(filter.canRegister({'staging'}), isTrue);
    });

    test('passes when depEnvironments contains multiple matches', () {
      const filter = NoEnvOrContainsAny({'dev', 'staging'});
      expect(filter.canRegister({'dev', 'staging', 'prod'}), isTrue);
    });

    test('fails when depEnvironments contains none of the environments', () {
      const filter = NoEnvOrContainsAny({'dev', 'staging'});
      expect(filter.canRegister({'prod'}), isFalse);
    });

    test('fails when depEnvironments contains only unrelated values', () {
      const filter = NoEnvOrContainsAny({'dev', 'staging'});
      expect(filter.canRegister({'prod', 'test'}), isFalse);
    });

    test('environments property stores all provided environments', () {
      const filter = NoEnvOrContainsAny({'dev', 'staging'});
      expect(filter.environments, {'dev', 'staging'});
    });
  });

  group('SimpleEnvironmentFilter', () {
    test('calls filter function', () {
      var called = false;
      final filter = SimpleEnvironmentFilter(
        filter: (_) {
          called = true;
          return true;
        },
      );
      filter.canRegister({'dev'});
      expect(called, isTrue);
    });

    test('returns the filter result', () {
      final filter = SimpleEnvironmentFilter(filter: (_) => false);
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('receives depEnvironments in filter function', () {
      Set<String>? received;
      final filter = SimpleEnvironmentFilter(filter: (envs) {
        received = envs;
        return true;
      });
      filter.canRegister({'test'});
      expect(received, {'test'});
    });

    test('default environments is empty set', () {
      final filter = SimpleEnvironmentFilter(filter: (_) => true);
      expect(filter.environments, isEmpty);
    });

    test('custom environments stored correctly', () {
      final filter = SimpleEnvironmentFilter(
        filter: (_) => true,
        environments: const {'dev', 'prod'},
      );
      expect(filter.environments, {'dev', 'prod'});
    });
  });

  group('multiple filters combined', () {
    test(
        'NoEnvOrContains and NoEnvOrContainsAll both pass for matching envs',
        () {
      final filter1 = NoEnvOrContains('dev');
      final filter2 = NoEnvOrContainsAll(const {'dev'});

      expect(filter1.canRegister({'dev'}), isTrue);
      expect(filter2.canRegister({'dev'}), isTrue);
    });

    test('NoEnvOrContainsAny with multiple allowed environments', () {
      const filter = NoEnvOrContainsAny({'dev', 'staging', 'test'});

      expect(filter.canRegister({'dev'}), isTrue);
      expect(filter.canRegister({'staging'}), isTrue);
      expect(filter.canRegister({'test'}), isTrue);
      expect(filter.canRegister({'prod'}), isFalse);
      expect(filter.canRegister(<String>{}), isTrue);
    });

    test('all filters pass when depEnvironments is empty', () {
      final filters = <EnvironmentFilter>[
        NoEnvOrContains('dev'),
        const NoEnvOrContainsAll({'dev', 'staging'}),
        const NoEnvOrContainsAny({'dev', 'staging'}),
      ];

      for (final filter in filters) {
        expect(filter.canRegister(<String>{}), isTrue);
      }
    });
  });

  group('SetX extension', () {
    test('firstOrNull returns first element for non-empty set', () {
      final set = {'dev'};
      expect(set.firstOrNull, 'dev');
    });

    test('firstOrNull returns null for empty set', () {
      final set = <String>{};
      expect(set.firstOrNull, isNull);
    });
  });

  group('EnvironmentFilter base class', () {
    test('environments are accessible through base class reference', () {
      final EnvironmentFilter filter = NoEnvOrContains('dev');
      expect(filter.environments, {'dev'});
    });
  });
}
