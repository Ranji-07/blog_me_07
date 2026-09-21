import 'dart:convert';

import 'package:flutter/services.dart';

/// Reads the public portfolio from the bundled config file.
///
/// This keeps the public site independent of the FastAPI service, so the same
/// build can be deployed to GitHub Pages or any other static web host.
class PortfolioApi {
  PortfolioApi._();

  /// Used only by the separate local admin tools. The public site reads the
  /// bundled config and makes no API request.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String configAsset = 'config/portfolio.json';
  static Map<String, dynamic>? _content;

  static Future<Map<String, dynamic>> fetchAll() async {
    final cached = _content;
    if (cached != null) return cached;

    final decoded = jsonDecode(await rootBundle.loadString(configAsset));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Portfolio config must contain an object.');
    }
    _content = decoded;
    return decoded;
  }

  static Future<Map<String, dynamic>> fetchAbout() async {
    final section = (await fetchAll())['about'];
    if (section is! Map<String, dynamic>) {
      throw const FormatException('Portfolio config is missing about content.');
    }
    return section;
  }

  static Future<Map<String, dynamic>> fetchJourney() async {
    final section = (await fetchAll())['journey'];
    if (section is! Map<String, dynamic>) {
      throw const FormatException(
          'Portfolio config is missing journey content.');
    }
    return section;
  }

  static Future<List<Map<String, dynamic>>> fetchProjects(
      {String? category}) async {
    final projectsSection = (await fetchAll())['projects'];
    if (projectsSection is! Map<String, dynamic>) {
      throw const FormatException('Portfolio config is missing projects.');
    }
    final projects = (projectsSection['projects'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    if (category == null || category.trim().isEmpty) return projects.toList();
    return projects
        .where((project) =>
            (project['category'] as String? ?? '').toLowerCase() ==
            category.toLowerCase())
        .toList();
  }

  /// Kept for the existing landing interaction. Static hosting has no API to
  /// record visits.
  static Future<void> recordVisit() async {}
}
