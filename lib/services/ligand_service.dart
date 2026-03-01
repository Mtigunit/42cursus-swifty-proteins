import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

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

  /// Verify if a ligand file exists by checking the RCSB API
  static Future<bool> verifyLigandExists(String ligandId) async {
    try {
      final String sdfUrl = '$baseUrl/${ligandId.toUpperCase()}_ideal.sdf';
      final response = await http.get(Uri.parse(sdfUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out while checking ligand');
        },
      );

      if (response.statusCode == 404) {
        throw LigandNotFoundException(
          'Ligand "${ligandId.toUpperCase()}" not found in the database.',
        );
      }

      if (response.statusCode != 200) {
        throw NetworkException(
          'Failed to validate ligand (Error: ${response.statusCode})',
        );
      }

      return true;
    } on LigandNotFoundException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to check ligand: $e');
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
