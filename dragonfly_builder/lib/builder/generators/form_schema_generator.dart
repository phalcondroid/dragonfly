import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for @FormSchema annotated classes.
///
/// This generator creates:
/// - A form state class with field states
/// - A form controller mixin for StateManager integration
/// - Field enum for type-safe field references
/// - Validation logic based on field annotations
class FormSchemaGenerator extends GeneratorForAnnotation<FormSchema> {
  final _formatter = DartFormatter();

  // Validator type checkers
  static final _requiredChecker = TypeChecker.fromRuntime(Required);
  static final _emailChecker = TypeChecker.fromRuntime(Email);
  static final _minLengthChecker = TypeChecker.fromRuntime(MinLength);
  static final _maxLengthChecker = TypeChecker.fromRuntime(MaxLength);
  static final _patternChecker = TypeChecker.fromRuntime(Pattern);
  static final _urlChecker = TypeChecker.fromRuntime(Url);
  static final _phoneChecker = TypeChecker.fromRuntime(Phone);
  static final _alphanumericChecker = TypeChecker.fromRuntime(Alphanumeric);
  static final _alphaChecker = TypeChecker.fromRuntime(Alpha);
  static final _numericChecker = TypeChecker.fromRuntime(Numeric);
  static final _minChecker = TypeChecker.fromRuntime(Min);
  static final _maxChecker = TypeChecker.fromRuntime(Max);
  static final _rangeChecker = TypeChecker.fromRuntime(Range);
  static final _positiveChecker = TypeChecker.fromRuntime(Positive);
  static final _negativeChecker = TypeChecker.fromRuntime(Negative);
  static final _equalToChecker = TypeChecker.fromRuntime(EqualTo);
  static final _notEqualToChecker = TypeChecker.fromRuntime(NotEqualTo);
  static final _pastDateChecker = TypeChecker.fromRuntime(PastDate);
  static final _futureDateChecker = TypeChecker.fromRuntime(FutureDate);
  static final _minAgeChecker = TypeChecker.fromRuntime(MinAge);
  static final _minItemsChecker = TypeChecker.fromRuntime(MinItems);
  static final _maxItemsChecker = TypeChecker.fromRuntime(MaxItems);
  static final _mustBeTrueChecker = TypeChecker.fromRuntime(MustBeTrue);
  static final _mustBeFalseChecker = TypeChecker.fromRuntime(MustBeFalse);
  // ignore: unused_field - Reserved for future custom validator support
  static final _customChecker = TypeChecker.fromRuntime(Custom);
  static final _requiredIfChecker = TypeChecker.fromRuntime(RequiredIf);
  static final _requiredUnlessChecker = TypeChecker.fromRuntime(RequiredUnless);
  static final _creditCardChecker = TypeChecker.fromRuntime(CreditCard);
  static final _cvvChecker = TypeChecker.fromRuntime(Cvv);
  static final _expiryDateChecker = TypeChecker.fromRuntime(ExpiryDate);
  static final _strongPasswordChecker = TypeChecker.fromRuntime(StrongPassword);
  static final _formFieldChecker = TypeChecker.fromRuntime(FormField);

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@FormSchema can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final generateCopyWith = annotation.read('copyWith').boolValue;
    final validateOnChange = annotation.read('validateOnChange').boolValue;
    final validateOnBlur = annotation.read('validateOnBlur').boolValue;
    final customStateName = annotation.peek('stateName')?.stringValue;

    // Collect fields with their validators
    final fields = _collectFields(element);

    if (fields.isEmpty) {
      return '// No fields found in $className';
    }

    final stateName = customStateName ?? '${className}FormState';
    final controllerName = '${className}FormController';
    final fieldEnumName = '${className}Field';

    try {
      final code = _generateCode(
        className: className,
        stateName: stateName,
        controllerName: controllerName,
        fieldEnumName: fieldEnumName,
        fields: fields,
        generateCopyWith: generateCopyWith,
        validateOnChange: validateOnChange,
        validateOnBlur: validateOnBlur,
      );

      return _formatter.format(code);
    } catch (e, stackTrace) {
      log.severe('FormSchemaGenerator error: $e\n$stackTrace');
      return '// Error generating form schema code: $e';
    }
  }

  List<_FieldInfo> _collectFields(ClassElement element) {
    final fields = <_FieldInfo>[];

    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic) continue;

      final validators = <_ValidatorInfo>[];
      final crossValidators = <_CrossValidatorInfo>[];

      // Collect validators from annotations
      _collectValidators(field, validators, crossValidators);

      // Get field metadata
      final metadata = _getFieldMetadata(field);

      fields.add(_FieldInfo(
        name: field.name,
        type: field.type.getDisplayString(withNullability: false),
        dartType: field.type,
        validators: validators,
        crossValidators: crossValidators,
        metadata: metadata,
        defaultValue: _getDefaultValue(field),
      ));
    }

    return fields;
  }

  void _collectValidators(
    FieldElement field,
    List<_ValidatorInfo> validators,
    List<_CrossValidatorInfo> crossValidators,
  ) {
    // Required
    if (_requiredChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_requiredChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'required',
        message: annotation.peek('message')?.stringValue ?? 'This field is required',
      ));
    }

    // Email
    if (_emailChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_emailChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'email',
        message: annotation.peek('message')?.stringValue ?? 'Invalid email format',
      ));
    }

    // MinLength
    if (_minLengthChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_minLengthChecker.firstAnnotationOfExact(field));
      final length = annotation.read('length').intValue;
      validators.add(_ValidatorInfo(
        'minLength',
        params: {'length': length},
        message: annotation.peek('message')?.stringValue,
      ));
    }

    // MaxLength
    if (_maxLengthChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_maxLengthChecker.firstAnnotationOfExact(field));
      final length = annotation.read('length').intValue;
      validators.add(_ValidatorInfo(
        'maxLength',
        params: {'length': length},
        message: annotation.peek('message')?.stringValue,
      ));
    }

    // Pattern
    if (_patternChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_patternChecker.firstAnnotationOfExact(field));
      final pattern = annotation.read('pattern').stringValue;
      validators.add(_ValidatorInfo(
        'pattern',
        params: {'pattern': pattern},
        message: annotation.peek('message')?.stringValue ?? 'Invalid format',
      ));
    }

    // URL
    if (_urlChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_urlChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'url',
        message: annotation.peek('message')?.stringValue ?? 'Invalid URL format',
      ));
    }

    // Phone
    if (_phoneChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_phoneChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'phone',
        message: annotation.peek('message')?.stringValue ?? 'Invalid phone number',
      ));
    }

    // Alphanumeric
    if (_alphanumericChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_alphanumericChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'alphanumeric',
        message: annotation.peek('message')?.stringValue ?? 'Must contain only letters and numbers',
      ));
    }

    // Alpha
    if (_alphaChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_alphaChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'alpha',
        message: annotation.peek('message')?.stringValue ?? 'Must contain only letters',
      ));
    }

    // Numeric
    if (_numericChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_numericChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'numeric',
        message: annotation.peek('message')?.stringValue ?? 'Must contain only numbers',
      ));
    }

    // Min
    if (_minChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_minChecker.firstAnnotationOfExact(field));
      final value = annotation.read('value').literalValue as num;
      validators.add(_ValidatorInfo(
        'min',
        params: {'value': value},
        message: annotation.peek('message')?.stringValue,
      ));
    }

    // Max
    if (_maxChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_maxChecker.firstAnnotationOfExact(field));
      final value = annotation.read('value').literalValue as num;
      validators.add(_ValidatorInfo(
        'max',
        params: {'value': value},
        message: annotation.peek('message')?.stringValue,
      ));
    }

    // Range
    if (_rangeChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_rangeChecker.firstAnnotationOfExact(field));
      final min = annotation.read('min').literalValue as num;
      final max = annotation.read('max').literalValue as num;
      validators.add(_ValidatorInfo(
        'range',
        params: {'min': min, 'max': max},
        message: annotation.peek('message')?.stringValue,
      ));
    }

    // Positive
    if (_positiveChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_positiveChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'positive',
        message: annotation.peek('message')?.stringValue ?? 'Must be a positive number',
      ));
    }

    // Negative
    if (_negativeChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_negativeChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'negative',
        message: annotation.peek('message')?.stringValue ?? 'Must be a negative number',
      ));
    }

    // EqualTo (cross-field)
    if (_equalToChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_equalToChecker.firstAnnotationOfExact(field));
      final targetField = annotation.read('field').stringValue;
      crossValidators.add(_CrossValidatorInfo(
        'equalTo',
        targetField: targetField,
        message: annotation.peek('message')?.stringValue ?? 'Fields must match',
      ));
    }

    // NotEqualTo (cross-field)
    if (_notEqualToChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_notEqualToChecker.firstAnnotationOfExact(field));
      final targetField = annotation.read('field').stringValue;
      crossValidators.add(_CrossValidatorInfo(
        'notEqualTo',
        targetField: targetField,
        message: annotation.peek('message')?.stringValue ?? 'Fields must be different',
      ));
    }

    // PastDate
    if (_pastDateChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_pastDateChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'pastDate',
        message: annotation.peek('message')?.stringValue ?? 'Date must be in the past',
      ));
    }

    // FutureDate
    if (_futureDateChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_futureDateChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'futureDate',
        message: annotation.peek('message')?.stringValue ?? 'Date must be in the future',
      ));
    }

    // MinAge
    if (_minAgeChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_minAgeChecker.firstAnnotationOfExact(field));
      final years = annotation.read('years').intValue;
      validators.add(_ValidatorInfo(
        'minAge',
        params: {'years': years},
        message: annotation.peek('message')?.stringValue,
      ));
    }

    // MinItems
    if (_minItemsChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_minItemsChecker.firstAnnotationOfExact(field));
      final count = annotation.read('count').intValue;
      validators.add(_ValidatorInfo(
        'minItems',
        params: {'count': count},
        message: annotation.peek('message')?.stringValue,
      ));
    }

    // MaxItems
    if (_maxItemsChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_maxItemsChecker.firstAnnotationOfExact(field));
      final count = annotation.read('count').intValue;
      validators.add(_ValidatorInfo(
        'maxItems',
        params: {'count': count},
        message: annotation.peek('message')?.stringValue,
      ));
    }

    // MustBeTrue
    if (_mustBeTrueChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_mustBeTrueChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'mustBeTrue',
        message: annotation.peek('message')?.stringValue ?? 'This field must be checked',
      ));
    }

    // MustBeFalse
    if (_mustBeFalseChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_mustBeFalseChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'mustBeFalse',
        message: annotation.peek('message')?.stringValue ?? 'This field must be unchecked',
      ));
    }

    // CreditCard
    if (_creditCardChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_creditCardChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'creditCard',
        message: annotation.peek('message')?.stringValue ?? 'Invalid credit card number',
      ));
    }

    // CVV
    if (_cvvChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_cvvChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'cvv',
        message: annotation.peek('message')?.stringValue ?? 'Invalid CVV',
      ));
    }

    // ExpiryDate
    if (_expiryDateChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_expiryDateChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'expiryDate',
        message: annotation.peek('message')?.stringValue ?? 'Invalid or expired date',
      ));
    }

    // StrongPassword
    if (_strongPasswordChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_strongPasswordChecker.firstAnnotationOfExact(field));
      validators.add(_ValidatorInfo(
        'strongPassword',
        params: {
          'minLength': annotation.peek('minLength')?.intValue ?? 8,
          'requireUppercase': annotation.peek('requireUppercase')?.boolValue ?? true,
          'requireLowercase': annotation.peek('requireLowercase')?.boolValue ?? true,
          'requireDigit': annotation.peek('requireDigit')?.boolValue ?? true,
          'requireSpecial': annotation.peek('requireSpecial')?.boolValue ?? false,
        },
        message: annotation.peek('message')?.stringValue ?? 'Password does not meet requirements',
      ));
    }

    // RequiredIf (cross-field)
    if (_requiredIfChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_requiredIfChecker.firstAnnotationOfExact(field));
      final targetField = annotation.read('field').stringValue;
      final value = annotation.read('value').literalValue;
      crossValidators.add(_CrossValidatorInfo(
        'requiredIf',
        targetField: targetField,
        targetValue: value,
        message: annotation.peek('message')?.stringValue ?? 'This field is required',
      ));
    }

    // RequiredUnless (cross-field)
    if (_requiredUnlessChecker.hasAnnotationOfExact(field)) {
      final annotation = ConstantReader(_requiredUnlessChecker.firstAnnotationOfExact(field));
      final targetField = annotation.read('field').stringValue;
      final value = annotation.read('value').literalValue;
      crossValidators.add(_CrossValidatorInfo(
        'requiredUnless',
        targetField: targetField,
        targetValue: value,
        message: annotation.peek('message')?.stringValue ?? 'This field is required',
      ));
    }
  }

  _FieldMetadata? _getFieldMetadata(FieldElement field) {
    if (!_formFieldChecker.hasAnnotationOfExact(field)) return null;

    final annotation = ConstantReader(_formFieldChecker.firstAnnotationOfExact(field));
    return _FieldMetadata(
      label: annotation.peek('label')?.stringValue,
      hint: annotation.peek('hint')?.stringValue,
      helpText: annotation.peek('helpText')?.stringValue,
      obscureText: annotation.peek('obscureText')?.boolValue ?? false,
    );
  }

  String? _getDefaultValue(FieldElement field) {
    final type = field.type;
    if (type.isDartCoreString) return "''";
    if (type.isDartCoreInt) return '0';
    if (type.isDartCoreDouble) return '0.0';
    if (type.isDartCoreBool) return 'false';
    if (type.isDartCoreList) return 'const []';
    if (type.isDartCoreMap) return 'const {}';
    return 'null';
  }

  String _generateCode({
    required String className,
    required String stateName,
    required String controllerName,
    required String fieldEnumName,
    required List<_FieldInfo> fields,
    required bool generateCopyWith,
    required bool validateOnChange,
    required bool validateOnBlur,
  }) {
    final buffer = StringBuffer();

    // Generate field enum
    _generateFieldEnum(buffer, fieldEnumName, fields);
    buffer.writeln();

    // Generate form state class
    _generateFormStateClass(buffer, stateName, fieldEnumName, fields, generateCopyWith, validateOnChange, validateOnBlur);
    buffer.writeln();

    // Generate form controller mixin
    _generateControllerMixin(buffer, className, stateName, controllerName, fieldEnumName, fields);

    return buffer.toString();
  }

  void _generateFieldEnum(StringBuffer buffer, String enumName, List<_FieldInfo> fields) {
    buffer.writeln('/// Enum of form fields for type-safe field references.');
    buffer.writeln('enum $enumName {');
    for (final field in fields) {
      buffer.writeln('  ${field.name},');
    }
    buffer.writeln('}');
  }

  void _generateFormStateClass(
    StringBuffer buffer,
    String stateName,
    String fieldEnumName,
    List<_FieldInfo> fields,
    bool generateCopyWith,
    bool validateOnChange,
    bool validateOnBlur,
  ) {
    buffer.writeln('/// Generated form state for managing field values and validation.');
    buffer.writeln('class $stateName extends FormController<$stateName> {');

    // Constructor
    buffer.writeln('  $stateName({');
    for (final field in fields) {
      buffer.writeln('    FormFieldState<${field.type}>? ${field.name},');
    }
    buffer.writeln('  }) :');
    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      final defaultVal = field.defaultValue ?? 'null';
      buffer.write('    _${field.name} = ${field.name} ?? FormFieldState<${field.type}>(value: $defaultVal, initialValue: $defaultVal)');
      buffer.writeln(i < fields.length - 1 ? ',' : ';');
    }
    buffer.writeln();

    // Factory for initial state
    buffer.writeln('  /// Creates an initial form state.');
    buffer.writeln('  factory $stateName.initial() => $stateName();');
    buffer.writeln();

    // Private field states
    for (final field in fields) {
      buffer.writeln('  final FormFieldState<${field.type}> _${field.name};');
    }
    buffer.writeln();

    // Public getters for field states
    for (final field in fields) {
      buffer.writeln('  /// State for the ${field.name} field.');
      buffer.writeln('  FormFieldState<${field.type}> get ${field.name} => _${field.name};');
    }
    buffer.writeln();

    // Fields map override
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, FormFieldState<dynamic>> get fields => {');
    for (final field in fields) {
      buffer.writeln("    '${field.name}': _${field.name},");
    }
    buffer.writeln('  };');
    buffer.writeln();

    // Validators override
    _generateValidatorsGetter(buffer, fields);
    buffer.writeln();

    // Cross-field validators override
    _generateCrossValidatorsGetter(buffer, fields);
    buffer.writeln();

    // validateOnChange/validateOnBlur overrides
    buffer.writeln('  @override');
    buffer.writeln('  bool get validateOnChange => $validateOnChange;');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  bool get validateOnBlur => $validateOnBlur;');
    buffer.writeln();

    // CopyWith method
    if (generateCopyWith) {
      buffer.writeln('  /// Creates a copy with updated field states.');
      buffer.writeln('  $stateName copyWith({');
      for (final field in fields) {
        buffer.writeln('    FormFieldState<${field.type}>? ${field.name},');
      }
      buffer.writeln('  }) {');
      buffer.writeln('    return $stateName(');
      for (final field in fields) {
        buffer.writeln('      ${field.name}: ${field.name} ?? _${field.name},');
      }
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln();

      // Helper method to update a single field
      buffer.writeln('  /// Creates a copy with an updated field.');
      buffer.writeln('  $stateName updateField(String fieldName, FormFieldState<dynamic> newState) {');
      buffer.writeln('    switch (fieldName) {');
      for (final field in fields) {
        buffer.writeln("      case '${field.name}':");
        buffer.writeln('        return copyWith(${field.name}: newState as FormFieldState<${field.type}>);');
      }
      buffer.writeln('      default:');
      buffer.writeln('        return this;');
      buffer.writeln('    }');
      buffer.writeln('  }');
    }

    buffer.writeln('}');
  }

  void _generateValidatorsGetter(StringBuffer buffer, List<_FieldInfo> fields) {
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, List<Validator<dynamic>>> get validators => {');
    for (final field in fields) {
      if (field.validators.isEmpty) continue;
      buffer.writeln("    '${field.name}': [");
      for (final validator in field.validators) {
        buffer.writeln('      ${_generateValidatorCall(validator, field.type)},');
      }
      buffer.writeln('    ],');
    }
    buffer.writeln('  };');
  }

  void _generateCrossValidatorsGetter(StringBuffer buffer, List<_FieldInfo> fields) {
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, List<CrossFieldValidator<dynamic>>> get crossFieldValidators => {');
    for (final field in fields) {
      if (field.crossValidators.isEmpty) continue;
      buffer.writeln("    '${field.name}': [");
      for (final validator in field.crossValidators) {
        buffer.writeln('      ${_generateCrossValidatorCall(validator)},');
      }
      buffer.writeln('    ],');
    }
    buffer.writeln('  };');
  }

  String _generateValidatorCall(_ValidatorInfo validator, String fieldType) {
    final message = validator.message != null ? "'${_escapeString(validator.message!)}'" : 'null';

    switch (validator.name) {
      case 'required':
        return 'Validators.required($message)';
      case 'email':
        return 'Validators.email($message)';
      case 'minLength':
        final length = validator.params!['length'];
        return 'Validators.minLength($length, $message)';
      case 'maxLength':
        final length = validator.params!['length'];
        return 'Validators.maxLength($length, $message)';
      case 'pattern':
        final pattern = validator.params!['pattern'];
        return "Validators.pattern(r'$pattern', $message)";
      case 'url':
        return 'Validators.url($message)';
      case 'phone':
        return 'Validators.phone($message)';
      case 'alphanumeric':
        return 'Validators.alphanumeric($message)';
      case 'alpha':
        return 'Validators.alpha($message)';
      case 'numeric':
        return 'Validators.numeric($message)';
      case 'min':
        final value = validator.params!['value'];
        return 'Validators.min($value, $message)';
      case 'max':
        final value = validator.params!['value'];
        return 'Validators.max($value, $message)';
      case 'range':
        final min = validator.params!['min'];
        final max = validator.params!['max'];
        return 'Validators.range($min, $max, $message)';
      case 'positive':
        return 'Validators.positive($message)';
      case 'negative':
        return 'Validators.negative($message)';
      case 'pastDate':
        return 'Validators.pastDate($message)';
      case 'futureDate':
        return 'Validators.futureDate($message)';
      case 'minAge':
        final years = validator.params!['years'];
        return 'Validators.minAge($years, $message)';
      case 'minItems':
        final count = validator.params!['count'];
        return 'Validators.minItems($count, $message)';
      case 'maxItems':
        final count = validator.params!['count'];
        return 'Validators.maxItems($count, $message)';
      case 'mustBeTrue':
        return 'Validators.mustBeTrue($message)';
      case 'mustBeFalse':
        return 'Validators.mustBeFalse($message)';
      case 'creditCard':
        return 'Validators.creditCard($message)';
      case 'cvv':
        return 'Validators.cvv($message)';
      case 'expiryDate':
        return 'Validators.expiryDate($message)';
      case 'strongPassword':
        final params = validator.params!;
        return 'Validators.strongPassword(minLength: ${params['minLength']}, requireUppercase: ${params['requireUppercase']}, requireLowercase: ${params['requireLowercase']}, requireDigit: ${params['requireDigit']}, requireSpecial: ${params['requireSpecial']}, message: $message)';
      default:
        return '// Unknown validator: ${validator.name}';
    }
  }

  String _generateCrossValidatorCall(_CrossValidatorInfo validator) {
    final message = "'${_escapeString(validator.message)}'";

    switch (validator.name) {
      case 'equalTo':
        return "Validators.equalTo('${validator.targetField}', $message)";
      case 'notEqualTo':
        return "Validators.notEqualTo('${validator.targetField}', $message)";
      case 'requiredIf':
        final value = _formatValue(validator.targetValue);
        return "Validators.requiredIf('${validator.targetField}', $value, $message)";
      case 'requiredUnless':
        final value = _formatValue(validator.targetValue);
        return "Validators.requiredUnless('${validator.targetField}', $value, $message)";
      default:
        return '// Unknown cross-field validator: ${validator.name}';
    }
  }

  void _generateControllerMixin(
    StringBuffer buffer,
    String className,
    String stateName,
    String controllerName,
    String fieldEnumName,
    List<_FieldInfo> fields,
  ) {
    buffer.writeln('/// Mixin that provides form controller functionality for StateManagers.');
    buffer.writeln('///');
    buffer.writeln('/// Use this mixin with your StateManager to get form handling:');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// @DragonflyStateManager()');
    buffer.writeln('/// class MyStateManager extends StateManager<MyState> with $controllerName {');
    buffer.writeln('///   // ...');
    buffer.writeln('/// }');
    buffer.writeln('/// ```');
    buffer.writeln('mixin $controllerName<S> on StateManager<S> {');
    buffer.writeln('  /// Gets the form state from the current state.');
    buffer.writeln('  /// Override this in your StateManager to return the actual form state.');
    buffer.writeln('  $stateName get formState;');
    buffer.writeln();
    buffer.writeln('  /// Updates the state with a new form state.');
    buffer.writeln('  /// Override this in your StateManager to update the actual state.');
    buffer.writeln('  void updateFormState($stateName newFormState);');
    buffer.writeln();

    // Generate typed update methods for each field
    for (final field in fields) {
      buffer.writeln('  /// Updates the ${field.name} field value.');
      buffer.writeln('  void update${_capitalize(field.name)}(${field.type} value) {');
      buffer.writeln("    final currentField = formState.${field.name};");
      buffer.writeln('    var newField = currentField.copyWith(value: value);');
      buffer.writeln();
      buffer.writeln('    // Validate if validateOnChange is true');
      buffer.writeln('    if (formState.validateOnChange) {');
      buffer.writeln("      final error = formState.validateField('${field.name}');");
      buffer.writeln('      newField = newField.copyWith(error: error, clearError: error == null);');
      buffer.writeln('    }');
      buffer.writeln();
      buffer.writeln("    updateFormState(formState.updateField('${field.name}', newField));");
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Generate typed touch methods for each field
    for (final field in fields) {
      buffer.writeln('  /// Marks the ${field.name} field as touched.');
      buffer.writeln('  void touch${_capitalize(field.name)}() {');
      buffer.writeln("    final currentField = formState.${field.name};");
      buffer.writeln('    var newField = currentField.copyWith(touched: true);');
      buffer.writeln();
      buffer.writeln('    // Validate if validateOnBlur is true');
      buffer.writeln('    if (formState.validateOnBlur) {');
      buffer.writeln("      final error = formState.validateField('${field.name}');");
      buffer.writeln('      newField = newField.copyWith(error: error, clearError: error == null);');
      buffer.writeln('    }');
      buffer.writeln();
      buffer.writeln("    updateFormState(formState.updateField('${field.name}', newField));");
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Generate validateAll method
    buffer.writeln('  /// Validates all fields and returns true if the form is valid.');
    buffer.writeln('  bool validateAllFields() {');
    buffer.writeln('    var newFormState = formState;');
    buffer.writeln('    bool allValid = true;');
    buffer.writeln();
    for (final field in fields) {
      buffer.writeln("    final ${field.name}Error = formState.validateField('${field.name}');");
      buffer.writeln('    newFormState = newFormState.updateField(');
      buffer.writeln("      '${field.name}',");
      buffer.writeln('      formState.${field.name}.copyWith(');
      buffer.writeln('        error: ${field.name}Error,');
      buffer.writeln('        clearError: ${field.name}Error == null,');
      buffer.writeln('        touched: true,');
      buffer.writeln('      ),');
      buffer.writeln('    );');
      buffer.writeln('    if (${field.name}Error != null) allValid = false;');
      buffer.writeln();
    }
    buffer.writeln('    updateFormState(newFormState);');
    buffer.writeln('    return allValid;');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate resetForm method
    buffer.writeln('  /// Resets all fields to their initial values.');
    buffer.writeln('  void resetAllFields() {');
    buffer.writeln('    updateFormState($stateName.initial());');
    buffer.writeln('  }');

    buffer.writeln('}');
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _escapeString(String s) {
    return s.replaceAll("'", "\\'").replaceAll('\n', '\\n');
  }

  String _formatValue(Object? value) {
    if (value == null) return 'null';
    if (value is String) return "'$value'";
    if (value is bool || value is num) return value.toString();
    return value.toString();
  }
}

class _FieldInfo {
  final String name;
  final String type;
  final DartType dartType;
  final List<_ValidatorInfo> validators;
  final List<_CrossValidatorInfo> crossValidators;
  final _FieldMetadata? metadata;
  final String? defaultValue;

  _FieldInfo({
    required this.name,
    required this.type,
    required this.dartType,
    required this.validators,
    required this.crossValidators,
    this.metadata,
    this.defaultValue,
  });
}

class _ValidatorInfo {
  final String name;
  final Map<String, dynamic>? params;
  final String? message;

  _ValidatorInfo(this.name, {this.params, this.message});
}

class _CrossValidatorInfo {
  final String name;
  final String targetField;
  final Object? targetValue;
  final String message;

  _CrossValidatorInfo(
    this.name, {
    required this.targetField,
    this.targetValue,
    required this.message,
  });
}

class _FieldMetadata {
  final String? label;
  final String? hint;
  final String? helpText;
  final bool obscureText;

  _FieldMetadata({
    this.label,
    this.hint,
    this.helpText,
    this.obscureText = false,
  });
}
