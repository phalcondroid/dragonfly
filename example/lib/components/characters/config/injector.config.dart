// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:dragonfly/dragonfly.dart';

import 'package:example/components/characters/data/repositories/character_repository.dart';
import 'package:example/components/characters/domain/use_cases/get_user_list_use_case.dart';
import 'package:example/components/characters/presentation/viewmodel/character_bloc.dart';

extension DragonflyContainerConfigX on DragonflyContainer {
  Future<void> configureDependencies() async {
    final gh = DragonflyContainer.I;

// Lazy Singletons
    gh.registerLazySingleton<CharacterRepository>(() => CharacterRepository());

// Factories
    gh.registerFactory<GetUserListUseCase>(
        () => GetUserListUseCase(gh.get<CharacterRepository>()),
        instanceName: 'GetUserList');
    gh.registerFactory<CharacterBloc>(() =>
        CharacterBloc(gh.get<GetUserListUseCase>(instanceName: 'GetUserList')));
  }
}
