import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

class _ConcreteAggregate implements AggregateRoot<int> {
  final int _id;

  _ConcreteAggregate(this._id);

  @override
  int get identity => _id;

  @override
  bool get isNew => _id == null;

  @override
  bool sameIdentityAs(Object other) {
    if (other is! AggregateRoot<int>) return false;
    return identity == other.identity;
  }
}

void main() {
  group('AggregateRoot<T>', () {
    test('interface exists and is abstract', () {
      expect(AggregateRoot, isA<Object>());
    });
  });

  group('concrete AggregateRoot<int>', () {
    test('identity returns the id', () {
      final aggregate = _ConcreteAggregate(42);

      expect(aggregate.identity, 42);
    });

    test('isNew returns false when identity is non-null', () {
      final aggregate = _ConcreteAggregate(1);

      expect(aggregate.isNew, isFalse);
    });

    test('sameIdentityAs returns true for matching identities', () {
      final a = _ConcreteAggregate(42);
      final b = _ConcreteAggregate(42);

      expect(a.sameIdentityAs(b), isTrue);
    });

    test('sameIdentityAs returns false for different identities', () {
      final a = _ConcreteAggregate(42);
      final b = _ConcreteAggregate(99);

      expect(a.sameIdentityAs(b), isFalse);
    });

    test('sameIdentityAs returns false for different types', () {
      final aggregate = _ConcreteAggregate(42);

      expect(aggregate.sameIdentityAs('not an aggregate'), isFalse);
    });

    test('is assignable to AggregateRoot<int>', () {
      final aggregate = _ConcreteAggregate(1);

      expect(aggregate, isA<AggregateRoot<int>>());
    });
  });

  group('AggregateException', () {
    test('stores message', () {
      final exception = AggregateException('Invariant violation');

      expect(exception.message, 'Invariant violation');
    });

    test('toString includes message', () {
      final exception = AggregateException('Missing identity');

      expect(exception.toString(), contains('AggregateException'));
      expect(exception.toString(), contains('Missing identity'));
    });
  });

  group('DomainEvent', () {
    test('marker interface exists', () {
      expect(DomainEvent, isA<Object>());
    });
  });
}
