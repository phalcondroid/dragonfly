import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/auth/domain/forms/login_form.dart';
import 'package:example/components/auth/presentation/features/login_state_manager.dart';
import 'package:example/components/auth/presentation/states/login_state.dart';
import 'package:flutter/material.dart';

part 'login_screen.view.dart';

/// Reads the form out of any [LoginState] variant.
LoginFormState _formOf(LoginState state) => state.when(
      initial: (form) => form,
      editing: (form) => form,
      loading: (form) => form,
      success: (form) => form,
      error: (form, _) => form,
    );

@Screen(path: '/login', name: 'login', stateManager: LoginStateManager, access: AccessLevel.guest)
class LoginScreen extends StatelessWidget with $LoginStateManager {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Logo/Header
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Form
              ValidatedForm(
                child: Column(
                  children: [
                    ValidatedTextField<LoginState>(
                      stateController: _loginStateManagerController,
                      fieldName: 'email',
                      formSelector: _formOf,
                      onChanged: emailChanged,
                      onBlur: emailTouched,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 16),

                    ValidatedTextField<LoginState>(
                      stateController: _loginStateManagerController,
                      fieldName: 'password',
                      formSelector: _formOf,
                      onChanged: passwordChanged,
                      onBlur: passwordTouched,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => login(),
                    ),

                    const SizedBox(height: 16),

                    ValidatedCheckbox<LoginState>(
                      stateController: _loginStateManagerController,
                      fieldName: 'acceptTerms',
                      formSelector: _formOf,
                      onChanged: (value) => acceptTermsChanged(value ?? false),
                      title: const Text('I accept the terms and conditions'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error banner — builds only while the state is `error`.
              buildError(
                (form, message) => Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Success panel — replaces the submit button on success.
              buildSuccess(
                (form) => Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, ${form.values['email']}!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: logout,
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              ),

              // Submit button — spinner while `loading`.
              when(
                success: (form) => const SizedBox.shrink(),
                loading: (form) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                orElse: () => FilledButton(
                  onPressed: login,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
