import 'package:dragonfly/framework/functional/either.dart';

abstract interface class UseCase<Params, Error, Response> {
  Future<Either<Error, Response>> exec(Params params);
}
