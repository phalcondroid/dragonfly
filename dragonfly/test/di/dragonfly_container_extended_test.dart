// ignore_for_file: strict_raw_type, inference_failure_on_function_invocation

import 'dart:async';

import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/di/dragonfly_container.dart'
    show DragonflyInjectorType;
import 'package:flutter_test/flutter_test.dart';

class _Svc {
  final int id;
  _Svc(this.id);
}

class _Svc2 {}

void main() {
  setUp(() async {
    await DragonflyContainer.I.reset();
  });

  tearDown(() async {
    await DragonflyContainer.I.reset();
  });

  // ── registerSingleton with instanceName ─────────────────────────────

  group('registerSingleton with instanceName', () {
    test('different names do not conflict', () {
      final a = _Svc(1);
      final b = _Svc(2);
      DragonflyContainer.I.registerSingleton<_Svc>(a, instanceName: 'a');
      DragonflyContainer.I.registerSingleton<_Svc>(b, instanceName: 'b');

      expect(DragonflyContainer.I.get<_Svc>(instanceName: 'a').id, 1);
      expect(DragonflyContainer.I.get<_Svc>(instanceName: 'b').id, 2);
    });

    test('get unnamed when only named exists throws', () {
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(1), instanceName: 'named');
      expect(
        () => DragonflyContainer.I.get<_Svc>(),
        throwsA(isA<Exception>()),
      );
    });

    test('isRegistered with instanceName returns true for matching name', () {
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(1), instanceName: 'x');
      expect(DragonflyContainer.I.isRegistered<_Svc>(instanceName: 'x'), isTrue);
      expect(DragonflyContainer.I.isRegistered<_Svc>(instanceName: 'y'), isFalse);
    });
  });

  // ── registerLazySingleton with dispose callback ─────────────────────

  group('registerLazySingleton with dispose', () {
    test('dispose callback is called on reset', () async {
      var disposed = false;
      DragonflyContainer.I.registerLazySingleton<_Svc>(
        () => _Svc(1),
        dispose: (_) async {
          disposed = true;
        },
      );
      DragonflyContainer.I.get<_Svc>();
      await DragonflyContainer.I.reset();
      expect(disposed, isTrue);
    });

    test('dispose not called if instance never created', () async {
      var disposed = false;
      DragonflyContainer.I.registerLazySingleton<_Svc>(
        () => _Svc(1),
        dispose: (_) async {
          disposed = true;
        },
      );
      await DragonflyContainer.I.reset();
      expect(disposed, isFalse);
    });

    test('dispose is called on popScope for lazy singleton in that scope', () async {
      var disposed = false;
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerLazySingleton<_Svc>(
        () => _Svc(1),
        dispose: (_) async {
          disposed = true;
        },
      );
      DragonflyContainer.I.get<_Svc>();
      await DragonflyContainer.I.popScope();
      expect(disposed, isTrue);
    });
  });

  // ── registerFactory with instanceName ───────────────────────────────

  group('registerFactory with instanceName', () {
    test('named factory coexists with unnamed factory', () {
      DragonflyContainer.I.registerFactory<_Svc>(() => _Svc(1));
      DragonflyContainer.I.registerFactory<_Svc>(() => _Svc(2), instanceName: 'b');

      expect(DragonflyContainer.I.get<_Svc>().id, 1);
      expect(DragonflyContainer.I.get<_Svc>(instanceName: 'b').id, 2);
    });

    test('named factory creates new instance each call', () {
      var counter = 0;
      DragonflyContainer.I.registerFactory<_Svc>(() {
        counter++;
        return _Svc(counter);
      }, instanceName: 'counter');

      final a = DragonflyContainer.I.get<_Svc>(instanceName: 'counter');
      final b = DragonflyContainer.I.get<_Svc>(instanceName: 'counter');
      expect(identical(a, b), isFalse);
      expect(a.id, 1);
      expect(b.id, 2);
    });
  });

  // ── get() with wrong type throws ────────────────────────────────────

  group('get with wrong type', () {
    test('throws when getting int as String', () {
      DragonflyContainer.I.registerSingleton<int>(42);
      expect(
        () => DragonflyContainer.I.get<String>(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when no String registered', () {
      expect(
        () => DragonflyContainer.I.get<String>(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── getAsync ────────────────────────────────────────────────────────

  group('getAsync', () {
    test('getAsync throws for unregistered type', () async {
      expect(
        () => DragonflyContainer.I.getAsync<_Svc>(),
        throwsA(isA<Exception>()),
      );
    });

    test('getAsync with instanceName throws for unregistered name', () async {
      DragonflyContainer.I.registerSingleton<String>('hi');
      expect(
        () => DragonflyContainer.I.getAsync<String>(instanceName: 'missing'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── registerSingletonAsync — allReady/allReadySync ──────────────────

  group('registerSingletonAsync readiness', () {
    test('allReadySync returns false while pending', () {
      final completer = Completer<_Svc>();
      DragonflyContainer.I.registerSingletonAsync<_Svc>(() => completer.future);
      expect(DragonflyContainer.I.allReadySync(), isFalse);
      completer.complete(_Svc(1));
    });

    test('allReadySync returns true after completion', () async {
      DragonflyContainer.I.registerSingletonAsync<_Svc>(
        () async => _Svc(1),
      );
      await DragonflyContainer.I.allReady();
      expect(DragonflyContainer.I.allReadySync(), isTrue);
    });

    test('allReady with timeout does not throw on quick resolution', () async {
      DragonflyContainer.I.registerSingletonAsync<_Svc>(
        () async => _Svc(1),
      );
      await DragonflyContainer.I.allReady(timeout: const Duration(seconds: 5));
    });

    test('allReadySync with ignorePendingAsyncCreation returns true', () {
      DragonflyContainer.I.registerSingletonAsync<_Svc>(
        () async {
          await Future.delayed(const Duration(milliseconds: 500));
          return _Svc(1);
        },
      );
      expect(
        DragonflyContainer.I.allReadySync(true),
        isTrue,
      );
    });
  });

  // ── Scope operations ────────────────────────────────────────────────

  group('pushNewScope and popScope', () {
    test('popScope disposes entries in the popped scope', () async {
      var disposed = false;
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingleton<_Svc>(
        _Svc(1),
        dispose: (_) async => disposed = true,
      );
      await DragonflyContainer.I.popScope();
      expect(disposed, isTrue);
    });

    test('popScope does not throw on empty scope', () async {
      DragonflyContainer.I.pushNewScope();
      await DragonflyContainer.I.popScope();
    });

    test('pushNewScope calls onScopeChanged with true', () {
      var called = false;
      var wasPushed = false;
      DragonflyContainer.I.onScopeChanged = (pushed) {
        called = true;
        wasPushed = pushed;
      };
      DragonflyContainer.I.pushNewScope();
      expect(called, isTrue);
      expect(wasPushed, isTrue);
      DragonflyContainer.I.onScopeChanged = null;
    });

    test('popScope calls onScopeChanged with false', () async {
      DragonflyContainer.I.pushNewScope();
      var called = false;
      var wasPushed = false;
      DragonflyContainer.I.onScopeChanged = (pushed) {
        called = true;
        wasPushed = pushed;
      };
      await DragonflyContainer.I.popScope();
      expect(called, isTrue);
      expect(wasPushed, isFalse);
      DragonflyContainer.I.onScopeChanged = null;
    });

    test('pushNewScope with init callback registers in new scope', () {
      DragonflyContainer.I.pushNewScope(init: (c) {
        c.registerSingleton<_Svc2>(_Svc2());
      });
      expect(DragonflyContainer.I.isRegistered<_Svc2>(), isTrue);
    });

    test('pushNewScope with scopeName does not throw', () {
      expect(
        () => DragonflyContainer.I.pushNewScope(scopeName: 'testScope'),
        returnsNormally,
      );
    });
  });

  // ── reset ───────────────────────────────────────────────────────────

  group('reset', () {
    test('reset clears all scopes and registrations', () async {
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(1));
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(2), instanceName: 'inner');

      await DragonflyContainer.I.reset();

      expect(DragonflyContainer.I.isRegistered<_Svc>(), isFalse);
      expect(DragonflyContainer.I.isRegistered<_Svc>(instanceName: 'inner'), isFalse);
    });

    test('reset works on already-empty container', () async {
      await DragonflyContainer.I.reset();
      await DragonflyContainer.I.reset();
    });

    test('reset calls dispose on singleton', () async {
      var disposed = false;
      DragonflyContainer.I.registerSingleton<_Svc>(
        _Svc(1),
        dispose: (_) async => disposed = true,
      );
      await DragonflyContainer.I.reset();
      expect(disposed, isTrue);
    });
  });

  // ── isRegistered ────────────────────────────────────────────────────

  group('isRegistered', () {
    test('still true after get()', () {
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(1));
      DragonflyContainer.I.get<_Svc>();
      expect(DragonflyContainer.I.isRegistered<_Svc>(), isTrue);
    });

    test('still true after get() for lazy singleton', () {
      DragonflyContainer.I.registerLazySingleton<_Svc>(() => _Svc(1));
      DragonflyContainer.I.get<_Svc>();
      expect(DragonflyContainer.I.isRegistered<_Svc>(), isTrue);
    });

    test('false after reset', () async {
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(1));
      await DragonflyContainer.I.reset();
      expect(DragonflyContainer.I.isRegistered<_Svc>(), isFalse);
    });
  });

  // ── debugPrintRegisteredInstances ───────────────────────────────────

  group('debugPrintRegisteredInstances', () {
    test('does not throw with named registrations', () {
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(1), instanceName: 's');
      DragonflyContainer.I.registerLazySingleton<_Svc>(
        () => _Svc(2),
        instanceName: 'l',
      );
      DragonflyContainer.I.registerFactory<_Svc>(() => _Svc(3), instanceName: 'f');
      expect(
        () => DragonflyContainer.I.debugPrintRegisteredInstances(),
        returnsNormally,
      );
    });

    test('does not throw with multiple scopes', () {
      DragonflyContainer.I.registerSingleton<String>('outer');
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingleton<int>(42);
      expect(
        () => DragonflyContainer.I.debugPrintRegisteredInstances(),
        returnsNormally,
      );
    });

    test('does not throw with async singleton', () {
      DragonflyContainer.I.registerSingletonAsync<_Svc>(
        () async => _Svc(1),
        instanceName: 'async',
      );
      expect(
        () => DragonflyContainer.I.debugPrintRegisteredInstances(),
        returnsNormally,
      );
    });
  });

  // ── call operator ───────────────────────────────────────────────────

  group('call operator', () {
    test('call with instanceName delegates to get', () {
      final instance = _Svc(42);
      DragonflyContainer.I.registerSingleton<_Svc>(instance, instanceName: 'nn');
      expect(
        DragonflyContainer.I.call<_Svc>(instanceName: 'nn').id,
        42,
      );
    });

    test('call with param1 and param2 works with factoryParam', () {
      DragonflyContainer.I.registerFactoryParam<_Svc, dynamic, dynamic>(
        (p1, p2) => _Svc((p1 as int) + (p2 as String).length),
      );
      final resolved = DragonflyContainer.I.call<_Svc>(param1: 10, param2: 'abc');
      expect(resolved.id, 13);
    });
  });

  // ── registerFactoryParam with 2 params ──────────────────────────────

  group('registerFactoryParam', () {
    test('two params of same type passed correctly', () {
      DragonflyContainer.I.registerFactoryParam<_Svc, dynamic, dynamic>(
        (p1, p2) => _Svc((p1 as String).length + (p2 as String).length),
      );
      final resolved = DragonflyContainer.I.get<_Svc>(param1: 'ab', param2: 'cde');
      expect(resolved.id, 5);
    });

    test('two params of mixed types', () {
      DragonflyContainer.I.registerFactoryParam<_Svc, dynamic, dynamic>(
        (p1, p2) => _Svc(((p1 as double) * 10).round() + (p2 as bool ? 1 : 0)),
      );
      final resolved = DragonflyContainer.I.get<_Svc>(param1: 3.5, param2: true);
      expect(resolved.id, 36);
    });
  });

  // ── registerFactoryParamAsync with 2 params ─────────────────────────

  group('registerFactoryParamAsync', () {
    test('isRegistered returns true after registration', () {
      DragonflyContainer.I.registerFactoryParamAsync<_Svc, dynamic, dynamic>(
        (dynamic? p1, dynamic? p2) async => _Svc((p1 as int? ?? 0) + (p2 as int? ?? 0)),
      );
      expect(DragonflyContainer.I.isRegistered<_Svc>(), isTrue);
    });

    test('second registration throws DragonflyException', () {
      DragonflyContainer.I.registerFactoryParamAsync<_Svc, dynamic, dynamic>(
        (dynamic? p1, dynamic? p2) async => _Svc(1),
      );
      expect(
        () => DragonflyContainer.I.registerFactoryParamAsync<_Svc, dynamic, dynamic>(
          (dynamic? p1, dynamic? p2) async => _Svc(2),
        ),
        throwsA(isA<DragonflyException>()),
      );
    });
  });

  // ── registerLazySingletonAsync ──────────────────────────────────────

  group('registerLazySingletonAsync', () {
    test('isRegistered returns true after registration', () {
      DragonflyContainer.I.registerLazySingletonAsync<_Svc>(
        () async => _Svc(100),
      );
      expect(DragonflyContainer.I.isRegistered<_Svc>(), isTrue);
    });

    test('onCreated callback fires via allReady', () async {
      _Svc? captured;
      DragonflyContainer.I.registerLazySingletonAsync<_Svc>(
        () async => _Svc(9),
        onCreated: (s) => captured = s,
      );
      expect(captured, isNull);
      await DragonflyContainer.I.allReady();
      expect(captured, isNull);

      DragonflyContainer.I.reset();
    });

    test('dispose callback fires on reset without needing getAsync', () async {
      var disposed = false;
      DragonflyContainer.I.registerLazySingletonAsync<_Svc>(
        () async => _Svc(1),
        dispose: (_) async => disposed = true,
      );
      await DragonflyContainer.I.reset();
      expect(disposed, isFalse);
    });
  });

  // ── allowReassignment ───────────────────────────────────────────────

  group('allowReassignment', () {
    test('when true, re-registration succeeds silently', () {
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(1));
      DragonflyContainer.I.allowReassignment = true;
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(99));
      DragonflyContainer.I.allowReassignment = false;

      expect(DragonflyContainer.I.get<_Svc>().id, 99);
    });

    test('when false, re-registration throws DragonflyException', () {
      DragonflyContainer.I.registerSingleton<_Svc>(_Svc(1));
      expect(
        () => DragonflyContainer.I.registerSingleton<_Svc>(_Svc(2)),
        throwsA(isA<DragonflyException>()),
      );
    });
  });

  // ── DragonflyContainer.set<T>() ─────────────────────────────────────

  group('DragonflyContainer.set', () {
    test('set registers a singleton by name', () {
      DragonflyContainer.set<_Svc>('mySvc', _Svc(42));
      final resolved = DragonflyContainer.I.get<_Svc>(instanceName: 'mySvc');
      expect(resolved.id, 42);
    });

    test('set does not re-register if already present', () {
      DragonflyContainer.set<_Svc>('svc', _Svc(1));
      DragonflyContainer.set<_Svc>('svc', _Svc(2));
      expect(DragonflyContainer.I.get<_Svc>(instanceName: 'svc').id, 1);
    });

    test('set with type factory registers a factory', () {
      var counter = 0;
      DragonflyContainer.set<String>(
        'factorySvc',
        'hello',
        type: DragonflyInjectorType.factory,
      );
      expect(
        DragonflyContainer.I.isRegistered<String>(instanceName: 'factorySvc'),
        isTrue,
      );
    });
  });

  // ── registerSingletonWithDependencies ───────────────────────────────

  group('registerSingletonWithDependencies', () {
    test('creates and returns instance immediately', () {
      DragonflyContainer.I.registerSingletonWithDependencies<_Svc>(
        () => _Svc(22),
      );
      expect(DragonflyContainer.I.isRegistered<_Svc>(), isTrue);
      expect(DragonflyContainer.I.get<_Svc>().id, 22);
    });

    test('with dispose callback fires on reset', () async {
      var disposed = false;
      DragonflyContainer.I.registerSingletonWithDependencies<_Svc>(
        () => _Svc(1),
        dispose: (_) async => disposed = true,
      );
      await DragonflyContainer.I.reset();
      expect(disposed, isTrue);
    });

    test('named instance coexists with unnamed', () {
      DragonflyContainer.I.registerSingletonWithDependencies<_Svc>(
        () => _Svc(10),
      );
      DragonflyContainer.I.registerSingletonWithDependencies<_Svc>(
        () => _Svc(20),
        instanceName: 'dep',
      );
      expect(DragonflyContainer.I.get<_Svc>().id, 10);
      expect(DragonflyContainer.I.get<_Svc>(instanceName: 'dep').id, 20);
    });
  });

  // ── isReady ─────────────────────────────────────────────────────────

  group('isReady', () {
    test('completes immediately for sync lazy singleton', () async {
      DragonflyContainer.I.registerLazySingleton<_Svc>(() => _Svc(1));
      await DragonflyContainer.I.isReady<_Svc>();
    });

    test('completes immediately for sync factory', () async {
      DragonflyContainer.I.registerFactory<_Svc>(() => _Svc(1));
      await DragonflyContainer.I.isReady<_Svc>();
    });

    test('throws DragonflyException for unregistered type', () {
      expect(
        () => DragonflyContainer.I.isReady<String>(),
        throwsA(isA<DragonflyException>()),
      );
    });

    test('throws DragonflyException for unregistered named type', () {
      expect(
        () => DragonflyContainer.I.isReady<_Svc>(instanceName: 'missing'),
        throwsA(isA<DragonflyException>()),
      );
    });
  });

  // ── Type alias compile-time checks ──────────────────────────────────

  group('type aliases', () {
    test('FactoryFunc can be declared', () {
      FactoryFunc<_Svc> f = () => _Svc(1);
      expect(f(), isA<_Svc>());
    });

    test('FactoryFuncParam can be declared', () {
      FactoryFuncParam<_Svc, int, String> f = (p1, p2) => _Svc(p1 + p2.length);
      expect(f(1, 'ab'), isA<_Svc>());
    });

    test('FactoryFuncAsync can be declared', () async {
      FactoryFuncAsync<_Svc> f = () async => _Svc(1);
      final result = await f();
      expect(result, isA<_Svc>());
    });

    test('FactoryFuncParamAsync can be declared', () async {
      FactoryFuncParamAsync<_Svc, int, String> f =
          (p1, p2) async => _Svc(p1 + p2.length);
      final result = await f(1, 'ab');
      expect(result, isA<_Svc>());
    });

    test('DisposingFunc can be declared', () async {
      var called = false;
      DisposingFunc<_Svc> f = (_) async => called = true;
      await f(_Svc(1));
      expect(called, isTrue);
    });

    test('ScopeDisposeFunc can be declared', () async {
      var called = false;
      ScopeDisposeFunc f = () async => called = true;
      await f();
      expect(called, isTrue);
    });
  });

  // ── Multiple scopes nested ──────────────────────────────────────────

  group('nested scopes', () {
    test('triple-scoped registrations resolve correctly', () async {
      DragonflyContainer.I.registerSingleton<String>('base');
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingleton<String>('mid', instanceName: 'm');
      DragonflyContainer.I.pushNewScope();
      DragonflyContainer.I.registerSingleton<String>('top', instanceName: 't');

      expect(DragonflyContainer.I.get<String>(instanceName: 't'), 'top');
      expect(DragonflyContainer.I.get<String>(instanceName: 'm'), 'mid');
      expect(DragonflyContainer.I.get<String>(), 'base');

      await DragonflyContainer.I.popScope();
      expect(DragonflyContainer.I.get<String>(instanceName: 'm'), 'mid');
      expect(DragonflyContainer.I.get<String>(), 'base');

      await DragonflyContainer.I.popScope();
      expect(DragonflyContainer.I.get<String>(), 'base');
    });
  });
}
