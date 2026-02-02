import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/data/models/service_response.dart';
import 'package:example/components/characters/data/repositories/character_repository.dart';

@InjectableUseCase(instanceName: 'GetUserList')
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
      (error, stackTrace) {
        print("===>>>> from use case: $error");
        return Error();
      },
    );
  }
}
