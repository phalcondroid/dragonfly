import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/annotations/injectable/injectable_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/data/models/service_response.dart';
import 'package:example/components/characters/data/repositories/character_repository.dart';

@InjectableUseCase()
class GetUserListUseCase
    implements
        UseCase<Map<String, dynamic>, Error, ServiceResponse<Character>> {
  final CharacterRepository userRepository;

  const GetUserListUseCase(this.userRepository);

  Future<Either<Error, ServiceResponse<Character>>> call(
    String name,
    List<String> params,
  ) async {
    return await Either.tryCatchAsync(
      () => userRepository.getAll(name, params),
      (error, stackTrace) => Error(),
    );
  }
}
