import 'dart:io';
import '../models/product_model.dart';

// Enum for product availability status
enum ProductStatus {
  neutral,   // Default state
  good,      // Good stock level
  warning,   // Low stock 
  critical,  // Very low stock or out of stock
}

// Model for product availability
class ProductAvailability {
  final Product product;
  int stockGudang;      // Warehouse stock
  int stockDisplay;     // Display stock
  int totalStock;       // Combined total
  String? beforeImagePath;
  String? afterImagePath;
  ProductStatus status;

  ProductAvailability({
    required this.product,
    this.stockGudang = 0,
    this.stockDisplay = 0,
    this.totalStock = 0,
    this.beforeImagePath,
    this.afterImagePath,
    this.status = ProductStatus.neutral,
  });

  // Create from JSON
  factory ProductAvailability.fromJson(Map<String, dynamic> json) {
    return ProductAvailability(
      product: Product.fromJson(json['product']),
      stockGudang: json['stock_gudang'] ?? 0,
      stockDisplay: json['stock_display'] ?? 0,
      totalStock: json['total_stock'] ?? 0,
      beforeImagePath: json['before_image_path'],
      afterImagePath: json['after_image_path'],
      status: _statusFromInt(json['status'] ?? 0),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'product': {
        'id': product.id,
        'code': product.code,
        'name': product.name,
        'price': product.price,
        'image': product.image,
      },
      'stock_gudang': stockGudang,
      'stock_display': stockDisplay,
      'total_stock': totalStock,
      'before_image_path': beforeImagePath,
      'after_image_path': afterImagePath,
      'status': _statusToInt(status),
    };
  }

  // Helper to convert status enum to int
  static int _statusToInt(ProductStatus status) {
    switch (status) {
      case ProductStatus.good:
        return 1;
      case ProductStatus.warning:
        return 2;
      case ProductStatus.critical:
        return 3;
      default:
        return 0;
    }
  }

  // Helper to convert int to status enum
  static ProductStatus _statusFromInt(int value) {
    switch (value) {
      case 1:
        return ProductStatus.good;
      case 2:
        return ProductStatus.warning;
      case 3:
        return ProductStatus.critical;
      default:
        return ProductStatus.neutral;
    }
  }
}

// Main class for all availability data for a store visit
class AvailabilityData {
  final String id;
  final String storeId;
  final String visitId;
  final String createdAt;
  final List<ProductAvailability> products;
  
  AvailabilityData({
    required this.id,
    required this.storeId,
    required this.visitId,
    required this.createdAt,
    required this.products,
  });
  
  // Create from JSON
  factory AvailabilityData.fromJson(Map<String, dynamic> json) {
    List<ProductAvailability> productsList = [];
    
    if (json['products'] != null) {
      for (var item in json['products']) {
        productsList.add(ProductAvailability.fromJson(item));
      }
    }
    
    return AvailabilityData(
      id: json['id'],
      storeId: json['store_id'],
      visitId: json['visit_id'],
      createdAt: json['created_at'],
      products: productsList,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> productsList = products.map((item) => item.toJson()).toList();
    
    return {
      'id': id,
      'store_id': storeId,
      'visit_id': visitId,
      'created_at': createdAt,
      'products': productsList,
    };
  }
}