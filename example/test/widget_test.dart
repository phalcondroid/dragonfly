import 'package:flutter_test/flutter_test.dart';

import 'package:example/components/characters/config/app_config.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('app builds without error', (WidgetTester tester) async {
    final config = AppConfig();
    await tester.pumpWidget(MyApp(config: config));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
