import 'package:flutter/material.dart';
import 'package:swifty_proteins/models/molecule.dart';
import 'package:swifty_proteins/widgets/protein/ligand_3d_viewer.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showMoleculeInfo(context),
            tooltip: 'Molecule Info',
          ),
        ],
      ),
      body: Ligand3DViewer(ligandId: ligandId),
    );
  }

  void _showMoleculeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ligandId.toUpperCase()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Atoms', value: '${molecule.atoms.length}'),
              _InfoRow(label: 'Bonds', value: '${molecule.bonds.length}'),
              const SizedBox(height: 16),
              Text(
                'Atom Types',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ..._getAtomTypeCounts().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text('${entry.key}: ${entry.value}'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getAtomTypeCounts() {
    final counts = <String, int>{};
    for (final atom in molecule.atoms) {
      counts[atom.element] = (counts[atom.element] ?? 0) + 1;
    }
    return counts;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
