import 'package:test/test.dart';

import 'package:dragonfly_annotations/dragonfly_annotations.dart';

void main() {
  group('annotation defaults', () {
    test('FactoryModel defaults match the documented behaviour', () {
      const model = FactoryModel();
      expect(model.copyWith, isFalse);
      expect(model.generic, isFalse);
      expect(model.isList, isFalse);
      expect(model.toJson, isTrue);
      expect(model.toMap, isTrue);
      expect(model.equals, isTrue);
      expect(model.toStringMethod, isTrue);
    });

    test('Repository defaults to the shared http connection', () {
      const repo = Repository();
      expect(repo.url, isEmpty);
      expect(repo.connection, 'defaultHttpNetwork');
      expect(repo.instanceName, isNull);
    });

    test('DragonflyStateManager is injectable by default', () {
      const sm = DragonflyStateManager();
      expect(sm.injectable, isTrue);
      expect(sm.logging, isFalse);
      expect(sm.order, 100);
    });

    test('DragonflyScreen defaults to guest access', () {
      const screen = DragonflyScreen(path: '/home');
      expect(screen.access, AccessLevel.guest);
      expect(screen.initial, isFalse);
      expect(screen.transition, ScreenTransition.fade);
      expect(screen.roles, isEmpty);
      expect(screen.permissions, isEmpty);
    });

    test('Path and Query take a named value argument', () {
      const path = Path(value: 'id');
      const query = Query(value: 'name');
      expect(path.value, 'id');
      expect(query.value, 'name');
      expect(const Path().value, isEmpty);
    });
  });
}
