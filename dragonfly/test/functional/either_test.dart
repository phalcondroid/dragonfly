import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly/framework/functional/either.dart'
    show EitherExtensions, FutureEitherExtensions;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Either.right', () {
    test('isRight returns true', () {
      final either = Either<String, int>.right(42);
      expect(either.isRight, isTrue);
    });

    test('isLeft returns false', () {
      final either = Either<String, int>.right(42);
      expect(either.isLeft, isFalse);
    });

    test('getRight returns the value', () {
      final either = Either<String, int>.right(42);
      expect(either.getRight(), 42);
    });

    test('getLeft throws StateError', () {
      final either = Either<String, int>.right(42);
      expect(() => either.getLeft(), throwsStateError);
    });

    test('getOrElse returns the value, ignoring default', () {
      final either = Either<String, int>.right(42);
      expect(either.getOrElse(0), 42);
    });

    test('getOrElseCompute returns the value, ignoring orElse', () {
      final either = Either<String, int>.right(42);
      expect(either.getOrElseCompute((_) => 0), 42);
    });

    test('fold calls onRight', () {
      final either = Either<String, int>.right(42);
      final result = either.fold(
        (l) => 'left: $l',
        (r) => 'right: $r',
      );
      expect(result, 'right: 42');
    });

    test('map transforms the value', () {
      final either = Either<String, int>.right(42);
      final result = either.map((r) => r * 2);
      expect(result.getOrElse(0), 84);
    });

    test('flatMap chains transformations', () {
      final either = Either<String, int>.right(42);
      final result = either.flatMap((r) => Either<String, double>.right(r / 2.0));
      expect(result.getOrElse(0.0), 21.0);
    });

    test('flatMap can switch to Left', () {
      final either = Either<String, int>.right(42);
      final result = either.flatMap((_) => Either<String, double>.left('error'));
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'error');
    });

    test('mapLeft preserves Right', () {
      final either = Either<String, int>.right(42);
      final result = either.mapLeft((l) => l.toUpperCase());
      expect(result.isRight, isTrue);
      expect(result.getRight(), 42);
    });

    test('swap converts Right to Left', () {
      final either = Either<String, int>.right(42);
      final swapped = either.swap();
      expect(swapped.isLeft, isTrue);
      expect(swapped.getLeft(), 42);
    });

    test('toNullable returns the value', () {
      final either = Either<String, int>.right(42);
      expect(either.toNullable(), 42);
    });

    test('tapRight executes action', () {
      var called = false;
      Either<String, int>.right(42).tapRight((int r) {
        called = true;
        expect(r, 42);
      });
      expect(called, isTrue);
    });

    test('tapLeft does not execute action', () {
      var called = false;
      Either<String, int>.right(42).tapLeft((String _) {
        called = true;
      });
      expect(called, isFalse);
    });

    test('toString returns Right(value)', () {
      final either = Either<String, int>.right(42);
      expect(either.toString(), 'Right(42)');
    });
  });

  group('Either.left', () {
    test('isRight returns false', () {
      final either = Either<String, int>.left('error');
      expect(either.isRight, isFalse);
    });

    test('isLeft returns true', () {
      final either = Either<String, int>.left('error');
      expect(either.isLeft, isTrue);
    });

    test('getLeft returns the value', () {
      final either = Either<String, int>.left('error');
      expect(either.getLeft(), 'error');
    });

    test('getRight throws StateError', () {
      final either = Either<String, int>.left('error');
      expect(() => either.getRight(), throwsStateError);
    });

    test('getOrElse returns the default', () {
      final either = Either<String, int>.left('error');
      expect(either.getOrElse(99), 99);
    });

    test('getOrElseCompute calls orElse with left value', () {
      final either = Either<String, int>.left('error');
      final result = either.getOrElseCompute((l) => l.length);
      expect(result, 5);
    });

    test('fold calls onLeft', () {
      final either = Either<String, int>.left('error');
      final result = either.fold(
        (l) => 'left: $l',
        (r) => 'right: $r',
      );
      expect(result, 'left: error');
    });

    test('map preserves Left', () {
      final either = Either<String, int>.left('error');
      final result = either.map((r) => r * 2);
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'error');
    });

    test('flatMap preserves Left', () {
      final either = Either<String, int>.left('error');
      final result = either.flatMap((r) => Either<String, double>.right(r / 2.0));
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'error');
    });

    test('mapLeft transforms the Left value', () {
      final either = Either<String, int>.left('error');
      final result = either.mapLeft((l) => l.toUpperCase());
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'ERROR');
    });

    test('swap converts Left to Right', () {
      final either = Either<String, int>.left('error');
      final swapped = either.swap();
      expect(swapped.isRight, isTrue);
      expect(swapped.getRight(), 'error');
    });

    test('toNullable returns null', () {
      final either = Either<String, int>.left('error');
      expect(either.toNullable(), isNull);
    });

    test('tapLeft executes action', () {
      var called = false;
      Either<String, int>.left('error').tapLeft((String l) {
        called = true;
        expect(l, 'error');
      });
      expect(called, isTrue);
    });

    test('tapRight does not execute action', () {
      var called = false;
      Either<String, int>.left('error').tapRight((int _) {
        called = true;
      });
      expect(called, isFalse);
    });

    test('toString returns Left(value)', () {
      final either = Either<String, int>.left('error');
      expect(either.toString(), 'Left(error)');
    });
  });

  group('Either.tryCatch', () {
    test('returns Right on success', () {
      final result = Either.tryCatch<int, String>(
        () => 'success',
        (error, stackTrace) => -1,
      );
      expect(result.isRight, isTrue);
      expect(result.getRight(), 'success');
    });

    test('returns Left on exception', () {
      final result = Either.tryCatch<String, int>(
        () => throw FormatException('bad format'),
        (error, stackTrace) => error.toString(),
      );
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), contains('FormatException'));
    });

    test('passes error and stackTrace to onError', () {
      Object? capturedError;
      StackTrace? capturedStack;
      Either.tryCatch<String, int>(
        () => throw ArgumentError('test'),
        (error, stackTrace) {
          capturedError = error;
          capturedStack = stackTrace;
          return 'caught';
        },
      );
      expect(capturedError, isA<ArgumentError>());
      expect(capturedStack, isNotNull);
    });

    test('handles string errors', () {
      final result = Either.tryCatch<String, void>(
        () => throw 'raw string',
        (error, stackTrace) => 'caught: $error',
      );
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), contains('raw string'));
    });
  });

  group('Either.tryCatchAsync', () {
    test('returns Right on async success', () async {
      final result = await Either.tryCatchAsync<String, int>(
        () async => 42,
        (error, stackTrace) => error.toString(),
      );
      expect(result.isRight, isTrue);
      expect(result.getRight(), 42);
    });

    test('returns Left on async exception', () async {
      final result = await Either.tryCatchAsync<String, int>(
        () async => throw Exception('async failure'),
        (error, stackTrace) => error.toString(),
      );
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), contains('async failure'));
    });

    test('catches exceptions thrown synchronously in run', () async {
      final result = await Either.tryCatchAsync<String, int>(
        () => throw StateError('sync throw'),
        (error, stackTrace) => error.toString(),
      );
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), contains('sync throw'));
    });

    test('passes error and stackTrace in async context', () async {
      Object? capturedError;
      await Either.tryCatchAsync<String, void>(
        () async => throw RangeError('bad range'),
        (error, stackTrace) {
          capturedError = error;
          return 'caught';
        },
      );
      expect(capturedError, isA<RangeError>());
    });
  });

  group('Either.fromNullable', () {
    test('returns Right for non-null value', () {
      final result = Either.fromNullable<String, int>(
        42,
        () => 'was null',
      );
      expect(result.isRight, isTrue);
      expect(result.getRight(), 42);
    });

    test('returns Left for null value', () {
      final result = Either.fromNullable<String, int>(
        null,
        () => 'was null',
      );
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'was null');
    });
  });

  group('Either.map2', () {
    test('combines two Rights', () {
      final a = Either<String, int>.right(2);
      final b = Either<String, int>.right(3);
      final result = Either.map2<String, int, int, int>(a, b, (x, y) => x + y);
      expect(result.isRight, isTrue);
      expect(result.getRight(), 5);
    });

    test('returns Left if first is Left', () {
      final a = Either<String, int>.left('error');
      final b = Either<String, int>.right(3);
      final result = Either.map2<String, int, int, int>(a, b, (x, y) => x + y);
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'error');
    });

    test('returns Left if second is Left', () {
      final a = Either<String, int>.right(2);
      final b = Either<String, int>.left('error');
      final result = Either.map2<String, int, int, int>(a, b, (x, y) => x + y);
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'error');
    });
  });

  group('equality and hashCode', () {
    test('two Rights with same value are equal', () {
      final a = Either<String, int>.right(42);
      final b = Either<String, int>.right(42);
      expect(a, equals(b));
    });

    test('two Rights with different values are not equal', () {
      final a = Either<String, int>.right(42);
      final b = Either<String, int>.right(99);
      expect(a, isNot(equals(b)));
    });

    test('two Lefts with same value are equal', () {
      final a = Either<String, int>.left('error');
      final b = Either<String, int>.left('error');
      expect(a, equals(b));
    });

    test('two Lefts with different values are not equal', () {
      final a = Either<String, int>.left('error');
      final b = Either<String, int>.left('different');
      expect(a, isNot(equals(b)));
    });

    test('Right and Left with same value type are not equal', () {
      final a = Either<String, int>.right(42);
      final b = Either<String, int>.left('42');
      expect(a, isNot(equals(b)));
    });

    test('hashCode matches for equal Rights', () {
      final a = Either<String, int>.right(42);
      final b = Either<String, int>.right(42);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode matches for equal Lefts', () {
      final a = Either<String, int>.left('error');
      final b = Either<String, int>.left('error');
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('edge cases', () {
    test('Right with null value', () {
      final either = Either<String, int?>.right(null);
      expect(either.isRight, isTrue);
      expect(either.getRight(), isNull);
      expect(either.toString(), 'Right(null)');
    });

    test('Left with null value', () {
      final either = Either<String?, int>.left(null);
      expect(either.isLeft, isTrue);
      expect(either.getLeft(), isNull);
      expect(either.toString(), 'Left(null)');
    });

    test('nested Either — Right containing Right', () {
      final inner = Either<String, int>.right(42);
      final outer = Either<String, Either<String, int>>.right(inner);
      final unrolled = outer.flatMap((e) => e);
      expect(unrolled.getOrElse(0), 42);
    });

    test('nested Either — Right containing Left', () {
      final inner = Either<String, int>.left('inner error');
      final outer = Either<String, Either<String, int>>.right(inner);
      final unrolled = outer.flatMap((e) => e);
      expect(unrolled.isLeft, isTrue);
      expect(unrolled.getLeft(), 'inner error');
    });

    test('multiple maps compose correctly', () {
      final result = Either<String, int>
          .right(5)
          .map((r) => r * 3)
          .map((r) => r.toString())
          .map((r) => '$r!');
      expect(result.getOrElse(''), '15!');
    });

    test('chained flatMap and map', () {
      final result = Either<String, int>
          .right(10)
          .flatMap((r) => Either<String, int>.right(r + 5))
          .map((r) => r * 2);
      expect(result.getOrElse(0), 30);
    });
  });

  group('FutureEitherExtensions', () {
    test('mapAsync transforms Right in Future', () async {
      final future = Future.value(Either<String, int>.right(42));
      final result = await future.mapAsync((int r) => r * 2);
      expect(result.isRight, isTrue);
      expect(result.getRight(), 84);
    });

    test('mapAsync preserves Left in Future', () async {
      final future = Future.value(Either<String, int>.left('error'));
      final result = await future.mapAsync((int r) => r * 2);
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'error');
    });

    test('flatMapAsync chains Right in Future', () async {
      final future = Future.value(Either<String, int>.right(42));
      final result = await future.flatMapAsync(
        (int r) => Future.value(Either<String, double>.right(r / 2.0)),
      );
      expect(result.isRight, isTrue);
      expect(result.getRight(), 21.0);
    });

    test('flatMapAsync preserves Left in Future', () async {
      final future = Future.value(Either<String, int>.left('error'));
      final result = await future.flatMapAsync(
        (int r) => Future.value(Either<String, double>.right(r / 2.0)),
      );
      expect(result.isLeft, isTrue);
      expect(result.getLeft(), 'error');
    });
  });
}
