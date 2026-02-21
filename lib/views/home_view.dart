import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // StreamBuilder handles the rest
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Hey ${user?.email ?? 'User'}!',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}