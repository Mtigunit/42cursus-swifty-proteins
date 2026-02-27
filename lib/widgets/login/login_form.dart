import 'package:flutter/material.dart';
import 'package:swifty_proteins/services/auth_service.dart';
import 'package:swifty_proteins/widgets/login/login_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.authService,
    required this.onSubmit,
    required this.isBiometricLoading,
    super.key,
  });

  final AuthService authService;
  final VoidCallback onSubmit;
  final bool isBiometricLoading;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.authService.formKey,
      child: ListenableBuilder(
        listenable: widget.authService,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledField(
                label: 'Username',
                child: TextFormField(
                  controller: widget.authService.emailController,
                  enabled: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter your username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                )
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'Password',
                child: TextFormField(
                  controller: widget.authService.passwordController,
                  validator: widget.authService.passwordValidator,
                  enabled: true,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => widget.onSubmit(),
                ),
              ),
              const SizedBox(height: 32),
              LoginButton(
                isLoading: widget.authService.isLoginLoading,
                isDisabled: widget.isBiometricLoading,
                onPressed: () => widget.authService.onSignIn(context),
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
