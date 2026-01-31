import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/annotations/injectable/injectable_annotations.dart';

import 'injector.config.dart';

@DragonflyInjectableInit()
Future<void> initDragonflyContainer() async {
  DragonflyContainer.I.configureDependencies();
}
