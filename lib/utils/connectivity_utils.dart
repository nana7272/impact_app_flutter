import 'package:http/http.dart' as http;
import 'dart:async';
import 'logger.dart';

class ConnectivityUtils {
  static final Logger _logger = Logger();
  static const String _tag = 'ConnectivityUtils';
  
  // Check internet connection
  static Future<bool> checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      _logger.e(_tag, 'Error checking internet connection: $e');
      return false;
    }
  }
  
  // Check if server is reachable
  static Future<bool> checkServerConnection(String url) async {
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      _logger.e(_tag, 'Error checking server connection: $e');
      return false;
    }
  }
}