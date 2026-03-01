import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swifty_proteins/screens/ligand_list_screen.dart';
import 'package:swifty_proteins/screens/login_screen.dart';
import 'package:swifty_proteins/screens/protein_view_screen.dart';
import 'package:swifty_proteins/services/ligand_service.dart';

/// Manages app-level navigation, authentication state, and ligand data loading.
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator>
    with WidgetsBindingObserver {
  // Navigation state
  String? _selectedLigandId;

  // Data state
  List<String> _ligands = [];
  bool _isLoadingLigands = true;

  // Service dependencies
  late final FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    WidgetsBinding.instance.addObserver(this);
    _initializeLigands();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handles app lifecycle state changes. Logs out user when app is backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is backgrounded - logout user
      unawaited(_signOutAndReset());
    }
  }

  /// Initializes ligand data on app startup.
  Future<void> _initializeLigands() async {
    try {
      final ligands = await LigandService.loadLigands();
      if (mounted) {
        setState(() {
          _ligands = ligands;
          _isLoadingLigands = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLigands = false);
        _showErrorMessage('Failed to load ligands: $e');
      }
    }
  }

  /// Signs out the user and resets navigation state.
  Future<void> _signOutAndReset() async {
    try {
      await _auth.signOut();
      if (mounted) {
        setState(() => _selectedLigandId = null);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Sign out failed: $e');
      }
    }
  }

  /// Displays an error message via SnackBar.
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  /// Handles selection of a ligand to view.
  void _onLigandSelected(String ligandId) {
    setState(() => _selectedLigandId = ligandId);
  }

  /// Handles navigation back from protein view screen.
  void _onProteinViewBack() {
    setState(() => _selectedLigandId = null);
  }

  /// Handles user logout action.
  Future<void> _onLogout() async {
    await _signOutAndReset();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading state while Firebase initializes or ligands load
        if (snapshot.connectionState == ConnectionState.waiting ||
            _isLoadingLigands) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is authenticated
        if (snapshot.hasData) {
          if (_selectedLigandId != null) {
            return ProteinViewScreen(
              ligandId: _selectedLigandId!,
              onBack: _onProteinViewBack,
            );
          }

          return LigandListScreen(
            ligands: _ligands,
            onLigandSelected: _onLigandSelected,
            onLogout: _onLogout,
          );
        }

        // User is not authenticated
        return const LoginScreen();
      },
    );
  }
}
