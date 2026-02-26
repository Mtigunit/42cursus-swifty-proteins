import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isSignIn = true;
  bool isLoginLoading = false;
  bool isBiometricLoading = false;

  String? errorMessage;

  User? get currentUser => _firebaseAuth.currentUser;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void togglePage() {
    isSignIn = !isSignIn;
    emailController.clear();
    passwordController.clear();
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics(BuildContext context) async {
    isBiometricLoading = true;
    notifyListeners();

    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric not available on this device'),
            ),
          );
        }
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
      );

      if (!didAuthenticate) return false;

      final email = await _secureStorage.read(key: "email");
      final pass = await _secureStorage.read(key: "pass");
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email!,
        password: pass!,
      );
      return true;
    } catch (e) {
      log('Biometric auth error: $e');
      return false;
    } finally {
      isBiometricLoading = false;
      notifyListeners();
    }
  }

  Future<void> onSignIn(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    isLoginLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      await _secureStorage.write(key: "email", value: emailController.text);
      await _secureStorage.write(key: "pass", value: passwordController.text);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          try {
            await _firebaseAuth.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
            await _secureStorage.write(
              key: "email",
              value: emailController.text,
            );
            await _secureStorage.write(
              key: "pass",
              value: passwordController.text,
            );
          } on FirebaseAuthException catch (signInError) {
            errorMessage = switch (signInError.code) {
              'wrong-password' || 'invalid-credential' => 'Incorrect password.',
              _ => 'An error occurred. Please try again.',
            };
            notifyListeners();
          }
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          notifyListeners();
        default:
          errorMessage = 'An error occurred. Please try again.';
          notifyListeners();
      }
    } finally {
      isLoginLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkPreviousSession() async {
    final email = await _secureStorage.read(key: "email");
    return email != null;
    // if (mounted) {
    //   setState(() => _hasPreviousSession = email != null);
    // }
  }

  String? emailValidator(String? val) {
    if (val == null || val.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
    return null;
  }

  String? passwordValidator(String? val) {
    if (val == null || val.isEmpty) return 'Password is required';
    if (val.length < 8) return 'At least 8 characters';
    if (!val.contains(RegExp(r'[A-Z]'))) return 'At least one uppercase letter';
    if (!val.contains(RegExp(r'[0-9]'))) return 'At least one number';
    if (!val.contains(RegExp(r'[!@#\$&*~]'))) {
      return 'At least one special character (!@#\$&*~)';
    }
    return null;
  }
}
