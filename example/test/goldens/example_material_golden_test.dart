import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['golden'])
void main() {
  group('Example app golden smoke', () {
    testWidgets('Material theme renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: Center(
              child: Text(
                'Dragonfly Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/example_material_theme.png'),
      );
    });
  });
}
