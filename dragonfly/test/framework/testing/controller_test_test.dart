import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal controller for demonstrating TDD patterns.
class _CounterController extends DragonflyController<int> {
  _CounterController() : super(0);

  Future<void> increment() async {
    emit(state + 1);
  }

  void syncIncrement() => emit(state + 1);
}

/// State model used in the loading/error example.
sealed class _LoadState {}
class _LoadLoading extends _LoadState {}
class _LoadResult extends _LoadState {
  _LoadResult(this.value);
  final String value;
}
class _LoadError extends _LoadState {
  _LoadError(this.message);
  final String message;
}

class _AsyncController extends DragonflyController<_LoadState> {
  _AsyncController() : super(_LoadLoading());

  Future<void> fetch(String id) async {
    emit(_LoadLoading());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    emit(_LoadResult('data-$id'));
  }

  Future<void> fail() async {
    emit(_LoadLoading());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    emit(_LoadError('not found'));
  }
}

void main() {
  group('controllerTest (primary TDD entry point)', () {
    test('captures emitted states after an async event', () async {
      final controller = _CounterController();
      await controllerTest<int>(
        () => controller,
        act: (_) => controller.increment(),
        expect: (r) {
          expect(r.states, [1]);
          expect(r.controller.state, 1);
        },
      );
    });

    test('auto-disposes the controller after the test', () async {
      DragonflyController<int>? captured;
      await controllerTest<int>(
        () {
          final c = _CounterController();
          captured = c;
          return c;
        },
        act: (_) async {},
        expect: (_) {},
      );
      expect(captured!.isDisposed, isTrue);
    });

    test('supports multiple emissions in one act', () async {
      final controller = _CounterController();
      await controllerTest<int>(
        () => controller,
        act: (_) async {
          controller.syncIncrement();
          controller.syncIncrement();
          controller.syncIncrement();
        },
        expect: (r) {
          expect(r.states, [1, 2, 3]);
        },
      );
    });

    test('excludes initial state from collected state list', () async {
      await controllerTest<int>(
        () => _CounterController(),
        act: (_) async {},
        expect: (r) {
          expect(r.states, isEmpty);
          expect(r.controller.state, 0);
        },
      );
    });

    test('captures loading → result sequence from async events', () async {
      final controller = _AsyncController();
      await controllerTest<_LoadState>(
        () => controller,
        act: (_) => controller.fetch('42'),
        expect: (r) {
          expect(r.states[0], isA<_LoadLoading>());
          expect(r.states[1], isA<_LoadResult>());
          expect((r.states[1] as _LoadResult).value, 'data-42');
        },
      );
    });

    test('captures loading → error sequence from failing events', () async {
      final controller = _AsyncController();
      await controllerTest<_LoadState>(
        () => controller,
        act: (_) => controller.fail(),
        expect: (r) {
          expect(r.states[0], isA<_LoadLoading>());
          expect(r.states[1], isA<_LoadError>());
          expect((r.states[1] as _LoadError).message, 'not found');
        },
      );
    });
  });

  group('ControllerResult.flush (debounce/throttle)', () {
    test('fast-forwards a debounced event without real timers', () async {
      final controller = _CounterController();
      await controllerTest<int>(
        () => controller,
        act: (_) async {
          controller.schedule(
            'bump',
            () => controller.syncIncrement(),
            debounce: const Duration(seconds: 10),
          );
        },
        expect: (r) async {
          expect(r.states, isEmpty);
          await r.flush('bump');
          expect(r.states, [1]);
          expect(r.controller.state, 1);
        },
      );
    });
  });

  group('ControllerStates (manual lifecycle)', () {
    test('allows interleaving actions and assertions', () async {
      final controller = _CounterController();
      final cs = ControllerStates<int>(controller);

      controller.syncIncrement();
      await cs.pump();
      expect(cs.events, [1]);
      expect(controller.state, 1);

      controller.syncIncrement();
      controller.syncIncrement();
      await cs.pump();
      expect(cs.events, [1, 2, 3]);

      cs.dispose();
      controller.dispose();
    });
  });

  group('pump (standalone)', () {
    test('flushes stream deliveries after a direct emit call', () async {
      final controller = _CounterController();
      final states = <int>[];
      final sub = controller.stream.listen(states.add);

      controller.syncIncrement();
      await pump();
      expect(states, [1]);

      await sub.cancel();
      controller.dispose();
    });
  });
}
