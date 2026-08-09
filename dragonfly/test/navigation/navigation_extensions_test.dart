import 'dart:async';

import 'package:dragonfly/dragonfly.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContextNavigation extensions', () {
    testWidgets('push navigates to named route', (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (_) => const Text('Home'),
          '/details': (_) => const Text('Details'),
        },
      ));

      expect(find.text('Home'), findsOneWidget);

      final context = tester.element(find.text('Home'));
      unawaited(context.push('/details'));

      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('push with arguments', (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (_) => const Text('Home'),
          '/details': (context) => Text(
              ModalRoute.of(context)!.settings.arguments as String),
        },
      ));

      final context = tester.element(find.text('Home'));
      unawaited(context.push('/details', arguments: 'ARG_DATA'));

      await tester.pumpAndSettle();

      expect(find.text('ARG_DATA'), findsOneWidget);
    });

    testWidgets('replace replaces current route', (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (_) => const Text('Home'),
          '/replace': (_) => const Text('Replaced'),
        },
      ));

      final context = tester.element(find.text('Home'));
      unawaited(context.replace('/replace'));

      await tester.pumpAndSettle();

      expect(find.text('Replaced'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('pushAndRemoveUntil clears stack', (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (_) => const Text('Home'),
          '/new-root': (_) => const Text('New Root'),
        },
      ));

      final context = tester.element(find.text('Home'));
      unawaited(context.pushAndRemoveUntil('/new-root'));

      await tester.pumpAndSettle();

      expect(find.text('New Root'), findsOneWidget);
    });

    testWidgets('pop navigates back', (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (_) => const Text('Home'),
          '/details': (_) => const Text('Details'),
        },
      ));

      final homeContext = tester.element(find.text('Home'));
      unawaited(homeContext.push('/details'));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);

      final detailsContext = tester.element(find.text('Details'));
      detailsContext.pop();

      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Details'), findsNothing);
    });

    testWidgets('pop with result', (tester) async {
      Object? popResult;
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    popResult = await context.push('/details');
                  },
                  child: const Text('Go'),
                );
              },
            );
          }
          if (settings.name == '/details') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                return TextButton(
                  onPressed: () => context.pop('result_value'),
                  child: const Text('Back'),
                );
              },
            );
          }
          return null;
        },
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(popResult, 'result_value');
    });

    testWidgets('canPop returns true when stack can pop', (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (_) => const Text('Home'),
          '/details': (_) => const Text('Details'),
        },
      ));

      final homeContext = tester.element(find.text('Home'));
      unawaited(homeContext.push('/details'));
      await tester.pumpAndSettle();

      final detailsContext = tester.element(find.text('Details'));
      expect(detailsContext.canPop(), isTrue);
    });

    testWidgets('canPop returns false when no route to pop', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Text('Home'),
      ));

      final context = tester.element(find.text('Home'));
      expect(context.canPop(), isFalse);
    });

    testWidgets('goBack is an alias for pop', (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (_) => const Text('Home'),
          '/details': (_) => const Text('Details'),
        },
      ));

      final homeContext = tester.element(find.text('Home'));
      unawaited(homeContext.push('/details'));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);

      final detailsContext = tester.element(find.text('Details'));
      detailsContext.goBack();

      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
