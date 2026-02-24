import 'package:flutter/services.dart' show rootBundle;

/// Service to load ligands from assets
class LigandService {
  static Future<List<String>> loadLigands() async {
    try {
      final String data = await rootBundle.loadString('assets/ligands.txt');
      final List<String> ligands = data
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      return ligands;
    } catch (e) {
      throw Exception('Failed to load ligands: $e');
    }
  }
}
