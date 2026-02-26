import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swifty_proteins/models/molecule.dart';
import 'package:swifty_proteins/screens/ligand_list_screen.dart';
import 'package:swifty_proteins/screens/login_screen.dart';
import 'package:swifty_proteins/screens/protein_view_screen.dart';
import 'package:swifty_proteins/services/ligand_service.dart';
import 'package:vector_math/vector_math.dart';

/// Handles transitions between Login, List, and Protein View screens
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> with WidgetsBindingObserver {
  Molecule? _currentMolecule;
  String? _currentLigandId;
  List<String> _ligands = [];
  bool _isLoadingLigands = true;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLigands();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is backgrounded - logout user
      unawaited(_firebaseAuth.signOut());
    }
  }

  Future<void> _loadLigands() async {
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
        setState(() {
          _isLoadingLigands = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ligands: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Mock function to get ligand - replace with actual service
  Future<Molecule> _fetchLigand(String ligandId) async {
    // TODO: Call actual fetchLigand from services
    // This is a mock implementation
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock molecule
    return Molecule(
      atoms: [
        Atom(element: 'C', position: Vector3(0, 0, 0)),
        Atom(element: 'O', position: Vector3(1.2, 0, 0)),
        Atom(element: 'N', position: Vector3(-1.2, 0, 0)),
        Atom(element: 'H', position: Vector3(0, 1.2, 0)),
        Atom(element: 'S', position: Vector3(0, -1.2, 0)),
      ],
      bonds: [
        Bond(atomIndex1: 0, atomIndex2: 1),
        Bond(atomIndex1: 0, atomIndex2: 2),
        Bond(atomIndex1: 0, atomIndex2: 3),
        Bond(atomIndex1: 0, atomIndex2: 4),
      ],
    );
  }

  Future<void> _handleLigandSelected(String ligandId) async {
    try {
      final molecule = await _fetchLigand(ligandId);
      if (mounted) {
        setState(() {
          _currentMolecule = molecule;
          _currentLigandId = ligandId;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ligand: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleBackFromProteinView() {
    setState(() {
      _currentMolecule = null;
      _currentLigandId = null;
    });
  }

  Future<void> _handleLogout() async {
    await _firebaseAuth.signOut();
    setState(() {
      _currentMolecule = null;
      _currentLigandId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase connection still initializing
        if (snapshot.connectionState == ConnectionState.waiting ||
            _isLoadingLigands) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Authenticated — show protein view or ligand list
        if (snapshot.hasData) {
          if (_currentMolecule != null && _currentLigandId != null) {
            return ProteinViewScreen(
              molecule: _currentMolecule!,
              ligandId: _currentLigandId!,
              onBack: _handleBackFromProteinView,
            );
          }

          return LigandListScreen(
            ligands: _ligands,
            onLigandSelected: _handleLigandSelected,
            onLogout: _handleLogout,
          );
        }

        // Not authenticated — show login
        return const LoginScreen();
      },
    );
  }
}
