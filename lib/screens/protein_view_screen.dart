import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swifty_proteins/models/ligand_summary.dart';
import 'package:swifty_proteins/widgets/protein/ligand_3d_viewer.dart';

/// Displays a 3D molecular structure viewer for a specific ligand.
///
/// Provides interactive visualization and sharing capabilities.
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
  final GlobalKey<Ligand3DViewerState> _viewerKey =
      GlobalKey<Ligand3DViewerState>();

  /// Updates the ligand summary when loaded by the 3D viewer.
  void _onLigandLoaded(LigandSummary summary) {
    if (mounted) {
      setState(() => _ligandSummary = summary);
    }
  }

  /// Handles share button press - captures screenshot and shares ligand data.
  Future<void> _onSharePressed() async {
    if (_ligandSummary == null) {
      _showError('Molecule details are still loading.');
      return;
    }

    try {
      final imageBytes = await _captureScreenshot();
      if (imageBytes == null) {
        _showError('Unable to capture the ligand image yet.');
        return;
      }

      final imageFile = await _createTempImageFile(imageBytes);
      await _shareImage(imageFile);
    } catch (e) {
      _showError('Failed to share ligand: $e');
    }
  }

  /// Captures a PNG screenshot of the current 3D viewer state.
  Future<Uint8List?> _captureScreenshot() async {
    return _viewerKey.currentState?.capturePngBytes();
  }

  /// Creates a temporary file containing the ligand image.
  Future<File> _createTempImageFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'ligand_${widget.ligandId.toLowerCase()}.png';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(imageBytes, flush: true);
    return file;
  }

  Future<void> _shareImage(File imageFile) async {
    final params = ShareParams(
      files: [XFile(imageFile.path)],
      text: _buildShareText(),
    );

    final result = await SharePlus.instance.share(params);
    if (result.status != ShareResultStatus.success) {
      _showError('Failed to share ligand: ${result.status}');
    }
  }
  // /// Opens the native share dialog with the ligand image and details.
  // Future<void> _shareImage(File imageFile) async {
  //   await Share.shareXFiles([XFile(imageFile.path)], text: _buildShareText());
  // }

  /// Builds the text message to accompany the shared image.
  String _buildShareText() {
    final ligandName = widget.ligandId.toUpperCase();
    final summary = _ligandSummary;

    if (summary == null) {
      return 'Ligand $ligandName';
    }

    return 'Ligand $ligandName has ${summary.atomCount} atoms. '
        'Molecular formula: ${summary.formula}.';
  }

  /// Displays an error message to the user via SnackBar.
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Ligand3DViewer(
        key: _viewerKey,
        ligandId: widget.ligandId,
        onLigandSummary: _onLigandLoaded,
      ),
    );
  }

  /// Builds the app bar with navigation and share actions.
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.ligandId.toUpperCase()),
      centerTitle: false,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: widget.onBack,
        tooltip: 'Back',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _onSharePressed,
          tooltip: 'Share',
        ),
      ],
    );
  }
}
