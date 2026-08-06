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

    test('StateManager is injectable by default', () {
      const sm = StateManager();
      expect(sm.state, isNull);
      expect(sm.injectable, isTrue);
      expect(sm.logging, isFalse);
    });

    test('Screen defaults to guest access', () {
      const screen = Screen(path: '/home');
      expect(screen.access, AccessLevel.guest);
      expect(screen.initial, isFalse);
      expect(screen.transition, ScreenTransition.fade);
      expect(screen.roles, isEmpty);
      expect(screen.permissions, isEmpty);
    });

    test('Path and Query accept an optional positional value', () {
      const path = Path('id');
      const query = Query('name');
      expect(path.value, 'id');
      expect(query.value, 'name');
      expect(const Path().value, isEmpty);
    });
  });
}
