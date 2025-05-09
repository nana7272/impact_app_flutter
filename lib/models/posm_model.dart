// File: lib/models/posm_model.dart

class POSMSubmission {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String? createdAt;
  final List<POSMItemModel> items;
  
  POSMSubmission({
    this.id,
    this.storeId,
    this.visitId,
    this.createdAt,
    this.items = const [],
  });
  
  factory POSMSubmission.fromJson(Map<String, dynamic> json) {
    List<POSMItemModel> itemsList = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        itemsList.add(POSMItemModel.fromJson(item));
      }
    }
    
    return POSMSubmission(
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

class POSMItemModel {
  final String? id;
  final String type;
  final String status;
  final String installed;
  final String note;
  final String? imagePath;
  
  POSMItemModel({
    this.id,
    required this.type,
    required this.status,
    required this.installed,
    required this.note,
    this.imagePath,
  });
  
  factory POSMItemModel.fromJson(Map<String, dynamic> json) {
    return POSMItemModel(
      id: json['id'],
      type: json['posm_type'] ?? '',
      status: json['posm_status'] ?? '',
      installed: json['posm_installed'] ?? '',
      note: json['posm_note'] ?? '',
      imagePath: json['image_path'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'posm_type': type,
      'posm_status': status,
      'posm_installed': installed,
      'posm_note': note,
      if (imagePath != null) 'image_path': imagePath,
    };
  }
}