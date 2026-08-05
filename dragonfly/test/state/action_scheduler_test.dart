import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActionScheduler', () {
    late ActionScheduler scheduler;

    setUp(() => scheduler = ActionScheduler());
    tearDown(() => scheduler.dispose());

    test('runs immediately when neither debounce nor throttle is given', () {
      var calls = 0;
      final ran = scheduler.run('a', () => calls++);
      expect(ran, isTrue);
      expect(calls, 1);
    });

    test('debounce collapses a burst into a single trailing call', () async {
      var calls = 0;
      const delay = Duration(milliseconds: 20);

      for (var i = 0; i < 5; i++) {
        scheduler.run('search', () => calls++, debounce: delay);
      }

      expect(calls, 0, reason: 'nothing runs until the delay elapses');
      expect(scheduler.isPending('search'), isTrue);

      await Future<void>.delayed(delay * 3);
      expect(calls, 1);
      expect(scheduler.isPending('search'), isFalse);
    });

    test('debounce keeps only the most recent body', () async {
      final seen = <int>[];
      const delay = Duration(milliseconds: 20);

      for (var i = 0; i < 3; i++) {
        scheduler.run('search', () => seen.add(i), debounce: delay);
      }

      await Future<void>.delayed(delay * 3);
      expect(seen, [2]);
    });

    test('debounce keys are independent', () async {
      final seen = <String>[];
      const delay = Duration(milliseconds: 20);

      scheduler.run('a', () => seen.add('a'), debounce: delay);
      scheduler.run('b', () => seen.add('b'), debounce: delay);

      await Future<void>.delayed(delay * 3);
      expect(seen, containsAll(<String>['a', 'b']));
      expect(seen, hasLength(2));
    });

    test('throttle runs the first call and drops those inside the window',
        () async {
      var calls = 0;
      const window = Duration(milliseconds: 40);

      expect(scheduler.run('tap', () => calls++, throttle: window), isTrue);
      expect(scheduler.run('tap', () => calls++, throttle: window), isFalse);
      expect(scheduler.run('tap', () => calls++, throttle: window), isFalse);
      expect(calls, 1);

      await Future<void>.delayed(window * 2);
      expect(scheduler.run('tap', () => calls++, throttle: window), isTrue);
      expect(calls, 2);
    });

    test('cancel drops a pending debounced call', () async {
      var calls = 0;
      const delay = Duration(milliseconds: 20);

      scheduler.run('search', () => calls++, debounce: delay);
      scheduler.cancel('search');

      await Future<void>.delayed(delay * 3);
      expect(calls, 0);
    });

    test('flush runs a pending debounced call right away', () {
      var calls = 0;
      scheduler.run('search', () => calls++,
          debounce: const Duration(seconds: 10));

      scheduler.flush('search');

      expect(calls, 1);
      expect(scheduler.isPending('search'), isFalse);
    });

    test('flush on an idle key does nothing', () {
      expect(() => scheduler.flush('nothing'), returnsNormally);
    });

    test('dispose prevents a pending call from ever firing', () async {
      var calls = 0;
      const delay = Duration(milliseconds: 20);

      scheduler.run('search', () => calls++, debounce: delay);
      scheduler.dispose();

      await Future<void>.delayed(delay * 3);
      expect(calls, 0);
      expect(scheduler.isDisposed, isTrue);
    });

    test('run after dispose is refused', () {
      var calls = 0;
      scheduler.dispose();
      expect(scheduler.run('a', () => calls++), isFalse);
      expect(calls, 0);
    });
  });
}
