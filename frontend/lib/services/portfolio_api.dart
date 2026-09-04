import 'dart:convert';

import 'package:http/http.dart' as http;

class PortfolioApi {
  PortfolioApi._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static Future<Map<String, dynamic>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/api/portfolio/all'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load portfolio content.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid portfolio response.');
    }
    return decoded;
  }

  static Future<void> recordVisit() async {
    await http.post(Uri.parse('$baseUrl/api/analytics/visit'));
  }
}
