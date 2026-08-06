## 0.0.1

* Initial release — code generators for the Dragonfly framework.
* Generates model implementations (`@FactoryModel`), sealed states (`@StateModel`), repository clients (`@Repository`),
  state manager controllers (`@StateManager`), view mixins (`@StateView`), form states (`@FormSchema`),
  DI configuration (`@InjectableInit`), router config (`@RouterConfig`), and component barrel files.
* Uses `source_gen` and `analyzer` to read `dragonfly_annotations` and emit Dart code.
