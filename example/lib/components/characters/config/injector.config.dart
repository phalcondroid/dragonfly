// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:dragonfly/dragonfly.dart';

import 'package:example/components/characters/data/repositories/character_repository.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:example/components/auth/presentation/features/login_state_manager.dart';
import 'package:example/components/characters/presentation/features/character_feature.dart';

extension DragonflyContainerConfigX on DragonflyContainer {
  Future<void> configureDependencies() async {
    final gh = DragonflyContainer.I;

    // Lazy Singletons
    gh.registerLazySingleton<CharacterRepository>(() => CharacterRepository());

    // Factories
    gh.registerFactory<GetUserListUseCase>(
      () => GetUserListUseCase(gh.get<CharacterRepository>()),
      instanceName: 'GetUserList',
    );
    gh.registerFactory<LoginStateManager>(() => LoginStateManager());
    gh.registerFactory<CharacterFeature>(
      () => CharacterFeature(
        gh.get<GetUserListUseCase>(instanceName: 'GetUserList'),
      ),
    );
  }
}
