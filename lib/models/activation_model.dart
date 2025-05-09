// File: lib/models/activation_model.dart

class ActivationSubmission {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String? createdAt;
  final List<ActivationItem> items;
  
  ActivationSubmission({
    this.id,
    this.storeId,
    this.visitId,
    this.createdAt,
    this.items = const [],
  });
  
  factory ActivationSubmission.fromJson(Map<String, dynamic> json) {
    List<ActivationItem> itemsList = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        itemsList.add(ActivationItem.fromJson(item));
      }
    }
    
    return ActivationSubmission(
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

class ActivationItem {
  final String? id;
  final String program;
  final String periode;
  final String keterangan;
  final String? imagePath;
  
  ActivationItem({
    this.id,
    required this.program,
    required this.periode,
    required this.keterangan,
    this.imagePath,
  });
  
  factory ActivationItem.fromJson(Map<String, dynamic> json) {
    return ActivationItem(
      id: json['id'],
      program: json['program'] ?? '',
      periode: json['periode'] ?? '',
      keterangan: json['keterangan'] ?? '',
      imagePath: json['image_path'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'program': program,
      'periode': periode,
      'keterangan': keterangan,
      if (imagePath != null) 'image_path': imagePath,
    };
  }
}