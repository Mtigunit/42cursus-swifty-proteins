import 'package:flutter/material.dart';
import 'package:swifty_proteins/models/molecule.dart';

/// Protein View Screen - Molecule Display
class ProteinViewScreen extends StatelessWidget {
  final Molecule molecule;
  final String ligandId;
  final VoidCallback onBack;

  const ProteinViewScreen({
    super.key,
    required this.molecule,
    required this.ligandId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ligandId.toUpperCase()),
        centerTitle: false,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Text(
          '3D Protein Viewer Coming Soon',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
