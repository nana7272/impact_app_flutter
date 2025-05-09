// File: lib/models/price_monitoring_model.dart

class PriceMonitoringSubmission {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String? createdAt;
  final List<PriceItem> items;
  
  PriceMonitoringSubmission({
    this.id,
    this.storeId,
    this.visitId,
    this.createdAt,
    this.items = const [],
  });
  
  factory PriceMonitoringSubmission.fromJson(Map<String, dynamic> json) {
    List<PriceItem> itemsList = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        itemsList.add(PriceItem.fromJson(item));
      }
    }
    
    return PriceMonitoringSubmission(
      id: json['id'],
      storeId: json['store_id'],
      visitId: json['visit_id'],
      createdAt: json['created_at'],
      items: itemsList,
    );
  }
  
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> itemsList = [];
    for (var item in items) {
      itemsList.add(item.toJson());
    }
    
    return {
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (visitId != null) 'visit_id': visitId,
      'items': itemsList,
    };
  }
}

class PriceItem {
  final String? id;
  final String productId;
  final String productName;
  final String normalPrice;
  final String? promoPrice;
  final String? notes;
  
  PriceItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.normalPrice,
    this.promoPrice,
    this.notes,
  });
  
  factory PriceItem.fromJson(Map<String, dynamic> json) {
    return PriceItem(
      id: json['id'],
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      normalPrice: json['normal_price'] ?? '',
      promoPrice: json['promo_price'],
      notes: json['notes'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'product_name': productName,
      'normal_price': normalPrice,
      if (promoPrice != null) 'promo_price': promoPrice,
      if (notes != null) 'notes': notes,
    };
  }
}