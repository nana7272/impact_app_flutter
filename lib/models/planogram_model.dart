// File: lib/models/planogram_model.dart

class PlanogramSubmission {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String? createdAt;
  final List<PlanogramItemModel> items;
  
  PlanogramSubmission({
    this.id,
    this.storeId,
    this.visitId,
    this.createdAt,
    this.items = const [],
  });
  
  factory PlanogramSubmission.fromJson(Map<String, dynamic> json) {
    List<PlanogramItemModel> itemsList = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        itemsList.add(PlanogramItemModel.fromJson(item));
      }
    }
    
    return PlanogramSubmission(
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

class PlanogramItemModel {
  final String? id;
  final String displayType;
  final String displayIssue;
  final String descBefore;
  final String descAfter;
  final String? beforeImagePath;
  final String? afterImagePath;
  
  PlanogramItemModel({
    this.id,
    required this.displayType,
    required this.displayIssue,
    required this.descBefore,
    required this.descAfter,
    this.beforeImagePath,
    this.afterImagePath,
  });
  
  factory PlanogramItemModel.fromJson(Map<String, dynamic> json) {
    return PlanogramItemModel(
      id: json['id'],
      displayType: json['display_type'] ?? '',
      displayIssue: json['display_issue'] ?? '',
      descBefore: json['desc_before'] ?? '',
      descAfter: json['desc_after'] ?? '',
      beforeImagePath: json['before_image_path'],
      afterImagePath: json['after_image_path'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'display_type': displayType,
      'display_issue': displayIssue,
      'desc_before': descBefore,
      'desc_after': descAfter,
      if (beforeImagePath != null) 'before_image_path': beforeImagePath,
      if (afterImagePath != null) 'after_image_path': afterImagePath,
    };
  }
}