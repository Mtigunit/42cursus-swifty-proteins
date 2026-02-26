import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:swifty_proteins/models/molecule.dart';
import 'package:vector_math/vector_math.dart';

/// Service to load ligands from assets
class LigandService {
  static const String baseUrl = 'https://files.rcsb.org/ligands/view';

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

  /// Fetch SDF file for a given ligand with detailed error handling
  static Future<String> fetchSdf(String ligandId) async {
    final url = Uri.parse('$baseUrl/${ligandId.toUpperCase()}_ideal.sdf');

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Request timeout. Please try again.',
        ),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw LigandNotFoundException(
          'Ligand not found (404). This ligand may not exist in the database.',
        );
      } else {
        throw Exception(
          'Failed to load ligand (HTTP ${response.statusCode}). Please try again.',
        );
      }
    } on SocketException catch (_) {
      throw NetworkException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException catch (e) {
      throw e;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch and parse SDF file to Molecule object
  static Future<Molecule> fetchMolecule(String ligandId) async {
    try {
      final sdfData = await fetchSdf(ligandId);
      return parseSdf(sdfData, ligandId);
    } on ParseException catch (e) {
      throw e;
    } catch (e) {
      rethrow;
    }
  }

  /// Parse SDF (MDL Molfile) format to extract atoms and bonds
  static Molecule parseSdf(String sdfData, [String? ligandId]) {
    try {
      final lines = sdfData.split('\n');
      
      if (lines.length < 4) {
        throw ParseException(
          'Failed to parse ligand data. The file may be corrupted.',
        );
      }

      // Line 4 (index 3) contains atom and bond counts
      // Format: aaabbblllfffcccsssxxxrrrpppiiimmmvvvvvv
      // aaa = number of atoms, bbb = number of bonds
      final countsLine = lines[3].trim();
      
      // Extract atom and bond counts (first 6 characters: 3 for atoms, 3 for bonds)
      if (countsLine.length < 6) {
        throw ParseException(
          'Failed to parse ligand data. The file may be corrupted.',
        );
      }
      
      final atomCount = int.parse(countsLine.substring(0, 3).trim());
      final bondCount = int.parse(countsLine.substring(3, 6).trim());

    // Parse atoms (starting from line 5, index 4)
    final List<Atom> atoms = [];
    for (int i = 0; i < atomCount; i++) {
      final lineIndex = 4 + i;
      if (lineIndex >= lines.length) break;
      
      final atomLine = lines[lineIndex].trim();
      final parts = atomLine.split(RegExp(r'\s+'));
      
      if (parts.length >= 4) {
        final x = double.tryParse(parts[0]) ?? 0.0;
        final y = double.tryParse(parts[1]) ?? 0.0;
        final z = double.tryParse(parts[2]) ?? 0.0;
        final element = parts[3];
        
        atoms.add(Atom(
          element: element,
          position: Vector3(x, y, z),
        ));
      }
    }

    // Parse bonds (starting after atom lines)
    final List<Bond> bonds = [];
    final bondStartLine = 4 + atomCount;
    
    for (int i = 0; i < bondCount; i++) {
      final lineIndex = bondStartLine + i;
      if (lineIndex >= lines.length) break;
      
      final bondLine = lines[lineIndex].trim();
      final parts = bondLine.split(RegExp(r'\s+'));
      
      if (parts.length >= 2) {
        final atom1 = int.tryParse(parts[0]) ?? 0;
        final atom2 = int.tryParse(parts[1]) ?? 0;
        
        // SDF uses 1-based indexing, convert to 0-based
        if (atom1 > 0 && atom2 > 0) {
          bonds.add(Bond(
            atomIndex1: atom1 - 1,
            atomIndex2: atom2 - 1,
          ));
        }
      }
    }

      return Molecule(atoms: atoms, bonds: bonds);
    } catch (e) {
      if (e is ParseException) rethrow;
      throw ParseException(
        'Failed to parse ligand data. The file may be corrupted.',
      );
    }
  }
}

/// Custom exception classes for specific error types
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class LigandNotFoundException implements Exception {
  final String message;
  LigandNotFoundException(this.message);

  @override
  String toString() => message;
}

class ParseException implements Exception {
  final String message;
  ParseException(this.message);

  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
