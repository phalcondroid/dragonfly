import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/auth/domain/forms/login_form.dart';
import 'package:example/components/auth/presentation/features/login_state_manager.dart';
import 'package:example/components/auth/presentation/states/login_state.dart';
import 'package:flutter/material.dart';

@DragonflyScreen(
  path: '/login',
  name: 'login',
  provider: LoginStateManager,
  access: AccessLevel.guest,
)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultSideEffectHandler<LoginStateManager>(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          centerTitle: true,
        ),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Form
                const _LoginForm(),

                const SizedBox(height: 24),

                // Error message
                StateManagerBuilder<LoginStateManager, LoginState>(
                  buildWhen: (prev, curr) =>
                      (prev is LoginStateError) != (curr is LoginStateError),
                  builder: (context, state) {
                    if (state is LoginStateError) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.message,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Submit button
                const _SubmitButton(),

                const SizedBox(height: 16),

                // Forgot password link
                _ForgotPasswordLink(),

                const SizedBox(height: 24),

                // Register link
                _RegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    final stateManager = context.stateManager<LoginStateManager>();

    return ValidatedForm(
      child: Column(
        children: [
          // Email field
          ValidatedTextField<LoginStateManager, LoginState>(
            fieldName: 'email',
            formSelector: (state) => state.when(
              initial: () => LoginFormState.initial(),
              loading: (form) => form,
              success: (form) => form,
              error: (form, _) => form,
            ),
            onChanged: stateManager.updateEmail,
            onBlur: stateManager.touchEmail,
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

          // Password field
          ValidatedTextField<LoginStateManager, LoginState>(
            fieldName: 'password',
            formSelector: (state) => state.when(
              initial: () => LoginFormState.initial(),
              loading: (form) => form,
              success: (form) => form,
              error: (form, _) => form,
            ),
            onChanged: stateManager.updatePassword,
            onBlur: stateManager.touchPassword,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock_outlined),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => stateManager.login(),
          ),

          const SizedBox(height: 16),

          // Accept terms checkbox
          ValidatedCheckbox<LoginStateManager, LoginState>(
            fieldName: 'acceptTerms',
            formSelector: (state) => state.when(
              initial: () => LoginFormState.initial(),
              loading: (form) => form,
              success: (form) => form,
              error: (form, _) => form,
            ),
            onChanged: (value) => stateManager.updateAcceptTerms(value ?? false),
            title: const Text('I accept the terms and conditions'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    final stateManager = context.stateManager<LoginStateManager>();

    return StateManagerBuilder<LoginStateManager, LoginState>(
      builder: (context, state) {
        final isLoading = state is LoginStateLoading;
        final formState = state.when(
          initial: () => LoginFormState.initial(),
          loading: (form) => form,
          success: (form) => form,
          error: (form, _) => form,
        );

        return FilledButton(
          onPressed: isLoading ? null : stateManager.login,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stateManager = context.stateManager<LoginStateManager>();

    return TextButton(
      onPressed: stateManager.goToForgotPassword,
      child: const Text('Forgot your password?'),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stateManager = context.stateManager<LoginStateManager>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?"),
        TextButton(
          onPressed: stateManager.goToRegistration,
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}
