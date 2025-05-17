import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import '../utils/logger.dart';

class ApiClient {
  final http.Client _client = http.Client();
  final Logger _logger = Logger();
  final String _tag = 'ApiClient';
  
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
    
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      _logger.d(_tag, 'Adding token to request headers: Bearer $token');
    } else {
      _logger.w(_tag, 'No token available for request');
    }
    
    return headers;
  }
  
  // GET request
  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    _logger.d(_tag, 'GET Request to: ${ApiConstants.baseApiUrl}$endpoint');
    
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
        headers: headers,
      );
      
      return _processResponse(response);
    } catch (e) {
      _logger.e(_tag, 'Error on GET request: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  // POST request
  Future<dynamic> post(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    _logger.d(_tag, 'POST Request to: ${ApiConstants.baseApiUrl}$endpoint');
    _logger.d(_tag, 'POST Data: $data');
    
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      
      return _processResponse(response);
    } catch (e) {
      _logger.e(_tag, 'Error on POST request: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  // PUT request
  Future<dynamic> put(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    _logger.d(_tag, 'PUT Request to: ${ApiConstants.baseApiUrl}$endpoint');
    
    try {
      final response = await _client.put(
        Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      
      return _processResponse(response);
    } catch (e) {
      _logger.e(_tag, 'Error on PUT request: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    _logger.d(_tag, 'DELETE Request to: ${ApiConstants.baseApiUrl}$endpoint');
    
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
        headers: headers,
      );
      
      return _processResponse(response);
    } catch (e) {
      _logger.e(_tag, 'Error on DELETE request: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  // Upload multipart 
  Future<dynamic> uploadFile(String endpoint, File file, String fieldName, {Map<String, String>? data}) async {
    final headers = await _getHeaders();
    // Remove content-type, akan diatur secara otomatis
    headers.remove('Content-Type');
    
    _logger.d(_tag, 'UPLOAD Request to: ${ApiConstants.baseApiUrl}$endpoint');
    _logger.d(_tag, 'UPLOAD Field: $fieldName, Data: $data');
    
    try {
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
    } catch (e) {
      _logger.e(_tag, 'Error on UPLOAD request: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }

  Future<String> uploadFileMultiples(String endpoint, List<File?> file,  Map<String, String> data, List<Map<String, String>> data2) async {
    final headers = await _getHeaders();
    // Remove content-type, akan diatur secara otomatis
    headers.remove('Content-Type');
    
    _logger.d(_tag, 'UPLOAD Request to: ${ApiConstants.baseApiUrl}$endpoint');
    //_logger.d(_tag, 'UPLOAD Field: $fieldName, Data: $data');
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
      );
      
      request.headers.addAll(headers);
      //_logger.d(_tag, 'UPLOAD Image: ${file?.path ?? ''}');
      _logger.d(_tag, 'Files list for upload: ${file.length} item(s). Is empty: ${file.isEmpty}. List content: $file');
      for(File? f in file) {
        final filePath = f?.path ?? '';
        _logger.d(_tag, 'Looping for file. Current file object: $f. Resolved path for MultipartFile: "$filePath"');
        if (filePath.isEmpty) {
          _logger.w(_tag, 'File path is empty. MultipartFile.fromPath will likely fail or use an empty path.');
        }
        if (filePath.isEmpty) {
          request.files.add(http.MultipartFile.fromBytes('image[]', [], filename: ''));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image[]', filePath));
        }
        _logger.d(_tag, 'File with path "$filePath" added to request.files (or attempt was made).');
        // Jika Anda ingin melihat path asli dari f (sebelum null check), Anda bisa uncomment log di bawah ini
        // _logger.d(_tag, 'Original f?.path for UPLOAD Image: ${f?.path}');
      }

      request.fields.addAll(data);
    
      for(Map<String, String> d in data2) {
        request.fields.addAll(d);
      }
      
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);
      
      return response.toString();
    } catch (e) {
      _logger.e(_tag, 'Error on UPLOAD request: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }

  // Upload multipart 
  Future<dynamic> uploadFileMultiple(String endpoint, File file, String fieldName, File file2, String fieldName2, {Map<String, String>? data}) async {
    final headers = await _getHeaders();
    // Remove content-type, akan diatur secara otomatis
    headers.remove('Content-Type');
    
    _logger.d(_tag, 'UPLOAD Request to: ${ApiConstants.baseApiUrl}$endpoint');
    _logger.d(_tag, 'UPLOAD Field: $fieldName, Data: $data');
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseApiUrl}$endpoint'),
      );
      
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
      request.files.add(await http.MultipartFile.fromPath(fieldName2, file2.path));
      
      if (data != null) {
        request.fields.addAll(data);
      }
      
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);
      
      return _processResponse(response);
    } catch (e) {
      _logger.e(_tag, 'Error on UPLOAD request: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  // Process response
  dynamic _processResponse(http.Response response) {
    _logger.d(_tag, 'Response status code: ${response.statusCode}');
    _logger.d(_tag, 'Response body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return json.decode(response.body);
        } catch (e) {
          _logger.e(_tag, 'Error parsing response: $e');
          throw ApiException(
            statusCode: response.statusCode,
            message: 'Error parsing response: $e',
          );
        }
      }
      return null;
    } else {
      // Handle error
      try {
        final errorResponse = json.decode(response.body);
        _logger.e(_tag, 'API Error: ${errorResponse['message'] ?? 'Unknown error'}');
        throw ApiException(
          statusCode: response.statusCode,
          message: errorResponse['message'] ?? 'Unknown error',
          data: errorResponse,
        );
      } catch (e) {
        _logger.e(_tag, 'Error processing error response: $e');
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Server error: ${response.body}',
        );
      }
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