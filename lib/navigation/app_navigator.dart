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

class _AppNavigatorState extends State<AppNavigator> {
  // Navigation state
  // TODO: Replace with actual authentication state from services
  bool _isAuthenticated = false;
  Molecule? _currentMolecule;
  String? _currentLigandId;
  List<String> _ligands = [];
  bool _isLoadingLigands = true;

  @override
  void initState() {
    super.initState();
    _loadLigands();
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

  void _handleLogin(String username, String password) {
    // TODO: Call actual authentication service
    // Mock implementation - just transition to ligand list
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isAuthenticated = true);
      }
    });
  }

  void _handleBiometricLogin() {
    // TODO: Call actual biometric service
    // Mock implementation
    setState(() => _isAuthenticated = true);
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

  void _handleLogout() {
    setState(() {
      _isAuthenticated = false;
      _currentMolecule = null;
      _currentLigandId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while ligands are being loaded
    if (_isLoadingLigands) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show Protein View if molecule is loaded
    if (_currentMolecule != null && _currentLigandId != null) {
      return ProteinViewScreen(
        molecule: _currentMolecule!,
        ligandId: _currentLigandId!,
        onBack: _handleBackFromProteinView,
      );
    }

    // Show Ligand List if authenticated
    if (_isAuthenticated) {
      return LigandListScreen(
        ligands: _ligands,
        onLigandSelected: _handleLigandSelected,
        onLogout: _handleLogout,
      );
    }

    // Show Login screen by default
    return LoginScreen(
      biometricAvailable: true,
      onPasswordLogin: _handleLogin,
      onBiometricLogin: _handleBiometricLogin,
    );
  }
}
