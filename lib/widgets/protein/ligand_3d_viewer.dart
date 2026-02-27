import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 3D Ligand Viewer Widget using WebView and 3Dmol.js
class Ligand3DViewer extends StatefulWidget {
  final String ligandId;
  final String baseUrl;

  const Ligand3DViewer({
    super.key,
    required this.ligandId,
    this.baseUrl = 'https://files.rcsb.org/ligands/view',
  });

  @override
  State<Ligand3DViewer> createState() => _Ligand3DViewerState();
}

class _Ligand3DViewerState extends State<Ligand3DViewer> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String _currentStyle = 'ballStick';

  final Map<String, String> _styles = {
    'ballStick': 'Ball & Stick',
    'stick': 'Stick',
    'sphere': 'Space-Filling',
    'line': 'Wireframe',
  };

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Load the HTML file from assets
      final String htmlContent = await rootBundle.loadString(
        'assets/html/ligand_viewer.html',
      );

      // Build the SDF URL for the ligand
      final String ligandId = widget.ligandId.toUpperCase();
      final sdfUrl = '${widget.baseUrl}/${ligandId}_ideal.sdf';

      // Get the background color based on theme brightness
      final brightness = MediaQuery.of(context).platformBrightness;
      final backgroundColor = brightness == Brightness.dark
          ? const Color(0xFF0D1B2A)
          : const Color(0xFFF5F5F5);
      final colorHex =
          '#${backgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

      // Create the WebView controller
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        // ..setBackgroundColor(backgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              // Set the background color in the WebView
              _controller?.runJavaScript('''
                if (typeof setBackgroundColor === 'function') {
                  setBackgroundColor('$colorHex');
                }
                window.ligandData = '$sdfUrl';
                if (typeof loadMolecule === 'function') {
                  loadMolecule('$sdfUrl');
                }
              ''');

              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to load viewer: ${error.description}';
              });
            },
          ),
        );

      // Load the HTML content
      await _controller!.loadRequest(
        Uri.dataFromString(
          htmlContent,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8'),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing viewer: $e';
      });
    }
  }

  void _changeStyle(String style) {
    _controller?.runJavaScript('''
      if (typeof setStyle === 'function') {
        setStyle('$style');
      }
    ''');
    setState(() {
      _currentStyle = style;
    });
  }

  void _resetView() {
    _controller?.runJavaScript('''
      if (window.viewer) {
        window.viewer.zoomTo();
        window.viewer.zoom(1.2);
        window.viewer.render();
      }
    ''');
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error Loading Molecule',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _initializeWebView();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_controller != null)
          ExcludeSemantics(
            excluding: _isLoading,
            child: Semantics(
              label: '3D molecule viewer for ${widget.ligandId.toUpperCase()}',
              child: WebViewWidget(controller: _controller!),
            ),
          ),

        // Loading indicator
        if (_isLoading)
          Semantics(
            label: 'Loading 3D viewer',
            liveRegion: true,
            child: Container(
              color:
                  MediaQuery.of(context).platformBrightness == Brightness.dark
                  ? const Color(0xFF0D1B2A)
                  : const Color(0xFFF5F5F5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),

        // Control buttons
        if (!_isLoading)
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Style selector
                FloatingActionButton(
                  heroTag: 'style_button',
                  mini: true,
                  onPressed: () => _showStylePicker(context),
                  tooltip: 'Change Style',
                  child: const Icon(Icons.palette),
                ),
                const SizedBox(height: 8),
                // Reset view button
                FloatingActionButton(
                  heroTag: 'reset_button',
                  mini: true,
                  onPressed: _resetView,
                  tooltip: 'Reset View',
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showStylePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Visualization Style',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            ..._styles.entries.map((entry) {
              final isSelected = entry.key == _currentStyle;
              return ListTile(
                leading: Icon(
                  Icons.check,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                title: Text(entry.value),
                selected: isSelected,
                onTap: () {
                  _changeStyle(entry.key);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
