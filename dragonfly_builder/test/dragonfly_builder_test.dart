import 'package:test/test.dart';

import 'package:dragonfly_builder/builder.dart';

void main() {
  test('exposes a builder factory for every declared build.yaml builder', () {
    expect(repositoryGenerator, isNotNull);
    expect(factoryModelGenerator, isNotNull);
    expect(stateModelGenerator, isNotNull);
    expect(stateManagerGenerator, isNotNull);
    expect(viewGenerator, isNotNull);
    expect(injectableConfigBuilder, isNotNull);
    expect(routerBuilder, isNotNull);
    expect(formSchemaGenerator, isNotNull);
  });
}
