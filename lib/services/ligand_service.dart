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

  static Future<bool> verifyLigandExists(String ligandId) async {
    final id = ligandId.trim().toUpperCase();
    final uri = Uri.parse('$baseUrl/${id}_ideal.sdf');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      switch (response.statusCode) {
        case 200:
          return true;

        case 404:
          throw LigandNotFoundException('Ligand not found in the database.');

        default:
          throw NetworkException(
            'Failed to validate ligand (HTTP ${response.statusCode}).',
          );
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out while checking ligand "$id".');
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Network error while checking ligand "$id": ${e.message}',
      );
    } catch (e) {
      throw NetworkException('Error checking "$id": $e');
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
