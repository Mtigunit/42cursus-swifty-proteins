import 'package:flutter/services.dart' show rootBundle;

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
