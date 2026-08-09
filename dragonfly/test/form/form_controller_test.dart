import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

Validator<dynamic> _vd(Validator<String> v) => (value) => v(value as String?);

class _TestFormController extends FormController<dynamic> {
  _TestFormController({
    required Map<String, DragonflyFormFieldState<dynamic>> fields,
    required Map<String, List<Validator<dynamic>>> validators,
  })  : _fields = Map.from(fields),
        _validators = validators;

  _TestFormController.withDefaults()
      : _fields = {
          'name': const DragonflyFormFieldState<String>(
              value: '', initialValue: '', error: 'Required'),
          'email': const DragonflyFormFieldState<String>(
              value: 'test@test.com',
              initialValue: 'test@test.com',
              error: null),
        },
        _validators = {
          'name': [Validators.required<dynamic>()],
          'email': [_vd(Validators.email())],
        };

  final Map<String, DragonflyFormFieldState<dynamic>> _fields;
  final Map<String, List<Validator<dynamic>>> _validators;

  @override
  Map<String, DragonflyFormFieldState<dynamic>> get fields =>
      Map.unmodifiable(_fields);

  @override
  Map<String, List<Validator<dynamic>>> get validators => _validators;

  @override
  Map<String, List<CrossFieldValidator<dynamic>>> get crossFieldValidators =>
      {};

  @override
  bool get validateOnChange => false;

  @override
  bool get validateOnBlur => false;

  void updateField(String name, dynamic value) {
    final existing = _fields[name];
    if (existing == null) return;
    _fields[name] = existing.copyWith(value: value);
  }

  void touchField(String name) {
    final existing = _fields[name];
    if (existing == null) return;
    _fields[name] = existing.copyWith(touched: true);
  }

  FormController<dynamic> validate() {
    for (final name in _fields.keys) {
      final error = super.validateField(name);
      final existing = _fields[name]!;
      _fields[name] =
          existing.copyWith(error: error, clearError: error == null);
    }
    return this;
  }

  FormController<dynamic> validateFieldState(String name) {
    final error = super.validateField(name);
    final existing = _fields[name];
    if (existing != null) {
      _fields[name] =
          existing.copyWith(error: error, clearError: error == null);
    }
    return this;
  }

  FormController<dynamic> updateFieldValue(String name, dynamic value) {
    updateField(name, value);
    return this;
  }
}

void main() {
  group('FormController', () {
    late _TestFormController controller;

    setUp(() {
      controller = _TestFormController.withDefaults();
    });

    test('fields accessor returns the map', () {
      final fields = controller.fields;
      expect(fields, hasLength(2));
      expect(fields.containsKey('name'), isTrue);
      expect(fields.containsKey('email'), isTrue);
    });

    test('isValid returns false when any field has error', () {
      expect(controller.isValid, isFalse);
    });

    test('isValid returns true when all fields have null errors', () {
      controller = _TestFormController(
        fields: {
          'name': const DragonflyFormFieldState<String>(
              value: 'John', initialValue: 'John', error: null),
          'email': const DragonflyFormFieldState<String>(
              value: 'test@test.com',
              initialValue: 'test@test.com',
              error: null),
        },
        validators: {
          'name': [Validators.required<dynamic>()],
          'email': [_vd(Validators.email())],
        },
      );
      expect(controller.isValid, isTrue);
    });

    test('updateField updates the field value', () {
      controller.updateField('name', 'Alice');
      expect(controller.fields['name']!.value, 'Alice');
    });

    test('touchField marks field as touched', () {
      controller.touchField('name');
      expect(controller.fields['name']!.touched, isTrue);
    });

    test('validate runs all validators and returns a FormController', () {
      final result = controller.validate();
      expect(result, isA<FormController<dynamic>>());
      expect(result.isValid, isFalse);
    });

    test('validateField validates a single field state', () {
      final result = controller.validateFieldState('email');
      expect(result, isA<FormController<dynamic>>());
    });

    test(
        'updateFieldValue updates the field value and returns FormController',
        () {
      final result = controller.updateFieldValue('name', 'Bob');
      expect(result, isA<FormController<dynamic>>());
      expect(controller.fields['name']!.value, 'Bob');
    });

    test('validateAll returns false when fields have errors', () {
      final allValid = controller.validateAll();
      expect(allValid, isFalse);
    });

    test('validateAll returns true when all fields are valid', () {
      controller = _TestFormController(
        fields: {
          'name': const DragonflyFormFieldState<String>(
              value: 'John', initialValue: 'John', error: null),
          'email': const DragonflyFormFieldState<String>(
              value: 'test@test.com',
              initialValue: 'test@test.com',
              error: null),
        },
        validators: {
          'name': [Validators.required<dynamic>()],
          'email': [_vd(Validators.email())],
        },
      );
      final allValid = controller.validateAll();
      expect(allValid, isTrue);
    });

    test('after validate, fields with errors have error messages set', () {
      controller = _TestFormController(
        fields: {
          'name': const DragonflyFormFieldState<String>(
              value: '', initialValue: '', error: null),
          'email': const DragonflyFormFieldState<String>(
              value: 'test@test.com',
              initialValue: 'test@test.com',
              error: null),
        },
        validators: {
          'name': [Validators.required<dynamic>()],
          'email': [_vd(Validators.email())],
        },
      );
      controller.validate();
      expect(controller.fields['name']!.error, isNotNull);
      expect(controller.fields['email']!.error, isNull);
    });

    test('validateFieldState sets error on invalid field', () {
      controller = _TestFormController(
        fields: {
          'name': const DragonflyFormFieldState<String>(
              value: '', initialValue: '', error: null),
        },
        validators: {
          'name': [Validators.required<dynamic>()],
        },
      );
      controller.validateFieldState('name');
      expect(controller.fields['name']!.error, isNotNull);
    });

    test('isDirty returns true after field update', () {
      controller.updateField('name', 'New Name');
      expect(controller.isDirty, isTrue);
    });

    test('isTouched returns true after touching a field', () {
      controller.touchField('name');
      expect(controller.isTouched, isTrue);
    });

    test('values returns current field values', () {
      expect(controller.values, {'name': '', 'email': 'test@test.com'});
    });

    test('errors returns current field errors', () {
      expect(controller.errors['name'], 'Required');
      expect(controller.errors['email'], isNull);
    });

    test('getValue retrieves typed field value', () {
      expect(controller.getValue<String>('email'), 'test@test.com');
    });

    test('getError returns field error', () {
      expect(controller.getError('name'), 'Required');
      expect(controller.getError('email'), isNull);
    });

    test('isFieldValid returns false when field has error', () {
      expect(controller.isFieldValid('name'), isFalse);
      expect(controller.isFieldValid('email'), isTrue);
    });

    test('isFieldTouched returns false when field not touched', () {
      expect(controller.isFieldTouched('name'), isFalse);
    });

    test('isFieldDirty returns false when field not changed', () {
      expect(controller.isFieldDirty('name'), isFalse);
    });

    test('shouldShowError returns false when field not touched', () {
      expect(controller.shouldShowError('name'), isFalse);
    });

    test('shouldShowError returns true when field touched and has error', () {
      controller.touchField('name');
      expect(controller.shouldShowError('name'), isTrue);
    });
  });
}
