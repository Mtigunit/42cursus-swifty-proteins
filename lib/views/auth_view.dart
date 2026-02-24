import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool _isSignIn = true;
  String? _errorMessage;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final LocalAuthentication localAuth = LocalAuthentication();
  User? get currentUser => firebaseAuth.currentUser;

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

  Future<void> _storeToken(User? user) async {
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        await secureStorage.write(key: 'token', value: token);
        await secureStorage.write(key: 'uid', value: user.uid);
        await secureStorage.write(key: 'email', value: user.email ?? '');
      }
    }
  }

  Future<bool> hasValidToken() async {
    final token = await secureStorage.read(key: 'user_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> _clearStoredToken() async {
    await secureStorage.delete(key: 'user_token');
    await secureStorage.delete(key: 'user_uid');
    await secureStorage.delete(key: 'user_email');
  }

  Future<bool> authenticateWithLocalAuth(BuildContext context) async {
    try {
      final canAuthenticateWithBiometrics = await localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        if (context.mounted) {
          print('Biometric authentication not available');
        }
        return false;
      }

      final hasToken = await hasValidToken();
      if (!hasToken) {
        if (context.mounted) {
          print('Please login first');
        }
        return false;
      }

      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
      );

      if (didAuthenticate) {
        final token = await secureStorage.read(key: 'user_token');
        final uid = await secureStorage.read(key: 'user_uid');

        if (token != null && uid != null) {
          if (currentUser == null || currentUser?.uid != uid) {
            if (context.mounted) {
              print('Please sign in again');
            }
            await _clearStoredToken();
            return false;
          }

          if (context.mounted) {
            print('Authentication successful!');
            Navigator.pushReplacementNamed(context, "/home");
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Local auth error: $e');
      if (context.mounted) {
        print('Authentication failed');
      }
      return false;
    }
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
            final credentials = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );
            await _storeToken(credentials.user);

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
              const SizedBox(height: 32,),
              IconButton(
                onPressed: () => authenticateWithLocalAuth,
                icon: Icon(
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
  }

}
