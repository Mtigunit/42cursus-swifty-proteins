import 'package:flutter/material.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  bool _isSignIn = true;
  String? _errorMessage;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePage() {
    setState(() {
      _isSignIn = !_isSignIn;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  Future<void> _onSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    try {
      // Try to create account first
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
        // Account exists, try to sign in instead
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );
          } on FirebaseAuthException catch (signInError) {
            setState(() {
              switch (signInError.code) {
                case 'wrong-password':
                case 'invalid-credential':
                  _errorMessage = 'Incorrect password.';
                default:
                  _errorMessage = 'An error occurred. Please try again.';
              }
            });
          }
        case 'weak-password':
          setState(() => _errorMessage = 'The password provided is too weak.');
        default:
          setState(() => _errorMessage = 'An error occurred. Please try again.');
      }
    }
  }
  String? _emailValidator(String? val) {
    if (val == null || val.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
    return null;
  }

  String? _passwordValidator(String? val) {
    if (val == null || val.isEmpty) return 'Password is required';
    if (val.length < 8) return 'At least 8 characters';
    if (!val.contains(RegExp(r'[A-Z]'))) return 'At least one uppercase letter';
    if (!val.contains(RegExp(r'[0-9]'))) return 'At least one number';
    if (!val.contains(RegExp(r'[!@#\$&*~]'))) return 'At least one special character (!@#\$&*~)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignIn ? 'Sign In' : 'Sign Up'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                validator: _emailValidator,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: _passwordValidator,
              ),
              const SizedBox(height: 32),
              // add this 👇
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 32),
              AuthButton(
                label: 'Sign In',
                onPressed: _isSignIn ? _onSignIn : _togglePage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
