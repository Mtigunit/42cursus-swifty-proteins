import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isSignIn = true;
  String? errorMessage;

  // User? get currentUser => _firebaseAuth.currentUser;

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

  Future<void> _storeToken(User? user) async {
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'token', value: token);
        await _secureStorage.write(key: 'uid', value: user.uid);
        await _secureStorage.write(key: 'email', value: user.email ?? '');
      }
    }
  }

  Future<bool> hasValidToken() async {
    final token = await _secureStorage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  Future<void> _clearStoredToken() async {
    await _secureStorage.delete(key: 'token');
    await _secureStorage.delete(key: 'uid');
    await _secureStorage.delete(key: 'email');
  }

  Future<bool> authenticateWithBiometrics(BuildContext context) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser ?? await _firebaseAuth.authStateChanges().first;

      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      final hasToken = await hasValidToken();
      if (!hasToken) {
        if (context.mounted)
          print('DESIGN => Please login first');
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
      );

      if (didAuthenticate) {
        final token = await _secureStorage.read(key: 'token');
        final uid = await _secureStorage.read(key: 'uid');
        log("token ===> ${token}");

        if (token != null && uid != null) {
          
          log(firebaseUser == null ? "current user TRUE" : "current user FALSE");
          if (firebaseUser == null || firebaseUser.uid != uid) {
            // show an error 
            if (context.mounted) {
              print("DESIGN => You need to sing in again");
            }
            await _clearStoredToken();
            return false;
          }
          if (context.mounted) {
            print("DESIGN => Success authentication");
            Navigator.pushReplacementNamed(context, "/home");
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Local auth error: $e');
      if (context.mounted) {
        print('DESIGN => Auth failed ');
      }
      return false;
    }
  }

  Future<void> onSignIn() async {
    if (!formKey.currentState!.validate()) return;
    errorMessage = null;
    notifyListeners();

    try {
      final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      await _storeToken(credentials.user); 

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          try {
            final credentials = await _firebaseAuth.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
            await _storeToken(credentials.user);
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
