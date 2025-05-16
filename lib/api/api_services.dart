import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:impact_app/api/api_client.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/models/product_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart';

class ApiService {
  final ApiClient _client = ApiClient();
  final Logger _logger = Logger();
  final String _tag = 'ApiService';
  
  // Auth services
  Future<User> login(String email, String password) async {
    final response = await _client.post(
      ApiConstants.login,
      {'email': email, 'password': password},
    );
    
    return User.fromJson(response['data']);
  }
  
  // Store services
  Future<List<Store>> getStores(double latitude, double longitude) async {

   //final iduser = new SessionManager().getCurrentUser()
    final user = await SessionManager().getCurrentUser();
    final idUser = user?.idLogin;
    final response = await _client.get(ApiConstants.stores+'/$latitude/$longitude/$idUser');
    _logger.d(_tag, '$user.idLogin');
    
    List<Store> stores = [];
    if (response['data'] != null) {
      for (var item in response['data']) {
        stores.add(Store.fromJson(item));
      }
    }
    
    return stores;
  }
  
  Future<dynamic> getStoreById(String storeId) async {
    try {
      _logger.d(_tag, 'Getting store details for ID: $storeId');
      final response = await _client.get('${ApiConstants.stores}/$storeId');
      return response;
    } catch (e) {
      _logger.e(_tag, 'Error getting store details: $e');
      throw e;
    }
  }
  
  Future<Store> addStore(Store store, File image) async {
    final response = await _client.uploadFile(
      ApiConstants.stores,
      image,
      'foto',
      data: _convertMapValuesToString(store.toJson() as Map<String, dynamic>),
    );
    
    return Store.fromJson(response['data']);
  }
  
  // Check-in/Visit services
  Future<dynamic> getCurrentVisit() async {
    try {
      _logger.d(_tag, 'Getting current visit');
      final user = await SessionManager().getCurrentUser();
      final response = await _client.get('${ApiConstants.currentVisit}/${user?.idLogin}');
      _logger.d(_tag, 'Current visit response: $response');
      return response;
    } catch (e) {
      _logger.e(_tag, 'Error getting current visit: $e');
      return null;
    }
  }
  
  // Check-in services
  Future<dynamic> checkin(
    String storeId, 
    double latitude, 
    double longitude, 
    List<File> images, 
    List<String> descriptions,
    String outlet,
    {String? userId}
) async {
    try {
        _logger.d(_tag, 'Check-in to store: $storeId');
        final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        
        Map<String, String> data = {
          'store_id': storeId,
          'date': currentDate,
          'time': currentTime,
          'outlet': outlet,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        };
        
        // Add userId explicitly if provided
        if (userId != null) {
          data['user_id'] = userId;
          _logger.d(_tag, 'Adding user_id: $userId to check-in request');
        } else {
          // Try to get from session as fallback
          final user = await SessionManager().getCurrentUser();
          if (user?.idLogin != null) {
            data['user_id'] = user!.idLogin!;
            _logger.d(_tag, 'Adding user_id from session: ${user.idLogin} to check-in request');
          }
        }
        
        // Add descriptions
        for (int i = 0; i < descriptions.length; i++) {
          data['description_${i+1}'] = descriptions[i];
        }
        
        // Log complete data being sent
        _logger.d(_tag, 'Check-in data: $data');
        
        // Upload first image with data
        final response = await _client.uploadFileMultiple(
          ApiConstants.checkin,
          images[0],
          'image_1',
          images[1],
          'image_2',
          data: data,
        );
        
        // Log response for debugging
        _logger.d(_tag, 'Check-in response: $response');
        
        if (response == null || response['data'] == null) {
          _logger.e(_tag, 'Invalid check-in response format');
          return null;
        }
        
        // If more than one image, upload remaining images as separate requests
        // if (images.length > 1) {
        //   for (int i = 1; i < images.length; i++) {
        //     await _client.uploadFile(
        //       '${ApiConstants.checkin}/${response['data']['id']}/images',
        //       images[i],
        //       'image_${i+1}',
        //     );
        //   }
        // }
        
        return response['data'];
    } catch (e) {
        _logger.e(_tag, 'Error during check-in: $e');
        return null;
    }
  }
  
  // Checkout service
  Future<dynamic> checkout(String visitId) async {
    return await _client.post(
      '${ApiConstants.checkout}/$visitId',
      {},
    );
  }
  
  // Product services
  Future<List<Product>> getProducts() async {
    final response = await _client.get(ApiConstants.products);
    
    List<Product> products = [];
    if (response['data'] != null) {
      for (var item in response['data']) {
        products.add(Product.fromJson(item));
      }
    }
    
    return products;
  }
  
  // Activity services
  Future<dynamic> getActivities() async {
    return await _client.get(ApiConstants.activities);
  }
  
  // Profile services
  Future<User> getProfile() async {
    final response = await _client.get(ApiConstants.profile);
    return User.fromJson(response['data']);
  }
  
  Future<User> updateProfile(User user, {File? profileImage}) async {
    if (profileImage != null) {
      final response = await _client.uploadFile(
        ApiConstants.profile,
        profileImage,
        'profile_image',
        data: _convertMapValuesToString(user.toJson()),
      );
      return User.fromJson(response['data']);
    } else {
      final response = await _client.put(
        ApiConstants.profile,
        user.toJson(),
      );
      return User.fromJson(response['data']);
    }
  }

  // Helper function to convert Map<String, dynamic> to Map<String, String>
  Map<String, String> _convertMapValuesToString(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }
}