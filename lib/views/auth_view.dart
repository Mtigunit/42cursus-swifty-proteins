import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final AuthController _controller = AuthController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_controller.isSignIn ? 'Sign In' : 'Sign Up'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _controller.formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthTextField(
                    controller: _controller.emailController,
                    label: 'Email',
                    validator: _controller.emailValidator,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _controller.passwordController,
                    label: 'Password',
                    obscureText: true,
                    validator: _controller.passwordValidator,
                  ),
                  const SizedBox(height: 32),
                  if (_controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 32),
                  AuthButton(
                    label: 'Sign In',
                    onPressed: _controller.isSignIn
                        ? () => _controller.onSignIn(context)
                        : _controller.togglePage,
                  ),
                  const SizedBox(height: 32),
                  IconButton(
                    onPressed: () async {
                      await _controller.authenticateWithBiometrics(context);
                    },
                    icon: const Icon(
                      Icons.fingerprint,
                      size: 40,
                      color: Color(0xFF9EC90E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
