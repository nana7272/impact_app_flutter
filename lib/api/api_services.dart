import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:impact_app/api/api_client.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/models/product_model.dart';

class ApiService {
  final ApiClient _client = ApiClient();
  
  // Auth services
  Future<User> login(String email, String password) async {
    final response = await _client.post(
      ApiConstants.login,
      {'email': email, 'password': password},
    );
    
    return User.fromJson(response['data']);
  }
  
  // Store services
  Future<List<Store>> getStores() async {
    final response = await _client.get(ApiConstants.stores);
    
    List<Store> stores = [];
    if (response['data'] != null) {
      for (var item in response['data']) {
        stores.add(Store.fromJson(item));
      }
    }
    
    return stores;
  }
  
  Future<Store> addStore(Store store, File image) async {
    final response = await _client.uploadFile(
      ApiConstants.stores,
      image,
      'foto',
      data: store.toJson(),
    );
    
    return Store.fromJson(response['data']);
  }
  
  // Check-in services
  Future<dynamic> checkin(String storeId, double latitude, double longitude, List<File> images, List<String> descriptions) async {
    Map<String, String> data = {
      'store_id': storeId,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    
    // Add descriptions
    for (int i = 0; i < descriptions.length; i++) {
      data['description_${i+1}'] = descriptions[i];
    }
    
    // Upload first image with data
    final response = await _client.uploadFile(
      ApiConstants.checkin,
      images[0],
      'image_1',
      data: data,
    );
    
    // If more than one image, upload remaining images as separate requests
    if (images.length > 1) {
      for (int i = 1; i < images.length; i++) {
        await _client.uploadFile(
          '${ApiConstants.checkin}/${response['data']['id']}/images',
          images[i],
          'image_${i+1}',
        );
      }
    }
    
    return response['data'];
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
        data: user.toJson(),
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
}