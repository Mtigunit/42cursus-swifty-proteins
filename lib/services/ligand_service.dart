import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

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

  /// fetch cif file for a given ligand
  static Future<String> fetchCif(String ligand) async {
    final url = Uri.parse("https://files.rcsb.org/ligands/view/$ligand.cif");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("Failed to load CIF");
    }
  }
}
