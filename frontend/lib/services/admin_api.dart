import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portfolio/services/portfolio_api.dart';

class AdminSession {
  static String? token;
  static bool get active => token != null;
  static void clear() => token = null;
}

class AdminApi {
  static Map<String, String> get _headers => {'Authorization': 'Bearer ${AdminSession.token}', 'Content-Type': 'application/json'};
  static Future<void> login(String email, String password) async {
    final response = await http.post(Uri.parse('${PortfolioApi.baseUrl}/api/auth/login'), headers: const {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    if (response.statusCode != 200) throw Exception('Invalid email or password.');
    AdminSession.token = (jsonDecode(response.body) as Map<String, dynamic>)['access_token'] as String?;
  }
  static Future<dynamic> get(String path) async {
    final response = await http.get(Uri.parse('${PortfolioApi.baseUrl}$path'), headers: _headers);
    if (response.statusCode == 401 || response.statusCode == 403) { AdminSession.clear(); throw Exception('Your admin session has expired.'); }
    if (response.statusCode < 200 || response.statusCode > 299) throw Exception('Unable to load admin data.');
    return jsonDecode(response.body);
  }
  static Future<void> post(String path) async {
    final response = await http.post(Uri.parse('${PortfolioApi.baseUrl}$path'), headers: _headers);
    if (response.statusCode < 200 || response.statusCode > 299) throw Exception('Action failed.');
  }
  static Future<dynamic> send(String method, String path, {Map<String, dynamic>? body}) async {
    final request = http.Request(method, Uri.parse('${PortfolioApi.baseUrl}$path'))..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 401 || response.statusCode == 403) { AdminSession.clear(); throw Exception('Your admin session has expired.'); }
    if (response.statusCode < 200 || response.statusCode > 299) throw Exception('Action failed: ${response.body}');
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }
}
