import 'dart:async';

import 'package:dragonfly/framework/state/state_controller.dart';

/// The collected result of a [controllerTest] run.
///
/// Holds the [controller] for inspecting sync state and the [states] list
/// containing every emission that arrived on the controller's stream.
class ControllerResult<S> {
  ControllerResult(this.controller, this.states);

  /// The controller under test. Check [DragonflyController.state] for the
  /// synchronous current state, or call `controller.dispose()` if you need
  /// early cleanup.
  final DragonflyController<S> controller;

  /// Every state emitted to `controller.stream`, in order.
  ///
  /// The initial state is **not** included — only explicit [emit] calls
  /// appear here. This matches the behaviour of generated controllers, where
  /// loading, result, and error variants are emitted explicitly.
  final List<S> states;

  /// Fast-forwards any debounced/throttled dispatch pending on [key], then
  /// pumps the stream so the result arrives in [states].
  ///
  /// ```dart
  /// await controllerTest(
  ///   () => $SearchController(),
  ///   act: (c) => c.search('Rick'),   // debounced by 300 ms
  ///   expect: (r) async {
  ///     await r.flush('search');      // runs the pending call now
  ///     expect(r.states, [isA<SearchLoaded>()]);
  ///   },
  /// );
  /// ```
  Future<void> flush(String key) async {
    controller.flushScheduled(key);
    await _pump();
  }

  /// Pump the microtask queue once. Call repeatedly if the controller
  /// performs multiple async steps.
  Future<void> pump() => _pump();
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

/// Tests a [DragonflyController] in a strict 3-step lifecycle:
/// **build → act → expect**, with automatic stream collection and cleanup.
///
/// This is the primary TDD entry point for Dragonfly state managers. It is
/// deliberately minimal — three callbacks, zero hidden parameters — so AI
/// agents and developers can write tests with minimal ceremony.
///
/// ### Lifecycle
///
/// 1. Call [create] to build the controller.
/// 2. Subscribe to `controller.stream` to collect all emitted states.
/// 3. Run [act], passing the controller so test code can call event methods.
/// 4. Pump the microtask queue twice — once for the synchronous [emit]
///    delivery, once for any async completion that follows.
/// 5. Call [expect] with a [ControllerResult] holding the controller and the
///    collected [states].
/// 6. Cancel the stream subscription and call `controller.dispose()` in a
///    `finally` block.
///
/// ### Example
///
/// ```dart
/// await controllerTest(
///   () => $CharacterStateManagerController(mockDelegate),
///   act: (c) => c.fetchCharacters(),
///   expect: (r) {
///     expect(r.states[0], isA<CharacterStateLoading>());
///     expect(r.states[1], isA<CharacterStateLoaded>());
///     expect(r.controller.state, isA<CharacterStateLoaded>());
///   },
/// );
/// ```
///
/// ### Debounced / throttled events
///
/// Use [ControllerResult.flush] instead of real timers:
///
/// ```dart
/// await controllerTest(
///   () => $SearchController(),
///   act: (c) => c.search('Rick'),
///   expect: (r) async {
///     await r.flush('search');
///     expect(r.states, [isA<SearchLoaded>()]);
///   },
/// );
/// ```
///
/// ### Manual extra pumps
///
/// If the controller does multiple async rounds, call [ControllerResult.pump]:
///
/// ```dart
/// expect: (r) async {
///   await r.pump();   // loading
///   await r.pump();   // result
///   expect(r.states.length, 2);
/// },
/// ```
Future<void> controllerTest<S>(
  DragonflyController<S> Function() create, {
  required Future<void> Function(DragonflyController<S> controller) act,
  required FutureOr<void> Function(ControllerResult<S> result) expect,
}) async {
  final controller = create();
  final states = <S>[];
  final sub = controller.stream.listen(states.add);

  try {
    await act(controller);

    await _pump(); // synchronous emit → stream delivery
    await _pump(); // async event completion → result emission

    final result = ControllerResult<S>(controller, states);
    await expect(result);
  } finally {
    await sub.cancel();
    controller.dispose();
  }
}

/// A simple stream collector for manual-style tests where you want full
/// control over the lifecycle.
///
/// Prefer [controllerTest] for most cases. Use this when you need to
/// interleave assertions between multiple actions without the 3-step
/// lifecycle.
///
/// ### Example
///
/// ```dart
/// final controller = $CounterController();
/// final states = ControllerStates<int>(controller);
///
/// controller.increment();
/// await states.pump();
/// expect(states.events, [1]);
///
/// controller.increment();
/// await states.pump();
/// expect(states.events, [1, 2]);
///
/// states.dispose();
/// controller.dispose();
/// ```
class ControllerStates<S> {
  ControllerStates(this.controller) {
    _sub = controller.stream.listen(_states.add);
  }

  /// The controller being observed.
  final DragonflyController<S> controller;

  final List<S> _states = [];
  late final StreamSubscription<S> _sub;

  /// Every state that arrived on the stream since creation.
  List<S> get events => List.unmodifiable(_states);

  /// Pump the microtask queue so pending stream deliveries arrive.
  Future<void> pump() => _pump();

  /// Fast-forward a debounced/throttled dispatch and pump.
  Future<void> flush(String key) async {
    controller.flushScheduled(key);
    await _pump();
  }

  /// Cancel the stream subscription. Does NOT dispose the controller.
  void dispose() => _sub.cancel();
}

/// Pump the microtask queue once. Use in manual tests to flush stream
/// deliveries after an [emit].
///
/// ```dart
/// controller.emit(42);
/// await pump();
/// expect(listener.states, [42]);
/// ```
Future<void> pump() => _pump();
