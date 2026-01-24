/// Represents a value of one of two possible types (a disjoint union).
/// An instance of Either is either an instance of [Left] or [Right].
///
/// [L] is the type of the Left value (typically used for errors)
/// [R] is the type of the Right value (typically used for success)
sealed class Either<L, R> {
  const Either();

  /// Creates a [Right] containing the given [value].
  factory Either.right(R value) => Right(value);

  /// Creates a [Left] containing the given [value].
  factory Either.left(L value) => Left(value);

  /// Returns true if this is a [Right], false otherwise.
  bool get isRight;

  /// Returns true if this is a [Left], false otherwise.
  bool get isLeft;

  /// Returns the [Right] value or throws if this is a [Left].
  R getRight();

  /// Returns the [Left] value or throws if this is a [Right].
  L getLeft();

  /// Returns the [Right] value or [defaultValue] if this is a [Left].
  R getOrElse(R defaultValue);

  /// Returns the [Right] value or computes it from [orElse] if this is a [Left].
  R getOrElseCompute(R Function(L left) orElse);

  /// Applies [onLeft] if this is a [Left] or [onRight] if this is a [Right].
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight);

  /// Maps the [Right] value using [f].
  Either<L, T> map<T>(T Function(R right) f);

  /// Maps the [Left] value using [f].
  Either<T, R> mapLeft<T>(T Function(L left) f);

  /// FlatMaps the [Right] value using [f].
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) f);

  /// Swaps [Left] and [Right].
  Either<R, L> swap();

  /// Executes a try-catch and returns [Right] on success or [Left] on error.
  ///
  /// Example:
  /// ```dart
  /// final result = Either.tryCatch(
  ///   () => int.parse('42'),
  ///   (error, stackTrace) => 'Failed to parse: $error',
  /// );
  /// ```
  static Either<L, R> tryCatch<L, R>(
    R Function() run,
    L Function(Object error, StackTrace stackTrace) onError,
  ) {
    try {
      return Right(run());
    } catch (e, st) {
      return Left(onError(e, st));
    }
  }

  /// Async version of [tryCatch].
  ///
  /// Example:
  /// ```dart
  /// final result = await Either.tryCatchAsync(
  ///   () async => await fetchData(),
  ///   (error, stackTrace) => NetworkError(error.toString()),
  /// );
  /// ```
  static Future<Either<L, R>> tryCatchAsync<L, R>(
    Future<R> Function() run,
    L Function(Object error, StackTrace stackTrace) onError,
  ) async {
    try {
      return Right(await run());
    } catch (e, st) {
      return Left(onError(e, st));
    }
  }

  /// Converts a nullable value to Either.
  /// Returns [Right] if value is not null, otherwise [Left] with [onNull].
  static Either<L, R> fromNullable<L, R>(R? value, L Function() onNull) {
    if (value != null) {
      return Right(value);
    }
    return Left(onNull());
  }

  /// Combines two Either values.
  /// If both are [Right], applies [combine] to their values.
  /// If either is [Left], returns the first [Left].
  static Either<L, C> map2<L, A, B, C>(
    Either<L, A> ea,
    Either<L, B> eb,
    C Function(A a, B b) combine,
  ) {
    return ea.flatMap((a) => eb.map((b) => combine(a, b)));
  }
}

/// Represents the left side of [Either], typically used for errors.
final class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);

  @override
  bool get isRight => false;

  @override
  bool get isLeft => true;

  @override
  R getRight() => throw StateError('Cannot get Right value from Left');

  @override
  L getLeft() => value;

  @override
  R getOrElse(R defaultValue) => defaultValue;

  @override
  R getOrElseCompute(R Function(L left) orElse) => orElse(value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      onLeft(value);

  @override
  Either<L, T> map<T>(T Function(R right) f) => Left(value);

  @override
  Either<T, R> mapLeft<T>(T Function(L left) f) => Left(f(value));

  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) f) => Left(value);

  @override
  Either<R, L> swap() => Right(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Left<L, R> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Left($value)';
}

/// Represents the right side of [Either], typically used for success values.
final class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);

  @override
  bool get isRight => true;

  @override
  bool get isLeft => false;

  @override
  R getRight() => value;

  @override
  L getLeft() => throw StateError('Cannot get Left value from Right');

  @override
  R getOrElse(R defaultValue) => value;

  @override
  R getOrElseCompute(R Function(L left) orElse) => value;

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      onRight(value);

  @override
  Either<L, T> map<T>(T Function(R right) f) => Right(f(value));

  @override
  Either<T, R> mapLeft<T>(T Function(L left) f) => Right(value);

  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) f) => f(value);

  @override
  Either<R, L> swap() => Left(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Right<L, R> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Right($value)';
}

/// Extension methods for Either
extension EitherExtensions<L, R> on Either<L, R> {
  /// Converts Either to a nullable Right value.
  R? toNullable() => isRight ? getRight() : null;

  /// Executes [action] if this is a [Right].
  Either<L, R> tapRight(void Function(R right) action) {
    if (isRight) action(getRight());
    return this;
  }

  /// Executes [action] if this is a [Left].
  Either<L, R> tapLeft(void Function(L left) action) {
    if (isLeft) action(getLeft());
    return this;
  }
}

/// Extension for Future<Either>
extension FutureEitherExtensions<L, R> on Future<Either<L, R>> {
  /// Maps the Right value of a Future<Either>.
  Future<Either<L, T>> mapAsync<T>(T Function(R right) f) async {
    final either = await this;
    return either.map(f);
  }

  /// FlatMaps the Right value of a Future<Either>.
  Future<Either<L, T>> flatMapAsync<T>(
      Future<Either<L, T>> Function(R right) f) async {
    final either = await this;
    if (either.isRight) {
      return f(either.getRight());
    }
    return Left(either.getLeft());
  }
}
