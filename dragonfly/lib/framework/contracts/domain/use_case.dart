import 'package:dragonfly/framework/functional/either.dart';

/// Base interface for use cases.
/// Implement this with your own call signature.
///
/// Example with single param:
/// ```dart
/// class GetUserUseCase implements UseCase<int, Exception, User> {
///   Future<Either<Exception, User>> call(int userId) async { ... }
/// }
/// ```
///
/// Example with multiple params using a record:
/// ```dart
/// class SearchUseCase implements UseCase<({String query, int page}), Exception, List<Item>> {
///   Future<Either<Exception, List<Item>>> call(({String query, int page}) params) async { ... }
/// }
/// ```
abstract interface class UseCase<Params, Error, Response> {
  // No enforced call signature - implement your own
}

/// Use case with a single parameter
abstract interface class UseCaseWithParams<Params, Error, Response>
    implements UseCase<Params, Error, Response> {
  Future<Either<Error, Response>> call(Params params);
}

/// Use case with no parameters
abstract interface class UseCaseNoParams<Error, Response>
    implements UseCase<void, Error, Response> {
  Future<Either<Error, Response>> call();
}
