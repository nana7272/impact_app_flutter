import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class ApiClient {
  final http.Client _client = http.Client();
  
  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  
  factory ApiClient() {
    return _instance;
  }
  
  ApiClient._internal();
  
  // Get token from shared preferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  // Create headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // GET request
  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
      headers: headers,
    );
    
    return _processResponse(response);
  }
  
  // POST request
  Future<dynamic> post(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    
    return _processResponse(response);
  }
  
  // PUT request
  Future<dynamic> put(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final response = await _client.put(
      Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    
    return _processResponse(response);
  }
  
  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await _client.delete(
      Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
      headers: headers,
    );
    
    return _processResponse(response);
  }
  
  // Upload multipart 
  Future<dynamic> uploadFile(String endpoint, File file, String fieldName, {Map<String, String>? data}) async {
    final headers = await _getHeaders();
    // Remove content-type, akan diatur secara otomatis
    headers.remove('Content-Type');
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
    );
    
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    
    if (data != null) {
      request.fields.addAll(data);
    }
    
    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);
    
    return _processResponse(response);
  }
  
  // Process response
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else {
      // Handle error
      final errorResponse = json.decode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorResponse['message'] ?? 'Unknown error',
        data: errorResponse,
      );
    }
  }
}

// Exception class for API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;
  
  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });
  
  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
}