import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/annotations/injectable/injectable_annotations.dart';

import 'injector.config.dart';

@DragonflyInjectableInit()
Future<void> initDragonflyContainer() async {
  final container = DragonflyContainer();
  await container.configureDependencies();
}
