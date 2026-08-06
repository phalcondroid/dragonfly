import 'package:dragonfly/framework/state/state_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/mock_controller.dart';

void main() {
  group('DragonflyStateBuilder golden', () {
    testWidgets('renders initial state', (tester) async {
      final controller = MockController<String>('Hello Dragonfly');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DragonflyStateBuilder<String>(
                controller: controller,
                builder: (context, state) => Text(
                  state,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(DragonflyStateBuilder<String>),
        matchesGoldenFile('goldens/dragonfly_state_builder_initial.png'),
      );

      controller.dispose();
    });
  });
}
