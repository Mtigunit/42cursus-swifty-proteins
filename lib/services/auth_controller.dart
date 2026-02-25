import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isSignIn = true;
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

  Future<bool> _hasValidSession() async {
    final user = _firebaseAuth.currentUser;
    return user != null;
  }

  Future<bool> authenticateWithBiometrics(BuildContext context) async {
    try {
      final validSession = await _hasValidSession();
      // Only proceed if we have a valid session
      if (!validSession) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again')),
          );
        }
        return false;
      }

      // Check if device supports biometric
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric not available on this device')),
          );
        }
        return false;
      }

      // Show native biometric dialog
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
      );

      if (!didAuthenticate) {
        return false;
      }

      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
      return true;
    } catch (e) {
      log('Biometric auth error: $e');
      return false;
    }
  }

  Future<void> onSignIn(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    errorMessage = null;
    notifyListeners();

    try {
      log('DESIGN => Attempting to sign up...');
      var credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      log('DESIGN => Sign up successful: ${credential.user?.uid}');
      // await _storeUserToken(credential.user);
      log('DESIGN => Token stored');
      // Wait a moment for auth state to update
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          log('DESIGN => Email already in use, attempting sign in...');
          try {
            var credential = await _firebaseAuth.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
            log('DESIGN => Sign in successful: ${credential.user?.uid}');
            // await _storeUserToken(credential.user);
            log('DESIGN => Token stored');
            // Wait a moment for auth state to update
            await Future.delayed(const Duration(milliseconds: 500));
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          } on FirebaseAuthException catch (signInError) {
            switch (signInError.code) {
              case 'wrong-password':
              case 'invalid-credential':
                errorMessage = 'Incorrect password.';
              default:
                errorMessage = 'An error occurred. Please try again.';
            }
            notifyListeners();
          }
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          notifyListeners();
        default:
          errorMessage = 'An error occurred. Please try again.';
          notifyListeners();
      }
    }
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
