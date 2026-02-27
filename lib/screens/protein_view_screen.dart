import 'package:flutter/material.dart';
import 'package:swifty_proteins/widgets/protein/ligand_3d_viewer.dart';
import 'package:swifty_proteins/models/ligand_summary.dart';
import 'package:share_plus/share_plus.dart';

/// Protein View Screen - Molecule Display
class ProteinViewScreen extends StatefulWidget {
  final String ligandId;
  final VoidCallback onBack;

  const ProteinViewScreen({
    super.key,
    required this.ligandId,
    required this.onBack,
  });

  @override
  State<ProteinViewScreen> createState() => _ProteinViewScreenState();
}

class _ProteinViewScreenState extends State<ProteinViewScreen> {
  LigandSummary? _ligandSummary;

  String _buildShareMessage() {
    final summary = _ligandSummary;
    final ligandName = widget.ligandId.toUpperCase();

    if (summary == null) {
      return 'Ligand $ligandName';
    }

    return 'Ligand $ligandName has ${summary.atomCount} atoms. '
        'Molecular formula: ${summary.formula}.';
  }

  Future<void> _shareLigand() async {
    if (_ligandSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molecule details are still loading.'),
        ),
      );
      return;
    }

    await Share.share(_buildShareMessage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ligandId.toUpperCase()),
        centerTitle: false,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: widget.onBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLigand,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Ligand3DViewer(
        ligandId: widget.ligandId,
        onLigandSummary: (summary) {
          if (mounted) {
            setState(() => _ligandSummary = summary);
          }
        },
      ),
    );
  }
}
