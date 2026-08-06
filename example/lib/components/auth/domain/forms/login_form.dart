import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'login_form.form.dart';

/// Login form schema with validation rules.
///
/// This form demonstrates:
/// - Required field validation
/// - Email format validation
/// - Password strength validation
/// - Boolean validation (terms acceptance)
@FormSchema()
class LoginForm {
  @Required(message: 'Email is required')
  @Email(message: 'Please enter a valid email address')
  @FormField(
    label: 'Email',
    hint: 'Enter your email address',
    keyboardType: FormKeyboardType.emailAddress,
  )
  final String email;

  @Required(message: 'Password is required')
  @MinLength(8, message: 'Password must be at least 8 characters')
  @StrongPassword(
    requireUppercase: true,
    requireLowercase: true,
    requireDigit: true,
    requireSpecial: false,
  )
  @FormField(
    label: 'Password',
    hint: 'Enter your password',
    obscureText: true,
  )
  final String password;

  @MustBeTrue(message: 'You must accept the terms and conditions')
  final bool acceptTerms;

  const LoginForm({
    this.email = '',
    this.password = '',
    this.acceptTerms = false,
  });
}
