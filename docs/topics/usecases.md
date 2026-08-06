# Use Cases

A use case is a plain class with a hand-written `call` method. The `@UseCase`
annotation triggers DI registration — no contract interface to implement.

```dart
@UseCase(instanceName: 'GetUserList')
class GetUserListUseCase {
  final CharacterRepository userRepository;
  const GetUserListUseCase(this.userRepository);

  Future<Either<Error, ServiceResponse<Character>>> call(String name) async {
    return Either.tryCatchAsync(
      () => userRepository.getAll(name),
      (error, _) => Error(),
    );
  }
}
```

### The `Either` type

`Either<L, R>` represents success or failure without exceptions. It is hand-written
in `framework/functional/either.dart` (no fpdart dependency):

```dart
final result = await useCase.call("Rick");

result.fold(
  (error)    => emit(CharacterState.error(message: error.toString())),
  (response) => emit(CharacterState.loaded(character: response.results.first)),
);

// Also available:
result.isRight / result.isLeft
result.getOrElse(defaultValue)
result.getOrElseCompute((left) => alt)
result.map((right) => transformed)
Either.tryCatch(() => riskySync())
Either.tryCatchAsync(() => riskyAsync())
```

In easy-mode state managers, a returned `Either<L, R>` is folded automatically:
`Right` becomes the payload variant, `Left` becomes `error`.

[← Back to README.md](../../README.md)
