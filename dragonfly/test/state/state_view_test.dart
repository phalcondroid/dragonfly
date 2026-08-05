import 'package:dragonfly/dragonfly.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal state used across the view tests.
class CounterState {
  const CounterState({required this.count, required this.label});

  final int count;
  final String label;

  CounterState copyWith({int? count, String? label}) =>
      CounterState(count: count ?? this.count, label: label ?? this.label);
}

/// An app-defined side effect the framework knows nothing about.
class OpenPaymentSheet extends StateManagerSideEffect {
  const OpenPaymentSheet(this.token);
  final String token;
}

class CounterManager extends StateManager<CounterState> {
  CounterManager() : super(const CounterState(count: 0, label: 'a'));

  void increment() => emit(state.copyWith(count: state.count + 1));

  void relabel(String label) => emit(state.copyWith(label: label));

  void search(String term) => scheduleAction(
        'search',
        () => emit(state.copyWith(label: term)),
        debounce: const Duration(milliseconds: 20),
      );

  void notify(String message) => sideEffect(ShowSnackbar(message));

  void goTo(String route) => sideEffect(NavigateTo(route));

  void emitCustom(StateManagerSideEffect effect) => sideEffect(effect);
}

class CounterScreen extends StateView<CounterManager, CounterState> {
  const CounterScreen({super.key, this.onBuild});

  final VoidCallback? onBuild;

  @override
  Widget buildState(
      BuildContext context, CounterState state, CounterManager manager) {
    onBuild?.call();
    return Column(
      children: [
        Text('count:${state.count}'),
        Text('label:${state.label}'),
      ],
    );
  }
}

/// Only rebuilds when the count changes.
class CountOnlyScreen extends StateView<CounterManager, CounterState> {
  const CountOnlyScreen({super.key, required this.onBuild});

  final VoidCallback onBuild;

  @override
  bool buildWhen(CounterState previous, CounterState current) =>
      previous.count != current.count;

  @override
  Widget buildState(
      BuildContext context, CounterState state, CounterManager manager) {
    onBuild();
    return Text('count:${state.count} label:${state.label}');
  }
}

Widget _host(Widget child, {CounterManager? manager}) {
  return MaterialApp(
    home: Scaffold(
      body: StateScope<CounterManager>(
        create: (_) => manager ?? CounterManager(),
        child: child,
      ),
    ),
  );
}

void main() {
  group('StateView', () {
    testWidgets('renders the current state and rebuilds on emit',
        (tester) async {
      final manager = CounterManager();
      await tester.pumpWidget(_host(const CounterScreen(), manager: manager));

      expect(find.text('count:0'), findsOneWidget);

      manager.increment();
      await tester.pumpAndSettle();

      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('buildWhen suppresses rebuilds but keeps state current',
        (tester) async {
      final manager = CounterManager();
      var builds = 0;
      await tester.pumpWidget(
        _host(CountOnlyScreen(onBuild: () => builds++), manager: manager),
      );

      expect(builds, 1);

      manager.relabel('ignored');
      await tester.pumpAndSettle();
      expect(builds, 1, reason: 'label change must not rebuild');

      manager.increment();
      await tester.pumpAndSettle();
      expect(builds, 2);
      expect(
        find.text('count:1 label:ignored'),
        findsOneWidget,
        reason: 'the suppressed label change is still reflected',
      );
    });

    testWidgets('exposes the manager so the view can call actions',
        (tester) async {
      final manager = CounterManager();
      await tester.pumpWidget(_host(const CounterScreen(), manager: manager));

      final context = tester.element(find.text('count:0'));
      expect(context.stateManager<CounterManager>(), same(manager));
    });
  });

  group('StateSelector', () {
    testWidgets('rebuilds only when the selected value changes',
        (tester) async {
      final manager = CounterManager();
      var builds = 0;

      await tester.pumpWidget(
        _host(
          StateSelector<CounterManager, CounterState, int>(
            selector: (state) => state.count,
            builder: (context, count) {
              builds++;
              return Text('selected:$count');
            },
          ),
          manager: manager,
        ),
      );

      expect(builds, 1);
      expect(find.text('selected:0'), findsOneWidget);

      manager.relabel('other');
      await tester.pumpAndSettle();
      expect(builds, 1, reason: 'unselected slice changed');

      manager.increment();
      await tester.pumpAndSettle();
      expect(builds, 2);
      expect(find.text('selected:1'), findsOneWidget);
    });
  });

  group('StateScope', () {
    testWidgets('applies ShowSnackbar without an extra handler widget',
        (tester) async {
      final manager = CounterManager();
      await tester.pumpWidget(_host(const CounterScreen(), manager: manager));

      manager.notify('saved');
      await tester.pumpAndSettle();

      expect(find.text('saved'), findsOneWidget);
    });

    testWidgets('an override replaces the default effect handling',
        (tester) async {
      final manager = CounterManager();
      final seen = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateScope<CounterManager>(
              create: (_) => manager,
              onSnackbar: (context, effect) => seen.add(effect.message),
              child: const CounterScreen(),
            ),
          ),
        ),
      );

      manager.notify('intercepted');
      await tester.pumpAndSettle();

      expect(seen, ['intercepted']);
      expect(find.text('intercepted'), findsNothing);
    });

    testWidgets('custom effects are routed to onEffect, built-ins are not',
        (tester) async {
      final manager = CounterManager();
      final seen = <StateManagerSideEffect>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateScope<CounterManager>(
              create: (_) => manager,
              onSnackbar: (_, __) {},
              onEffect: (context, effect) => seen.add(effect),
              child: const CounterScreen(),
            ),
          ),
        ),
      );

      manager.emitCustom(const OpenPaymentSheet('tok_123'));
      await tester.pumpAndSettle();

      expect(seen, hasLength(1));
      expect((seen.single as OpenPaymentSheet).token, 'tok_123');

      // ShowSnackbar is a built-in effect, so it must not reach onEffect.
      manager.notify('hello');
      await tester.pumpAndSettle();
      expect(seen, hasLength(1));
    });

    testWidgets('disposes the manager with the subtree', (tester) async {
      final manager = CounterManager();
      await tester.pumpWidget(_host(const CounterScreen(), manager: manager));

      expect(manager.isDisposed, isFalse);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(manager.isDisposed, isTrue);
    });
  });

  group('StateManager.scheduleAction', () {
    testWidgets('debounced action emits once for a burst', (tester) async {
      final manager = CounterManager();
      await tester.pumpWidget(_host(const CounterScreen(), manager: manager));

      manager.search('a');
      manager.search('ab');
      manager.search('abc');
      await tester.pump();

      expect(find.text('label:a'), findsOneWidget,
          reason: 'nothing has fired yet');

      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('label:abc'), findsOneWidget);
    });

    testWidgets('a pending debounced action cannot fire after dispose',
        (tester) async {
      final manager = CounterManager();
      await tester.pumpWidget(_host(const CounterScreen(), manager: manager));

      manager.search('late');
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Would throw "Cannot add new events after calling close" if the pending
      // timer survived disposal.
      await tester.pump(const Duration(milliseconds: 60));
      expect(manager.isDisposed, isTrue);
    });
  });
}
