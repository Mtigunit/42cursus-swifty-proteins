import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          label: 'Username',
          child: TextField(
            controller: usernameController,
            focusNode: usernameFocus,
            enabled: !isLoading,
            decoration: const InputDecoration(
              hintText: 'Enter your username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => passwordFocus.requestFocus(),
          ),
        ),
        const SizedBox(height: 20),
        _LabeledField(
          label: 'Password',
          child: TextField(
            controller: passwordController,
            focusNode: passwordFocus,
            enabled: !isLoading,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
      ],
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
