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
  
  // Atom click handling
  Map<String, dynamic>? _currentAtomData;
  bool _isTooltipVisible = false;

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
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            _handleAtomClick(message.message);
          },
        )
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

  void _handleAtomClick(String jsonData) {
    try {
      final atomData = jsonDecode(jsonData) as Map<String, dynamic>;
      _showAtomTooltip(atomData);
    } catch (e) {
      print('Error parsing atom data: $e');
    }
  }

  void _showAtomTooltip(Map<String, dynamic> atomData) {
    setState(() {
      _currentAtomData = atomData;
      _isTooltipVisible = true;
    });
  }

  void _hideAtomTooltip() {
    if (mounted) {
      setState(() {
        _currentAtomData = null;
        _isTooltipVisible = false;
      });
    }
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
      return _buildErrorState(context);
    }

    return Stack(
      children: [
        _buildViewerLayer(context),
        if (!_isLoading) _buildControlButtons(context),
        if (_isTooltipVisible && _currentAtomData != null)
          _buildAtomTooltip(context),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
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

  Widget _buildViewerLayer(BuildContext context) {
    return GestureDetector(
      onTap: _isTooltipVisible ? _hideAtomTooltip : null,
      child: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: MediaQuery.of(context).platformBrightness == Brightness.dark
                  ? const Color(0xFF0D1B2A)
                  : const Color(0xFFF5F5F5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'style_button',
            mini: true,
            onPressed: () => _showStylePicker(context),
            tooltip: 'Change Style',
            child: const Icon(Icons.palette),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'reset_button',
            mini: true,
            onPressed: _resetView,
            tooltip: 'Reset View',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildAtomTooltip(BuildContext context) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(
                _currentAtomData!['elem'] == 'C'
                    ? 0xFF333333
                    : (_currentAtomData!['color'] as int? ?? 0xFFFFFFFF),
              ).withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              _currentAtomData!['elem'] ?? 'Unknown',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _currentAtomData!['elem'] == 'H'
                    ? const Color(0xFF333333)
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
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
