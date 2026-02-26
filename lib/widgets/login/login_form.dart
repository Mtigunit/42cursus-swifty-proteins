import 'package:flutter/material.dart';
import 'package:swifty_proteins/services/auth_service.dart';
import 'package:swifty_proteins/widgets/login/login_button.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.authService,
    required this.onSubmit,
    super.key,
  });

  final AuthService authService;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: authService.formKey,
      child: ListenableBuilder(
        listenable: authService,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledField(
                label: 'Email',
                child: TextFormField(
                  controller: authService.emailController,
                  validator: authService.emailValidator,
                  enabled: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'Password',
                child: TextFormField(
                  controller: authService.passwordController,
                  validator: authService.passwordValidator,
                  enabled: true,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
                ),
              ),
              if (authService.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    authService.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 32),
              LoginButton(
                isLoading: false,
                onPressed: () => authService.onSignIn(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}