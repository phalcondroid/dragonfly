import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.required', () {
    final validate = Validators.required<String>();

    test('returns error for null', () {
      expect(validate(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(validate(''), isNotNull);
    });

    test('returns error for empty list', () {
      final listValidator = Validators.required<List<int>>();
      expect(listValidator([]), isNotNull);
    });

    test('returns error for empty map', () {
      final mapValidator = Validators.required<Map<String, dynamic>>();
      expect(mapValidator({}), isNotNull);
    });

    test('returns null for non-empty string', () {
      expect(validate('hello'), isNull);
    });

    test('returns null for non-empty list', () {
      final listValidator = Validators.required<List<int>>();
      expect(listValidator([1]), isNull);
    });

    test('returns null for non-empty map', () {
      final mapValidator = Validators.required<Map<String, dynamic>>();
      expect(mapValidator({'key': 'value'}), isNull);
    });

    test('returns default error message', () {
      expect(validate(null), contains('required'));
    });

    test('returns custom message when provided', () {
      final custom = Validators.required<String>('Please fill in');
      expect(custom(''), 'Please fill in');
    });
  });

  group('Validators.email', () {
    final validate = Validators.email();

    test('returns null for valid email', () {
      expect(validate('test@example.com'), isNull);
      expect(validate('user.name+tag@domain.co.uk'), isNull);
    });

    test('returns error for invalid email', () {
      expect(validate('not-an-email'), isNotNull);
      expect(validate('missing@domain'), isNotNull);
      expect(validate('@nodomain.'), isNotNull);
    });

    test('returns null for empty string (not required)', () {
      expect(validate(''), isNull);
    });

    test('returns null for null (not required)', () {
      expect(validate(null), isNull);
    });

    test('returns custom message when provided', () {
      final custom = Validators.email('Bad email');
      expect(custom('invalid'), 'Bad email');
    });
  });

  group('Validators.minLength', () {
    final validate = Validators.minLength(3);

    test('returns error for string shorter than minimum', () {
      expect(validate('ab'), isNotNull);
    });

    test('returns null for string meeting minimum', () {
      expect(validate('abc'), isNull);
    });

    test('returns null for string exceeding minimum', () {
      expect(validate('abcdef'), isNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.maxLength', () {
    final validate = Validators.maxLength(5);

    test('returns error for string longer than maximum', () {
      expect(validate('abcdef'), isNotNull);
    });

    test('returns null for string at maximum', () {
      expect(validate('abcde'), isNull);
    });

    test('returns null for string within limit', () {
      expect(validate('ab'), isNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.pattern', () {
    final validate = Validators.pattern(r'^\d+$');

    test('returns null for matching pattern', () {
      expect(validate('12345'), isNull);
    });

    test('returns error for non-matching pattern', () {
      expect(validate('abc'), isNotNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.url', () {
    final validate = Validators.url();

    test('returns null for valid URL', () {
      expect(validate('https://example.com'), isNull);
      expect(validate('http://sub.domain.co/path?q=1'), isNull);
    });

    test('returns error for invalid URL', () {
      expect(validate('not-a-url'), isNotNull);
      expect(validate('example.com'), isNotNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.phone', () {
    final validate = Validators.phone();

    test('returns null for valid phone', () {
      expect(validate('+15551234567'), isNull);
      expect(validate('1234567890'), isNull);
      expect(validate('(555) 123-4567'), isNull);
    });

    test('returns error for invalid phone', () {
      expect(validate('12345'), isNotNull);
      expect(validate('abcdefghij'), isNotNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.alphanumeric', () {
    final validate = Validators.alphanumeric();

    test('returns null for alphanumeric string', () {
      expect(validate('abc123'), isNull);
      expect(validate('ABCxyz'), isNull);
    });

    test('returns error for string with special characters', () {
      expect(validate('abc@123'), isNotNull);
      expect(validate('hello world'), isNotNull);
      expect(validate('abc-def'), isNotNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.alpha', () {
    final validate = Validators.alpha();

    test('returns null for alphabetic string', () {
      expect(validate('abcXYZ'), isNull);
    });

    test('returns error for string with numbers', () {
      expect(validate('abc123'), isNotNull);
    });

    test('returns error for string with special characters', () {
      expect(validate('abc!'), isNotNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.numeric', () {
    final validate = Validators.numeric();

    test('returns null for numeric string', () {
      expect(validate('12345'), isNull);
    });

    test('returns error for string with letters', () {
      expect(validate('abc123'), isNotNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.min', () {
    final validate = Validators.min(5);

    test('returns error for value below min', () {
      expect(validate(3), isNotNull);
    });

    test('returns null for value at min', () {
      expect(validate(5), isNull);
    });

    test('returns null for value above min', () {
      expect(validate(10), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.max', () {
    final validate = Validators.max(10);

    test('returns error for value above max', () {
      expect(validate(15), isNotNull);
    });

    test('returns null for value at max', () {
      expect(validate(10), isNull);
    });

    test('returns null for value below max', () {
      expect(validate(3), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.range', () {
    final validate = Validators.range(5, 10);

    test('returns error for value below range', () {
      expect(validate(3), isNotNull);
    });

    test('returns error for value above range', () {
      expect(validate(15), isNotNull);
    });

    test('returns null for value at lower bound', () {
      expect(validate(5), isNull);
    });

    test('returns null for value at upper bound', () {
      expect(validate(10), isNull);
    });

    test('returns null for value within range', () {
      expect(validate(7), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.positive', () {
    final validate = Validators.positive();

    test('returns null for positive number', () {
      expect(validate(1), isNull);
      expect(validate(0.5), isNull);
    });

    test('returns error for zero', () {
      expect(validate(0), isNotNull);
    });

    test('returns error for negative number', () {
      expect(validate(-5), isNotNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.negative', () {
    final validate = Validators.negative();

    test('returns null for negative number', () {
      expect(validate(-1), isNull);
      expect(validate(-0.5), isNull);
    });

    test('returns error for zero', () {
      expect(validate(0), isNotNull);
    });

    test('returns error for positive number', () {
      expect(validate(5), isNotNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.mustBeTrue', () {
    final validate = Validators.mustBeTrue();

    test('returns null for true', () {
      expect(validate(true), isNull);
    });

    test('returns error for false', () {
      expect(validate(false), isNotNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.mustBeFalse', () {
    final validate = Validators.mustBeFalse();

    test('returns null for false', () {
      expect(validate(false), isNull);
    });

    test('returns error for true', () {
      expect(validate(true), isNotNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.pastDate', () {
    final validate = Validators.pastDate();

    test('returns null for past date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(validate(yesterday), isNull);
    });

    test('returns error for future date', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(validate(tomorrow), isNotNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.futureDate', () {
    final validate = Validators.futureDate();

    test('returns null for future date', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(validate(tomorrow), isNull);
    });

    test('returns error for past date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(validate(yesterday), isNotNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.minAge', () {
    final validate = Validators.minAge(18);

    test('returns error for too young', () {
      final tenYearsAgo = DateTime.now().subtract(const Duration(days: 10 * 365));
      expect(validate(tenYearsAgo), isNotNull);
    });

    test('returns null for old enough', () {
      final twentyYearsAgo =
          DateTime.now().subtract(const Duration(days: 20 * 365));
      expect(validate(twentyYearsAgo), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.minItems', () {
    final validate = Validators.minItems<int>(2);

    test('returns error for too few items', () {
      expect(validate([1]), isNotNull);
    });

    test('returns null for enough items', () {
      expect(validate([1, 2]), isNull);
      expect(validate([1, 2, 3]), isNull);
    });

    test('returns error for empty list', () {
      expect(validate([]), isNotNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.maxItems', () {
    final validate = Validators.maxItems<int>(3);

    test('returns error for too many items', () {
      expect(validate([1, 2, 3, 4]), isNotNull);
    });

    test('returns null for within limit', () {
      expect(validate([1, 2, 3]), isNull);
      expect(validate([1]), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.equalTo', () {
    final validate = Validators.equalTo<String>('other');

    test('returns null when values match', () {
      final result = validate('hello', {'other': 'hello'});
      expect(result, isNull);
    });

    test('returns error when values differ', () {
      final result = validate('hello', {'other': 'world'});
      expect(result, isNotNull);
    });

    test('returns null for null value', () {
      final result = validate(null, {'other': 'hello'});
      expect(result, isNull);
    });
  });

  group('Validators.notEqualTo', () {
    final validate = Validators.notEqualTo<String>('other');

    test('returns null when values differ', () {
      final result = validate('hello', {'other': 'world'});
      expect(result, isNull);
    });

    test('returns error when values match', () {
      final result = validate('hello', {'other': 'hello'});
      expect(result, isNotNull);
    });

    test('returns null for null value', () {
      final result = validate(null, {'other': 'hello'});
      expect(result, isNull);
    });
  });

  group('Validators.requiredIf', () {
    final validate = Validators.requiredIf<String>('country', 'US');

    test('returns error when condition met and value is null', () {
      final result = validate(null, {'country': 'US'});
      expect(result, isNotNull);
    });

    test('returns error when condition met and value is empty', () {
      final result = validate('', {'country': 'US'});
      expect(result, isNotNull);
    });

    test('returns null when condition met and value is provided', () {
      final result = validate('New York', {'country': 'US'});
      expect(result, isNull);
    });

    test('returns null when condition not met', () {
      final result = validate(null, {'country': 'CA'});
      expect(result, isNull);
    });
  });

  group('Validators.requiredUnless', () {
    final validate = Validators.requiredUnless<String>('country', 'US');

    test('returns error when condition not met and value is null', () {
      final result = validate(null, {'country': 'CA'});
      expect(result, isNotNull);
    });

    test('returns error when condition not met and value is empty', () {
      final result = validate('', {'country': 'CA'});
      expect(result, isNotNull);
    });

    test('returns null when condition not met but value is provided', () {
      final result = validate('Toronto', {'country': 'CA'});
      expect(result, isNull);
    });

    test('returns null when condition is met', () {
      final result = validate(null, {'country': 'US'});
      expect(result, isNull);
    });
  });

  group('Validators.creditCard', () {
    final validate = Validators.creditCard();

    test('returns null for valid credit card', () {
      expect(validate('4532015112830366'), isNull);
    });

    test('returns error for invalid credit card', () {
      expect(validate('1234567890123456'), isNotNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });

    test('handles credit card with spaces and dashes', () {
      expect(validate('4532 0151 1283 0366'), isNull);
      expect(validate('4532-0151-1283-0366'), isNull);
    });
  });

  group('Validators.cvv', () {
    final validate = Validators.cvv();

    test('returns null for valid CVV (3 digits)', () {
      expect(validate('123'), isNull);
    });

    test('returns null for valid CVV (4 digits)', () {
      expect(validate('1234'), isNull);
    });

    test('returns error for invalid CVV', () {
      expect(validate('12'), isNotNull);
      expect(validate('abc'), isNotNull);
      expect(validate('12345'), isNotNull);
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.expiryDate', () {
    final validate = Validators.expiryDate();

    test('returns null for valid future expiry (MM/YY)', () {
      final future = DateTime.now().add(const Duration(days: 365));
      final month = future.month.toString().padLeft(2, '0');
      final year = (future.year % 100).toString().padLeft(2, '0');
      expect(validate('$month/$year'), isNull);
    });

    test('returns error for past expiry date', () {
      expect(validate('01/20'), isNotNull);
    });

    test('returns error for invalid format with custom message', () {
      final custom = Validators.expiryDate('Custom expiry error');
      expect(custom('13/99'), 'Custom expiry error');
      expect(custom('not-a-date'), 'Custom expiry error');
    });

    test('returns null for empty string', () {
      expect(validate(''), isNull);
    });

    test('returns null for null', () {
      expect(validate(null), isNull);
    });
  });

  group('Validators.strongPassword', () {
    test('returns null for strong password', () {
      final validate = Validators.strongPassword();
      expect(validate('Strong1Password'), isNull);
    });

    test('returns error for too short password', () {
      final validate = Validators.strongPassword(minLength: 8);
      expect(validate('Ab1'), isNotNull);
    });

    test('returns error for missing uppercase', () {
      final validate = Validators.strongPassword();
      expect(validate('alllowercase1'), isNotNull);
    });

    test('returns error for missing lowercase', () {
      final validate = Validators.strongPassword();
      expect(validate('ALLUPPERCASE1'), isNotNull);
    });

    test('returns error for missing digit', () {
      final validate = Validators.strongPassword();
      expect(validate('NoDigitsHere'), isNotNull);
    });

    test('returns error for missing special character when required', () {
      final validate = Validators.strongPassword(requireSpecial: true);
      expect(validate('NoSpecial1'), isNotNull);
    });

    test('returns null for null', () {
      final validate = Validators.strongPassword();
      expect(validate(null), isNull);
    });

    test('returns null for empty string', () {
      final validate = Validators.strongPassword();
      expect(validate(''), isNull);
    });
  });

  group('Validators.compose', () {
    test('returns null when all validators pass', () {
      final composed = Validators.compose<String>([
        Validators.minLength(3),
        Validators.maxLength(10),
      ]);
      expect(composed('hello'), isNull);
    });

    test('returns first error when validation fails', () {
      final composed = Validators.compose<String>([
        Validators.minLength(3),
        Validators.maxLength(5),
      ]);
      expect(composed('ab'), isNotNull);
    });

    test('returns error from second validator when first passes', () {
      final composed = Validators.compose<String>([
        Validators.minLength(3),
        Validators.maxLength(5),
      ]);
      expect(composed('abcdef'), isNotNull);
    });
  });

  group('custom message parameter', () {
    test('required uses custom message', () {
      final v = Validators.required<String>('Custom required');
      expect(v(null), 'Custom required');
    });

    test('email uses custom message', () {
      final v = Validators.email('Custom email');
      expect(v('bad'), 'Custom email');
    });

    test('min uses custom message', () {
      final v = Validators.min(10, 'Custom min');
      expect(v(5), 'Custom min');
    });

    test('max uses custom message', () {
      final v = Validators.max(10, 'Custom max');
      expect(v(15), 'Custom max');
    });

    test('range uses custom message', () {
      final v = Validators.range(1, 10, 'Custom range');
      expect(v(20), 'Custom range');
    });
  });

  group('Validators.setMessages', () {
    test('changes global default messages', () {
      final customMessages = _SpanishValidationMessages();
      Validators.setMessages(customMessages);

      final validate = Validators.required<String>();
      expect(validate(null), 'Este campo es obligatorio');

      final emailValidator = Validators.email();
      expect(emailValidator('bad'), 'Formato de email inválido');

      Validators.setMessages(const DragonflyValidationMessages());
    });
  });
}

class _SpanishValidationMessages extends DragonflyValidationMessages {
  const _SpanishValidationMessages();

  @override
  String get required => 'Este campo es obligatorio';

  @override
  String get invalidEmail => 'Formato de email inválido';
}
