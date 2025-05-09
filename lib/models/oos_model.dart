// File: lib/models/oos_model.dart

class OOSSubmission {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String? createdAt;
  final List<OOSItemModel> items;
  
  OOSSubmission({
    this.id,
    this.storeId,
    this.visitId,
    this.createdAt,
    this.items = const [],
  });
  
  factory OOSSubmission.fromJson(Map<String, dynamic> json) {
    List<OOSItemModel> itemsList = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        itemsList.add(OOSItemModel.fromJson(item));
      }
    }
    
    return OOSSubmission(
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

class OOSItemModel {
  final String? id;
  final String? productId;
  final String? productName;
  final String? productCode;
  final String quantity;
  final String note;
  final bool isEmpty;
  
  OOSItemModel({
    this.id,
    this.productId,
    this.productName,
    this.productCode,
    required this.quantity,
    required this.note,
    this.isEmpty = true,
  });
  
  factory OOSItemModel.fromJson(Map<String, dynamic> json) {
    return OOSItemModel(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productCode: json['product_code'],
      quantity: json['quantity'] ?? '',
      note: json['note'] ?? '',
      isEmpty: json['is_empty'] == 1 || json['is_empty'] == true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (productCode != null) 'product_code': productCode,
      'quantity': quantity,
      'note': note,
      'is_empty': isEmpty ? 1 : 0,
    };
  }
}