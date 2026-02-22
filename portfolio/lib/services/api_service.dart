import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // CHANGE THIS to your API URL
  // For local testing: http://localhost:8000/api
  // For production: https://your-api-domain.com/api
  static const String baseUrl = 'http://localhost:8000';
  
  // Timeout duration
  static const Duration timeout = Duration(seconds: 10);
  
  // Get About Me data
  static Future<Map<String, dynamic>> getAbout() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/portfolio/about'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Portfolio in 404 mode - content hidden');
      } else {
        throw Exception('Failed to load about data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading about: $e');
    }
  }
  
  // Get Projects data
  static Future<Map<String, dynamic>> getProjects() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/portfolio/projects'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Portfolio in 404 mode - content hidden');
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading projects: $e');
    }
  }
  
  // Get Experience data
  static Future<Map<String, dynamic>> getExperience() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/portfolio/experience'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Portfolio in 404 mode - content hidden');
      } else {
        throw Exception('Failed to load experience: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading experience: $e');
    }
  }
  
  // Get Contact data
  static Future<Map<String, dynamic>> getContact() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/portfolio/contact'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Portfolio in 404 mode - content hidden');
      } else {
        throw Exception('Failed to load contact info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading contact: $e');
    }
  }
  
  // Submit contact form
  static Future<bool> submitContactForm({
    required String name,
    required String email,
    required String contact,
    required String message,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/portfolio/contact-form'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'name': name,
              'email': email,
              'contact': contact,
              'message': message,
            },
          )
          .timeout(timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error submitting form: $e');
      return false;
    }
  }
  
  // Health check
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http
          .get(Uri.parse('${baseUrl.replaceAll('/api', '')}/health'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}