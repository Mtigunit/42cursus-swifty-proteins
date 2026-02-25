import 'package:flutter/material.dart';
import 'package:swifty_proteins/widgets/common/error_dialog.dart';
import 'package:swifty_proteins/widgets/ligands/ligand_widgets.dart';
// import 'package:swifty_proteins/services/ligand_service.dart';

class LigandListScreen extends StatefulWidget {
  final List<String> ligands;
  final Future<void> Function(String ligandId) onLigandSelected;
  final VoidCallback? onLogout;

  const LigandListScreen({
    super.key,
    required this.ligands,
    required this.onLigandSelected,
    this.onLogout,
  });

  @override
  State<LigandListScreen> createState() => _LigandListScreenState();
}

class _LigandListScreenState extends State<LigandListScreen> {
  late List<String> _filteredLigands;
  String _searchQuery = '';
  String? _loadingLigandId;

  @override
  void initState() {
    super.initState();
    _filteredLigands = widget.ligands;
  }

  void _filterLigands(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredLigands = widget.ligands;
      } else {
        _filteredLigands = widget.ligands
            .where((ligand) => ligand.toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
  }

  Future<void> _handleLigandTap(String ligandId) async {
    setState(() => _loadingLigandId = ligandId);
    try {
      await widget.onLigandSelected(ligandId);
    } catch (e) {
      _showErrorDialog(
        // TODO: improve error handling with specific messages based on error type
        'Failed to Load',
        'Could not load ligand $ligandId. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loadingLigandId = null);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ligands'),
        centerTitle: false,
        elevation: 0.5,
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          CustomSearchBar(
            onChanged: _filterLigands,
            placeholder: 'Search ligands...',
          ),

          // Results Count (only show during search)
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredLigands.length} result${_filteredLigands.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),

          // Ligands List
          Expanded(
            child: _filteredLigands.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No ligands available'
                              : 'No results found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredLigands.length,
                    itemBuilder: (context, index) {
                      final ligand = _filteredLigands[index];
                      final isLoading = _loadingLigandId == ligand;

                      return LigandListTile(
                        ligandId: ligand,
                        onTap: () => _handleLigandTap(ligand),
                        isLoading: isLoading,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
