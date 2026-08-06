import 'package:dragonfly/framework/state/state_builder.dart';
import 'package:dragonfly/framework/state/state_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterController extends DragonflyController<int> {
  _CounterController() : super(0);

  void increment() => emit(state + 1);

  void emitPublic(int value) => emit(value);
}

void main() {
  group('DragonflyController', () {
    test('starts with the initial state', () {
      final controller = _CounterController();
      expect(controller.state, 0);
      expect(controller.isDisposed, isFalse);
      controller.dispose();
    });

    test('emit replaces the state and notifies the stream', () async {
      final controller = _CounterController();
      final states = <int>[];
      final sub = controller.stream.listen(states.add);

      controller.increment();
      controller.increment();

      expect(controller.state, 2);
      await Future<void>.delayed(Duration.zero);
      expect(states, [1, 2]);

      await sub.cancel();
      controller.dispose();
    });

    test('emit after dispose is a no-op', () async {
      final controller = _CounterController();
      final states = <int>[];
      final sub = controller.stream.listen(states.add);

      controller.dispose();
      controller.emitPublic(42);

      expect(controller.state, 0);
      await Future<void>.delayed(Duration.zero);
      expect(states, isEmpty);

      await sub.cancel();
    });

    test('dispose is idempotent', () {
      final controller = _CounterController();
      controller.dispose();
      expect(() => controller.dispose(), returnsNormally);
      expect(controller.isDisposed, isTrue);
    });

    test('logging is disabled by default', () {
      final controller = _CounterController();
      expect(controller.loggingEnabled, isFalse);
      controller.dispose();
    });

    test('schedule applies the debounce policy', () async {
      final controller = _CounterController();
      var runs = 0;

      controller.schedule(
        'bump',
        () => runs++,
        debounce: const Duration(milliseconds: 50),
      );
      controller.schedule(
        'bump',
        () => runs++,
        debounce: const Duration(milliseconds: 50),
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(runs, 1, reason: 'only the last debounced call runs');
      controller.dispose();
    });

    test('schedule returns false after dispose', () {
      final controller = _CounterController();
      controller.dispose();
      expect(controller.schedule('x', () {}), isFalse);
    });
  });

  group('DragonflyStateBuilder', () {
    testWidgets('builds with the current state synchronously', (tester) async {
      final controller = _CounterController();

      await tester.pumpWidget(
        DragonflyStateBuilder<int>(
          controller: controller,
          builder: (context, state) => Text('count:$state', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('count:0'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('rebuilds on emit and respects buildWhen', (tester) async {
      final controller = _CounterController();

      await tester.pumpWidget(
        DragonflyStateBuilder<int>(
          controller: controller,
          buildWhen: (previous, current) => current.isEven,
          builder: (context, state) => Text('count:$state', textDirection: TextDirection.ltr),
        ),
      );

      controller.increment(); // 1 — dropped by buildWhen
      // Broadcast-stream delivery lands after the pumped frame; the extra
      // pump flushes the pending microtasks.
      await tester.pump();
      await tester.pump();
      expect(find.text('count:0'), findsOneWidget);

      controller.increment(); // 2 — passes
      await tester.pump();
      await tester.pump();
      expect(find.text('count:2'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('stops listening after dispose of the widget', (tester) async {
      final controller = _CounterController();

      await tester.pumpWidget(
        DragonflyStateBuilder<int>(
          controller: controller,
          builder: (context, state) => Text('count:$state', textDirection: TextDirection.ltr),
        ),
      );
      await tester.pumpWidget(const SizedBox());

      // No exception and no rebuild work happens when the stream closes.
      controller.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
