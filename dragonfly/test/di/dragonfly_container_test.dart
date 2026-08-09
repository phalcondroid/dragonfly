import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

abstract class _TestService {}

class _ServiceImpl implements _TestService {
  final int id;
  _ServiceImpl(this.id);
}

void main() {
  setUp(() async {
    await DragonflyContainer.I.reset();
  });

  tearDown(() async {
    await DragonflyContainer.I.reset();
  });

  group('registerSingleton', () {
    test('get returns the same instance', () {
      final instance = _ServiceImpl(1);
      DragonflyContainer.I.registerSingleton<_TestService>(instance);
      final resolved = DragonflyContainer.I.get<_TestService>();
      expect(identical(resolved, instance), isTrue);
    });

    test('returns the passed instance from registerSingleton', () {
      final instance = _ServiceImpl(1);
      final returned = DragonflyContainer.I.registerSingleton<_TestService>(instance);
      expect(identical(returned, instance), isTrue);
    });

    test('resolves with instanceName', () {
      final instance = _ServiceImpl(42);
      DragonflyContainer.I.registerSingleton<_TestService>(instance, instanceName: 'named');
      final resolved = DragonflyContainer.I.get<_TestService>(instanceName: 'named');
      expect(identical(resolved, instance), isTrue);
    });

    test('named and unnamed registrations coexist', () {
      final unnamed = _ServiceImpl(1);
      final named = _ServiceImpl(2);
      DragonflyContainer.I.registerSingleton<_TestService>(unnamed);
      DragonflyContainer.I.registerSingleton<_TestService>(named, instanceName: 'named');
      expect((DragonflyContainer.I.get<_TestService>() as _ServiceImpl).id, 1);
      expect((DragonflyContainer.I.get<_TestService>(instanceName: 'named') as _ServiceImpl).id, 2);
    });
  });

  group('registerLazySingleton', () {
    test('creates instance on first get', () {
      var factoryCalls = 0;
      DragonflyContainer.I.registerLazySingleton<_TestService>(() {
        factoryCalls++;
        return _ServiceImpl(10);
      });
      expect(factoryCalls, 0);
      final resolved = DragonflyContainer.I.get<_TestService>();
      expect(factoryCalls, 1);
      expect((resolved as _ServiceImpl).id, 10);
    });

    test('returns same instance on subsequent gets', () {
      DragonflyContainer.I.registerLazySingleton<_TestService>(() => _ServiceImpl(7));
      final first = DragonflyContainer.I.get<_TestService>();
      final second = DragonflyContainer.I.get<_TestService>();
      expect(identical(first, second), isTrue);
    });

    test('calls onCreated callback after creation', () {
      _TestService? captured;
      DragonflyContainer.I.registerLazySingleton<_TestService>(
        () => _ServiceImpl(3),
        onCreated: (s) => captured = s,
      );
      expect(captured, isNull);
      DragonflyContainer.I.get<_TestService>();
      expect(captured, isNotNull);
      expect((captured as _ServiceImpl).id, 3);
    });

    test('calls dispose when scope is popped', () async {
      var disposed = false;
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerLazySingleton<_TestService>(
        () => _ServiceImpl(1),
        dispose: (_) async {
          disposed = true;
        },
      );
      DragonflyContainer.I.get<_TestService>();
      await DragonflyContainer.I.popScope();
      expect(disposed, isTrue);
    });
  });

  group('registerFactory', () {
    test('creates a new instance each get', () {
      var counter = 0;
      DragonflyContainer.I.registerFactory<_TestService>(() {
        counter++;
        return _ServiceImpl(counter);
      });
      final first = DragonflyContainer.I.get<_TestService>();
      final second = DragonflyContainer.I.get<_TestService>();
      expect(identical(first, second), isFalse);
      expect((first as _ServiceImpl).id, 1);
      expect((second as _ServiceImpl).id, 2);
    });
  });

  group('registerFactoryParam', () {
    test('passes parameters to factory', () {
      DragonflyContainer.I.registerFactoryParam<_TestService, dynamic, dynamic>(
        (dynamic p1, dynamic p2) => _ServiceImpl((p1 as int) + (p2 as String).length),
      );
      final resolved = DragonflyContainer.I.get<_TestService>(param1: 10, param2: 'abc');
      expect((resolved as _ServiceImpl).id, 13);
    });
  });

  group('registerSingletonAsync', () {
    test('registration is reflected in isRegistered', () {
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async => _ServiceImpl(1),
      );
      expect(DragonflyContainer.I.isRegistered<_TestService>(), isTrue);
    });

    test('allReadySync is false while creation is pending', () {
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return _ServiceImpl(1);
        },
      );
      expect(DragonflyContainer.I.allReadySync(), isFalse);
    });

    test('allReady completes after async singleton resolves', () async {
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _ServiceImpl(1);
        },
      );
      await DragonflyContainer.I.allReady();
    });

    test('calls onCreated callback automatically', () async {
      _TestService? captured;
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async => _ServiceImpl(5),
        onCreated: (s) => captured = s,
      );
      await DragonflyContainer.I.allReady();
      expect(captured, isNotNull);
      expect((captured as _ServiceImpl).id, 5);
    });

    test('calls dispose on scope pop', () async {
      var disposed = false;
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async => _ServiceImpl(1),
        dispose: (_) async {
          disposed = true;
        },
      );
      await DragonflyContainer.I.allReady();
      await DragonflyContainer.I.popScope();
      expect(disposed, isTrue);
    });

    test('throws when using get() instead of getAsync', () {
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async => _ServiceImpl(1),
      );
      expect(
        () => DragonflyContainer.I.get<_TestService>(),
        throwsA(isA<Exception>()),
      );
    });

    test('isReady completes after creation', () async {
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _ServiceImpl(1);
        },
      );
      await DragonflyContainer.I.isReady<_TestService>();
    });
  });

  group('registerFactoryAsync', () {
    test('registration is reflected in isRegistered', () {
      DragonflyContainer.I.registerFactoryAsync<_TestService>(
        () async => _ServiceImpl(1),
      );
      expect(DragonflyContainer.I.isRegistered<_TestService>(), isTrue);
    });
  });

  group('registerFactoryParamAsync', () {
    test('registration is reflected in isRegistered', () {
      DragonflyContainer.I.registerFactoryParamAsync<_TestService, int, String>(
        (int? p1, String? p2) async =>
            _ServiceImpl((p1 ?? 0) + (p2?.length ?? 0)) as _TestService,
      );
      expect(DragonflyContainer.I.isRegistered<_TestService>(), isTrue);
    });
  });

  group('registerLazySingletonAsync', () {
    test('registration is reflected in isRegistered', () {
      DragonflyContainer.I.registerLazySingletonAsync<_TestService>(
        () async => _ServiceImpl(1),
      );
      expect(DragonflyContainer.I.isRegistered<_TestService>(), isTrue);
    });
  });

  group('isRegistered', () {
    test('returns true after registration', () {
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(1));
      expect(DragonflyContainer.I.isRegistered<_TestService>(), isTrue);
    });

    test('returns false before registration', () {
      expect(DragonflyContainer.I.isRegistered<_TestService>(), isFalse);
    });

    test('works with named registrations', () {
      DragonflyContainer.I.registerSingleton<_TestService>(
        _ServiceImpl(1),
        instanceName: 'named',
      );
      expect(DragonflyContainer.I.isRegistered<_TestService>(), isFalse);
      expect(
        DragonflyContainer.I.isRegistered<_TestService>(instanceName: 'named'),
        isTrue,
      );
    });
  });

  group('duplicate registration', () {
    test('throws DragonflyException on duplicate registration', () {
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(1));
      expect(
        () => DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(2)),
        throwsA(isA<DragonflyException>()),
      );
    });

    test('allowReassignment allows override', () {
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(1));
      DragonflyContainer.I.allowReassignment = true;
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(2));
      final resolved = DragonflyContainer.I.get<_TestService>();
      expect((resolved as _ServiceImpl).id, 2);
      DragonflyContainer.I.allowReassignment = false;
    });
  });

  group('get unregistered type', () {
    test('throws Exception for unregistered type', () {
      expect(
        () => DragonflyContainer.I.get<_TestService>(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception for unregistered named type', () {
      expect(
        () => DragonflyContainer.I.get<_TestService>(instanceName: 'missing'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('pushNewScope and popScope', () {
    test('scope isolates registrations', () async {
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(99));
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(1));
      expect((DragonflyContainer.I.get<_TestService>() as _ServiceImpl).id, 1);
      await DragonflyContainer.I.popScope();
      expect((DragonflyContainer.I.get<_TestService>() as _ServiceImpl).id, 99);
    });

    test('inner scope shadows outer scope', () {
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(1));
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(2));
      expect((DragonflyContainer.I.get<_TestService>() as _ServiceImpl).id, 2);
    });

    test('dispose is called on scope pop for all entries', () async {
      var disposeCount = 0;
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingleton<_TestService>(
        _ServiceImpl(1),
        instanceName: 'singleton',
        dispose: (_) async => disposeCount++,
      );
      DragonflyContainer.I.registerLazySingleton<_TestService>(
        () => _ServiceImpl(2),
        instanceName: 'lazy',
        dispose: (_) async => disposeCount++,
      );
      DragonflyContainer.I.get<_TestService>(instanceName: 'lazy');
      await DragonflyContainer.I.popScope();
      expect(disposeCount, 2);
    });

    test('onScopeChanged is called', () async {
      var pushed = false;
      var popped = false;
      DragonflyContainer.I.onScopeChanged = (p) {
        if (p) pushed = true;
      };
      DragonflyContainer.I.pushNewScope();
      expect(pushed, isTrue);

      DragonflyContainer.I.onScopeChanged = (p) {
        if (!p) popped = true;
      };
      await DragonflyContainer.I.popScope();
      expect(popped, isTrue);
      DragonflyContainer.I.onScopeChanged = null;
    });
  });

  group('allReady', () {
    test('completes when all async singletons are ready', () async {
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _ServiceImpl(1);
        },
      );
      await DragonflyContainer.I.allReady();
    });
  });

  group('allReadySync', () {
    test('returns true when no async singletons are pending', () {
      expect(DragonflyContainer.I.allReadySync(), isTrue);
    });

    test('returns false while async singleton is pending', () {
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return _ServiceImpl(1);
        },
      );
      expect(DragonflyContainer.I.allReadySync(), isFalse);
    });
  });

  group('isReady', () {
    test('completes immediately for sync registration', () async {
      DragonflyContainer.I.registerSingleton<_TestService>(_ServiceImpl(1));
      await DragonflyContainer.I.isReady<_TestService>();
    });

    test('completes after async singleton creation', () async {
      DragonflyContainer.I.registerSingletonAsync<_TestService>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _ServiceImpl(1);
        },
      );
      await DragonflyContainer.I.isReady<_TestService>();
    });

    test('throws DragonflyException when nothing registered', () {
      expect(
        () => DragonflyContainer.I.isReady<_TestService>(),
        throwsA(isA<DragonflyException>()),
      );
    });
  });

  group('debugPrintRegisteredInstances', () {
    test('does not throw when empty', () {
      expect(
        () => DragonflyContainer.I.debugPrintRegisteredInstances(),
        returnsNormally,
      );
    });

    test('does not throw with registrations', () {
      DragonflyContainer.I.registerSingleton<_TestService>(
        _ServiceImpl(1),
        instanceName: 'a',
      );
      DragonflyContainer.I.registerFactory<_TestService>(
        () => _ServiceImpl(2),
        instanceName: 'b',
      );
      DragonflyContainer.I.registerLazySingleton<_TestService>(
        () => _ServiceImpl(3),
        instanceName: 'c',
      );
      expect(
        () => DragonflyContainer.I.debugPrintRegisteredInstances(),
        returnsNormally,
      );
    });
  });

  group('call operator', () {
    test('call<T>() delegates to get<T>()', () {
      final instance = _ServiceImpl(123);
      DragonflyContainer.I.registerSingleton<_TestService>(instance);
      expect(
        identical(DragonflyContainer.I.call<_TestService>(), instance),
        isTrue,
      );
    });
  });
}
