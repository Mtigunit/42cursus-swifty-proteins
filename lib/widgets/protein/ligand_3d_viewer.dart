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
                (function initLigand() {
                  if (typeof setLigandData === 'function') {
                    setLigandData('$sdfUrl');
                    if (typeof setStyle === 'function') {
                      setStyle('$_currentStyle');
                    }
                    if (typeof ensureMoleculeLoaded === 'function') {
                      ensureMoleculeLoaded();
                    }
                  } else {
                    setTimeout(initLigand, 50);
                  }
                })();
              ''');

              setState(() {
                _isLoading = false;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _controller?.runJavaScript('''
                  if (window.viewer) {
                    window.viewer.resize();
                    window.viewer.render();
                  }
                  if (typeof ensureMoleculeLoaded === 'function') {
                    ensureMoleculeLoaded();
                  }
                  if (typeof requestRender === 'function') {
                    requestRender();
                  }
                ''');
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
      
      if (atomData['hideTooltip'] == true) {
        _hideAtomTooltip();
        return;
      }
      
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
    final elem = _currentAtomData!['elem'] ?? 'Unknown';
    final name = _currentAtomData!['name'] ?? elem;
    final resn = (_currentAtomData!['resn'] as String?) ?? '';
    final resi = (_currentAtomData!['resi'] as String?) ?? '';
    final x = _currentAtomData!['x'] ?? '0.00';
    final y = _currentAtomData!['y'] ?? '0.00';
    final z = _currentAtomData!['z'] ?? '0.00';
    final serial = _currentAtomData!['serial'] ?? 0;
    
    // Determine text color based on element
    final isHydrogen = elem == 'H';
    final textColor = isHydrogen ? Colors.black : Colors.white;
    final labelColor = isHydrogen 
        ? Colors.black.withOpacity(0.7) 
        : Colors.white.withOpacity(0.7);
    final secondaryTextColor = isHydrogen 
        ? Colors.black.withOpacity(0.6) 
        : Colors.white.withOpacity(0.6);

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(
                elem == 'C'
                    ? 0xFF333333
                    : (_currentAtomData!['color'] as int? ?? 0xFFFFFFFF),
              ).withOpacity(0.95),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          elem,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: elem == 'H' ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            'Serial: $serial',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordinates',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'X: $x',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Y: $y',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Z: $z',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (resn.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Residue',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: labelColor,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              resn,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (resi.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Res Index',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: labelColor,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                resi,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: textColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
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
