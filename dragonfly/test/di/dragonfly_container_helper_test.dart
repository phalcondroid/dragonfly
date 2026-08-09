import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/di/environment_filter.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestService {}

void main() {
  setUp(() async {
    await DragonflyContainer.I.reset();
  });

  tearDown(() async {
    await DragonflyContainer.I.reset();
  });

  group('DragonflyContainerHelper', () {
    test('stores reference to container', () {
      final container = DragonflyContainer.instance;
      final helper = DragonflyContainerHelper(container);

      expect(helper.getIt, same(container));
    });

    test('can be constructed (no environment)', () {
      final helper = DragonflyContainerHelper(DragonflyContainer.instance);

      expect(helper, isA<DragonflyContainerHelper>());
    });

    test('can be constructed with environment string', () {
      final helper = DragonflyContainerHelper(
        DragonflyContainer.instance,
        'dev',
      );

      expect(helper, isA<DragonflyContainerHelper>());
    });

    test('can be constructed with environment filter', () {
      final helper = DragonflyContainerHelper(
        DragonflyContainer.instance,
        null,
        NoEnvOrContains('dev'),
      );

      expect(helper, isA<DragonflyContainerHelper>());
    });

    test('call<T>() delegates to container get<T>()', () {
      final container = DragonflyContainer.instance;
      final instance = _TestService();
      container.registerSingleton<_TestService>(instance);
      final helper = DragonflyContainerHelper(container);

      expect(helper.call<_TestService>(), same(instance));
    });

    group('factory registration', () {
      test('factory() registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.factory<_TestService>(() => _TestService());

        expect(container.isRegistered<_TestService>(), isTrue);
      });

      test('factory() does not throw with valid factory func', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.factory<_TestService>(() => _TestService());
        final resolved = helper.call<_TestService>();
        expect(resolved, isA<_TestService>());
      });

      test('factory() respects registerFor filter', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(
          container,
          null,
          NoEnvOrContains('prod'),
        );

        helper.factory<_TestService>(
          () => _TestService(),
          registerFor: {'dev'},
        );

        expect(container.isRegistered<_TestService>(), isFalse);
      });

      test('factory() with matching environment registers', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(
          container,
          null,
          NoEnvOrContains('dev'),
        );

        helper.factory<_TestService>(
          () => _TestService(),
          registerFor: {'dev'},
        );

        expect(container.isRegistered<_TestService>(), isTrue);
      });

      test('factory() with empty registerFor registers regardless', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(
          container,
          null,
          NoEnvOrContains('prod'),
        );

        helper.factory<_TestService>(
          () => _TestService(),
        );

        expect(container.isRegistered<_TestService>(), isTrue);
      });
    });

    group('singleton registration', () {
      test('singleton() registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.singleton<_TestService>(() => _TestService());

        expect(container.isRegistered<_TestService>(), isTrue);
      });

      test('singleton() with instanceName', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.singleton<_TestService>(
          () => _TestService(),
          instanceName: 'named',
        );

        expect(container.isRegistered<_TestService>(instanceName: 'named'),
            isTrue);
      });

      test('singleton() returns the same instance', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.singleton<_TestService>(() => _TestService());

        final first = helper.call<_TestService>();
        final second = helper.call<_TestService>();
        expect(identical(first, second), isTrue);
      });
    });

    group('lazySingleton registration', () {
      test('lazySingleton() registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.lazySingleton<_TestService>(() => _TestService());

        expect(container.isRegistered<_TestService>(), isTrue);
      });

      test('lazySingleton() creates instance on first call', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);
        var created = false;

        helper.lazySingleton<_TestService>(() {
          created = true;
          return _TestService();
        });

        expect(created, isFalse);
        helper.call<_TestService>();
        expect(created, isTrue);
      });
    });

    group('factoryAsync registration', () {
      test('factoryAsync() registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.factoryAsync<_TestService>(() async => _TestService());

        expect(container.isRegistered<_TestService>(), isTrue);
      });

      test('factoryAsync() with preResolve', () async {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        await helper.factoryAsync<_TestService>(
          () async => _TestService(),
          preResolve: true,
        );

        expect(container.isRegistered<_TestService>(), isTrue);
      });
    });

    group('singletonAsync registration', () {
      test('singletonAsync() registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.singletonAsync<_TestService>(() async => _TestService());

        expect(container.isRegistered<_TestService>(), isTrue);
      });
    });

    group('singletonWithDependencies', () {
      test('registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.singletonWithDependencies<_TestService>(
          () => _TestService(),
        );

        expect(container.isRegistered<_TestService>(), isTrue);
      });

      test('instance can be resolved', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.singletonWithDependencies<_TestService>(
          () => _TestService(),
        );

        final resolved = helper.call<_TestService>();
        expect(resolved, isA<_TestService>());
      });
    });

    group('factoryParam registration', () {
      test('registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.factoryParam<_TestService, dynamic, dynamic>(
          (p1, p2) => _TestService(),
        );

        expect(container.isRegistered<_TestService>(), isTrue);
      });

      test('registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.factoryParam<_TestService, String, int>(
          (p1, p2) => _TestService(),
        );

        expect(container.isRegistered<_TestService>(), isTrue);
      });
    });

    group('factoryParamAsync registration', () {
      test('registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.factoryParamAsync<_TestService, dynamic, dynamic>(
          (p1, p2) async => _TestService(),
        );

        expect(container.isRegistered<_TestService>(), isTrue);
      });
    });

    group('lazySingletonAsync registration', () {
      test('registers via container', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        helper.lazySingletonAsync<_TestService>(() async => _TestService());

        expect(container.isRegistered<_TestService>(), isTrue);
      });
    });

    group('initScope', () {
      test('initScope pushes a new scope', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        container.registerSingleton<_TestService>(_TestService());
        final result = helper.initScope('testScope', init: (gh) {});

        expect(result, same(container));
      });

      test('initScope runs the init callback', () {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);
        var called = false;

        helper.initScope('testScope', init: (gh) {
          called = true;
        });

        expect(called, isTrue);
      });
    });

    group('initScopeAsync', () {
      test('initScopeAsync pushes a new scope asynchronously', () async {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);

        container.registerSingleton<_TestService>(_TestService());
        final result =
            await helper.initScopeAsync('testScope', init: (gh) async {});

        expect(result, same(container));
      });

      test('initScopeAsync runs the init callback', () async {
        final container = DragonflyContainer.instance;
        final helper = DragonflyContainerHelper(container);
        var called = false;

        await helper.initScopeAsync('testScope', init: (gh) async {
          called = true;
        });

        expect(called, isTrue);
      });
    });
  });
}
