import 'package:dragonfly_annotations/dragonfly_annotations.dart';

part 'registration_form.form.dart';

/// Registration form schema with advanced validation rules.
///
/// This form demonstrates:
/// - Cross-field validation (confirmPassword must match password)
/// - Conditional validation (companyName required if isCompany is true)
/// - Pattern validation
/// - Age validation
@FormSchema(
  validateOnChange: true,
  validateOnBlur: true,
)
class RegistrationForm {
  @Required(message: 'First name is required')
  @Alpha(message: 'First name must contain only letters')
  @MinLength(2, message: 'First name must be at least 2 characters')
  @FormField(
    label: 'First Name',
    hint: 'Enter your first name',
    textCapitalization: FormTextCapitalization.words,
  )
  final String firstName;

  @Required(message: 'Last name is required')
  @Alpha(message: 'Last name must contain only letters')
  @MinLength(2, message: 'Last name must be at least 2 characters')
  @FormField(
    label: 'Last Name',
    hint: 'Enter your last name',
    textCapitalization: FormTextCapitalization.words,
  )
  final String lastName;

  @Required(message: 'Email is required')
  @Email(message: 'Please enter a valid email address')
  @FormField(
    label: 'Email',
    hint: 'Enter your email address',
    keyboardType: FormKeyboardType.emailAddress,
  )
  final String email;

  @Required(message: 'Username is required')
  @MinLength(3, message: 'Username must be at least 3 characters')
  @MaxLength(20, message: 'Username must be at most 20 characters')
  @Alphanumeric(message: 'Username must contain only letters and numbers')
  @FormField(
    label: 'Username',
    hint: 'Choose a username',
  )
  final String username;

  @Required(message: 'Password is required')
  @StrongPassword(
    minLength: 8,
    requireUppercase: true,
    requireLowercase: true,
    requireDigit: true,
    requireSpecial: true,
    message: 'Password must have 8+ chars, upper, lower, digit, special',
  )
  @FormField(
    label: 'Password',
    hint: 'Create a strong password',
    obscureText: true,
    helpText: 'Must be 8+ characters with uppercase, lowercase, number, and special character',
  )
  final String password;

  @Required(message: 'Please confirm your password')
  @EqualTo('password', message: 'Passwords do not match')
  @FormField(
    label: 'Confirm Password',
    hint: 'Confirm your password',
    obscureText: true,
  )
  final String confirmPassword;

  @Phone(message: 'Please enter a valid phone number')
  @FormField(
    label: 'Phone Number',
    hint: 'Enter your phone number (optional)',
    keyboardType: FormKeyboardType.phone,
  )
  final String phone;

  @MinAge(18, message: 'You must be at least 18 years old')
  @FormField(
    label: 'Date of Birth',
    hint: 'Select your date of birth',
  )
  final DateTime? dateOfBirth;

  final bool isCompany;

  @RequiredIf('isCompany', true, message: 'Company name is required')
  @MinLength(2, message: 'Company name must be at least 2 characters')
  @FormField(
    label: 'Company Name',
    hint: 'Enter your company name',
  )
  final String companyName;

  @Url(message: 'Please enter a valid website URL')
  @FormField(
    label: 'Website',
    hint: 'Enter your website (optional)',
    keyboardType: FormKeyboardType.url,
  )
  final String website;

  @MustBeTrue(message: 'You must accept the terms and conditions')
  final bool acceptTerms;

  @MustBeTrue(message: 'You must accept the privacy policy')
  final bool acceptPrivacy;

  const RegistrationForm({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.username = '',
    this.password = '',
    this.confirmPassword = '',
    this.phone = '',
    this.dateOfBirth,
    this.isCompany = false,
    this.companyName = '',
    this.website = '',
    this.acceptTerms = false,
    this.acceptPrivacy = false,
  });
}
