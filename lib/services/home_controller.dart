import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signOut(BuildContext context) async {
    await _firebaseAuth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
