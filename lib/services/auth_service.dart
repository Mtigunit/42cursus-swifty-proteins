import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:swifty_proteins/widgets/common/error_dialog.dart';

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
  bool isBiometricAvailable = false;

  String? errorMessage;

  User? get currentUser => _firebaseAuth.currentUser;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> checkBiometricAvailability() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      isBiometricAvailable = canAuthenticate;
      notifyListeners();
    } catch (e) {
      log('Error checking biometric availability: $e');
      isBiometricAvailable = false;
      notifyListeners();
    }
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
    } on FirebaseAuthException catch (e) {
      String message = _getErrorMessage(e);
      if (context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Authentication Failed',
          message: message,
        );
      }
      log('Biometric auth error: $e');
      return false;
    } catch (e) {
      log('Biometric auth error: $e');
      if (context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Authentication Failed',
          message: 'An unexpected error occurred. Please try again.',
        );
      }
      return false;
    } finally {
      isBiometricLoading = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    return switch (e.code) {
      'network-request-failed' =>
        'No internet connection. Please check your connection and try again.',
      'invalid-email' => 'The email address is invalid.',
      'user-disabled' =>
        'This account has been disabled. Please contact support.',
      'user-not-found' => 'No account found with this email address.',
      'wrong-password' || 'invalid-credential' => 'Incorrect password.',
      'email-already-in-use' => 'This email is already in use.',
      'weak-password' =>
        'The password is too weak. Please use a stronger password.',
      'operation-not-allowed' =>
        'Sign in is currently disabled. Please try again later.',
      'too-many-requests' => 'Too many login attempts. Please try again later.',
      _ => 'An error occurred: ${e.message}',
    };
  }

  Future<void> onSignIn(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    final email = "${emailController.text}@swifty.pro";
    isLoginLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );
      await _secureStorage.write(key: "email", value: email);
      await _secureStorage.write(key: "pass", value: passwordController.text);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: passwordController.text,
          );
          await _secureStorage.write(key: "email", value: email);
          await _secureStorage.write(
            key: "pass",
            value: passwordController.text,
          );
        } on FirebaseAuthException catch (signInError) {
          String message = _getErrorMessage(signInError);
          if (context.mounted) {
            await ErrorDialog.show(
              context,
              title: 'Login Failed',
              message: message,
            );
          }
        }
      } else {
        String message = _getErrorMessage(e);
        if (context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Sign Up Failed',
            message: message,
          );
        }
      }
    } catch (e) {
      log('Sign in error: $e');
      if (context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error',
          message: 'An unexpected error occurred. Please try again.',
        );
      }
    } finally {
      isLoginLoading = false;
      notifyListeners();
    }
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

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
