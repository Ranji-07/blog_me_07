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

  static Future<Map<String, dynamic>> fetchAbout() async {
    final response = await http.get(Uri.parse('$baseUrl/api/portfolio/about'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load profile content.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid profile response.');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> fetchJourney() async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/portfolio/journey'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load journey content.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid journey response.');
    }
    return decoded;
  }

  static Future<List<Map<String, dynamic>>> fetchProjects(
      {String? category}) async {
    final uri = Uri.parse('$baseUrl/api/portfolio/projects').replace(
      queryParameters: category == null ? null : {'category': category},
    );
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load projects.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid projects response.');
    }
    return (decoded['projects'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<void> recordVisit() async {
    await http.post(Uri.parse('$baseUrl/api/analytics/visit'));
  }

  static Future<bool> submitContactForm({
    required String name,
    required String email,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/portfolio/contact-form'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'message': message,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Unable to send your message. Please try again.';
      try {
        final decoded = jsonDecode(response.body);
        final detail =
            decoded is Map<String, dynamic> ? decoded['detail'] : null;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map<String, dynamic> && first['msg'] is String) {
            message = first['msg'] as String;
          }
        } else if (detail is String && detail.isNotEmpty) {
          message = detail;
        }
      } on FormatException {
        // Keep the safe fallback when a proxy returns a non-JSON response.
      }
      throw Exception(message);
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    return data?['visitor_copy_sent'] == true;
  }
}
