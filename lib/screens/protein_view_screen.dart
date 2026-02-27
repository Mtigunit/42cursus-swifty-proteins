import 'package:flutter/material.dart';
import 'package:swifty_proteins/widgets/protein/ligand_3d_viewer.dart';

/// Protein View Screen - Molecule Display
class ProteinViewScreen extends StatelessWidget {
  final String ligandId;
  final VoidCallback onBack;

  const ProteinViewScreen({
    super.key,
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
      body: Ligand3DViewer(ligandId: ligandId),
    );
  }

}
