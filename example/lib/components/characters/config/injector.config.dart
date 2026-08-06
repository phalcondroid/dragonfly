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
import 'package:example/components/characters/presentation/features/character_search_state_manager.dart';
import 'package:example/components/characters/presentation/features/character_state_manager.dart';

extension DragonflyContainerConfigX on DragonflyContainer {
  Future<void> configureDependencies() async {
    final gh = DragonflyContainer.I;

    // Lazy Singletons
    gh.registerLazySingleton<CharacterRepository>(() => CharacterRepository());
    gh.registerLazySingleton<$LoginStateManagerController>(
      () => $LoginStateManagerController(gh.get<LoginStateManager>()),
      dispose: (instance) => instance.dispose(),
    );
    gh.registerLazySingleton<$CharacterSearchStateManagerController>(
      () => $CharacterSearchStateManagerController(
        gh.get<CharacterSearchStateManager>(),
      ),
      dispose: (instance) => instance.dispose(),
    );
    gh.registerLazySingleton<$CharacterStateManagerController>(
      () => $CharacterStateManagerController(gh.get<CharacterStateManager>()),
      dispose: (instance) => instance.dispose(),
    );

    // Factories
    gh.registerFactory<GetUserListUseCase>(
      () => GetUserListUseCase(gh.get<CharacterRepository>()),
      instanceName: 'GetUserList',
    );
    gh.registerFactory<LoginStateManager>(() => LoginStateManager());
    gh.registerFactory<CharacterSearchStateManager>(
      () => CharacterSearchStateManager(
        gh.get<GetUserListUseCase>(instanceName: 'GetUserList'),
      ),
    );
    gh.registerFactory<CharacterStateManager>(
      () => CharacterStateManager(
        gh.get<GetUserListUseCase>(instanceName: 'GetUserList'),
      ),
    );
  }
}
