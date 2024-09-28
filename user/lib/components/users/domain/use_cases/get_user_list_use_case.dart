import 'package:dragonfly/core/framework/contracts/functional/either.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/core/framework/contracts/domain/use_case.dart';
import 'package:user/components/users/data/factories/user_response.dart';
import 'package:user/components/users/data/repositories/user_repository.dart';
import 'package:user/components/users/domain/use_cases/contracts/user_params.dart';
import 'package:user/components/users/exceptions/user_exception.dart';

@BusinessComponent()
class GetUserListUseCase
    implements UseCase<UserParams, UserException, UserResponse> {
  final UserRepository userRepository;

  const GetUserListUseCase({required this.userRepository});

  @override
  Future<Either<UserException, UserResponse>> exec(UserParams params) {
    try {
      return UserResponse(
          userId: 1,
          name: "name",
          lastname: "kaka",
          age: 12,
          active: true,
          creation: DateTime.now(),
          devices: []);
    } catch (e) {
      return UserException();
    }
  }
}
