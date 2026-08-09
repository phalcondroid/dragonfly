import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflyFormFieldState', () {
    group('constructor', () {
      test('stores value, error, touched', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'Required',
          touched: true,
        );

        expect(state.value, 'hello');
        expect(state.initialValue, '');
        expect(state.error, 'Required');
        expect(state.touched, true);
      });

      test('defaults touched to false', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
        );

        expect(state.touched, false);
      });

      test('defaults error to null', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
        );

        expect(state.error, isNull);
      });
    });

    group('dirty', () {
      test('returns false when value equals initialValue', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: 'hello',
        );
        expect(state.dirty, false);
      });

      test('returns true when value differs from initialValue', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
        );
        expect(state.dirty, true);
      });
    });

    group('isValid', () {
      test('returns true when error is null', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
        );
        expect(state.isValid, true);
      });

      test('returns false when error is not null', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'Invalid',
        );
        expect(state.isValid, false);
      });
    });

    group('isInvalid', () {
      test('returns false when error is null', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
        );
        expect(state.isInvalid, false);
      });

      test('returns true when error is not null', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'Invalid',
        );
        expect(state.isInvalid, true);
      });
    });

    group('showError', () {
      test('returns false when not touched', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'Invalid',
          touched: false,
        );
        expect(state.showError, false);
      });

      test('returns false when touched but no error', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          touched: true,
        );
        expect(state.showError, false);
      });

      test('returns true when touched and has error', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'Invalid',
          touched: true,
        );
        expect(state.showError, true);
      });
    });

    group('copyWith', () {
      final original = DragonflyFormFieldState<String>(
        value: 'hello',
        initialValue: '',
        error: 'Error',
        touched: true,
      );

      test('updates value, preserves other fields', () {
        final updated = original.copyWith(value: 'world');
        expect(updated.value, 'world');
        expect(updated.initialValue, '');
        expect(updated.error, 'Error');
        expect(updated.touched, true);
      });

      test('updates error, preserves other fields', () {
        final updated = original.copyWith(error: 'New error');
        expect(updated.value, 'hello');
        expect(updated.initialValue, '');
        expect(updated.error, 'New error');
        expect(updated.touched, true);
      });

      test('clearError sets error to null', () {
        final updated = original.copyWith(clearError: true);
        expect(updated.error, isNull);
        expect(updated.value, 'hello');
        expect(updated.touched, true);
      });

      test('clearError takes precedence over explicit error', () {
        final updated = original.copyWith(error: 'New', clearError: true);
        expect(updated.error, isNull);
      });

      test('marks touched', () {
        final untouched = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
        );
        final updated = untouched.copyWith(touched: true);
        expect(updated.touched, true);
      });

      test('updates multiple fields', () {
        final updated = original.copyWith(value: 'world', touched: false);
        expect(updated.value, 'world');
        expect(updated.touched, false);
        expect(updated.error, 'Error');
        expect(updated.initialValue, '');
      });

      test('returns original instance when no changes', () {
        final updated = original.copyWith();
        expect(updated.value, original.value);
        expect(updated.error, original.error);
        expect(updated.touched, original.touched);
        expect(updated.initialValue, original.initialValue);
      });
    });

    group('reset', () {
      test('resets to initial value and clears error and touched', () {
        final state = DragonflyFormFieldState<String>(
          value: 'changed',
          initialValue: 'original',
          error: 'Error',
          touched: true,
        );

        final reset = state.reset();
        expect(reset.value, 'original');
        expect(reset.initialValue, 'original');
        expect(reset.error, isNull);
        expect(reset.touched, false);
      });
    });

    group('equality', () {
      test('equal states with same values', () {
        final a = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'Error',
          touched: true,
        );
        final b = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'Error',
          touched: true,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when value differs', () {
        final a = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
        );
        final b = DragonflyFormFieldState<String>(
          value: 'world',
          initialValue: '',
        );
        expect(a, isNot(equals(b)));
      });

      test('not equal when error differs', () {
        final a = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'A',
        );
        final b = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'B',
        );
        expect(a, isNot(equals(b)));
      });

      test('not equal when touched differs', () {
        final a = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          touched: true,
        );
        final b = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          touched: false,
        );
        expect(a, isNot(equals(b)));
      });

      test('identical instance is equal', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
        );
        expect(state, equals(state));
      });
    });

    group('toString', () {
      test('contains all fields', () {
        final state = DragonflyFormFieldState<String>(
          value: 'hello',
          initialValue: '',
          error: 'Invalid',
          touched: true,
        );
        final str = state.toString();
        expect(str, contains('hello'));
        expect(str, contains('Invalid'));
        expect(str, contains('touched'));
        expect(str, contains('dirty'));
      });
    });
  });

  group('DragonflyValidationMessages', () {
    test('default English messages are correct', () {
      const messages = DragonflyValidationMessages();

      expect(messages.required, 'This field is required');
      expect(messages.invalidEmail, 'Invalid email format');
      expect(messages.invalidUrl, 'Invalid URL format');
      expect(messages.invalidPhone, 'Invalid phone number');
      expect(messages.notAlphanumeric, 'Must contain only letters and numbers');
      expect(messages.invalidCreditCard, 'Invalid credit card number');
    });

    test('subclass can override individual messages', () {
      final messages = _TestMessages();

      expect(messages.required, 'REQUIRED');
      expect(messages.invalidEmail, 'Invalid email format');
    });

    test('minLength accepts length parameter', () {
      const messages = DragonflyValidationMessages();
      final result = messages.minLength(5);
      expect(result, contains('5'));
    });

    test('tooYoung accepts years parameter', () {
      const messages = DragonflyValidationMessages();
      final result = messages.tooYoung(18);
      expect(result, contains('18'));
    });

    test('tooFewItems accepts count parameter', () {
      const messages = DragonflyValidationMessages();
      final result = messages.tooFewItems(3);
      expect(result, contains('3'));
    });

    test('tooManyItems accepts count parameter', () {
      const messages = DragonflyValidationMessages();
      final result = messages.tooManyItems(10);
      expect(result, contains('10'));
    });

    test('passwordChars accepts minLength parameter', () {
      const messages = DragonflyValidationMessages();
      final result = messages.passwordChars(8);
      expect(result, contains('8'));
    });

    test('requiredRoles accepts roles list', () {
      const messages = DragonflyValidationMessages();
      final result = messages.requiredRoles(['admin', 'user']);
      expect(result, contains('admin'));
      expect(result, contains('user'));
    });

    test('requiredPermissions accepts permissions list', () {
      const messages = DragonflyValidationMessages();
      final result = messages.requiredPermissions(['read', 'write']);
      expect(result, contains('read'));
      expect(result, contains('write'));
    });

    test('passwordRequirements joins errors', () {
      const messages = DragonflyValidationMessages();
      final result = messages.passwordRequirements(['a', 'b', 'c']);
      expect(result, contains('a, b, c'));
    });

    test('maxLength accepts length parameter', () {
      const messages = DragonflyValidationMessages();
      final result = messages.maxLength(10);
      expect(result, contains('10'));
    });

    test('tooLow accepts min parameter', () {
      const messages = DragonflyValidationMessages();
      final result = messages.tooLow(5);
      expect(result, contains('5'));
    });

    test('tooHigh accepts max parameter', () {
      const messages = DragonflyValidationMessages();
      final result = messages.tooHigh(100);
      expect(result, contains('100'));
    });

    test('outOfRange accepts min and max parameters', () {
      const messages = DragonflyValidationMessages();
      final result = messages.outOfRange(1, 100);
      expect(result, contains('1'));
      expect(result, contains('100'));
    });

    test('submitButtonLabel has default', () {
      const messages = DragonflyValidationMessages();
      expect(messages.submitButtonLabel, 'Submit');
    });

    test('authenticationRequired has default', () {
      const messages = DragonflyValidationMessages();
      expect(messages.authenticationRequired, 'Authentication required');
    });
  });
}

class _TestMessages extends DragonflyValidationMessages {
  const _TestMessages();

  @override
  String get required => 'REQUIRED';
}
