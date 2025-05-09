// File: lib/models/competitor_model.dart

class CompetitorSubmission {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String? createdAt;
  final List<CompetitorItemModel> items;
  
  CompetitorSubmission({
    this.id,
    this.storeId,
    this.visitId,
    this.createdAt,
    this.items = const [],
  });
  
  factory CompetitorSubmission.fromJson(Map<String, dynamic> json) {
    List<CompetitorItemModel> itemsList = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        itemsList.add(CompetitorItemModel.fromJson(item));
      }
    }
    
    return CompetitorSubmission(
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

class CompetitorItemModel {
  final String? id;
  final String? productId;
  
  // Own product data
  final String ownProductName;
  final String ownRbp;
  final String ownCbp;
  final String ownOutlet;
  final String ownPromoType;
  final String ownPromoMechanism;
  final String ownPeriode;
  final String? ownImageUrl;
  
  // Competitor product data
  final String competitorProductName;
  final String competitorNormal;
  final String competitorCbp;
  final String competitorOutlet;
  final String competitorPromoType;
  final String competitorPromoMechanism;
  final String competitorPeriode;
  final String? competitorImageUrl;
  
  CompetitorItemModel({
    this.id,
    this.productId,
    required this.ownProductName,
    required this.ownRbp,
    required this.ownCbp,
    required this.ownOutlet,
    required this.ownPromoType,
    required this.ownPromoMechanism,
    required this.ownPeriode,
    this.ownImageUrl,
    required this.competitorProductName,
    required this.competitorNormal,
    required this.competitorCbp,
    required this.competitorOutlet,
    required this.competitorPromoType,
    required this.competitorPromoMechanism,
    required this.competitorPeriode,
    this.competitorImageUrl,
  });
  
  factory CompetitorItemModel.fromJson(Map<String, dynamic> json) {
    return CompetitorItemModel(
      id: json['id'],
      productId: json['product_id'],
      
      // Own product data
      ownProductName: json['own_product_name'] ?? '',
      ownRbp: json['own_rbp'] ?? '',
      ownCbp: json['own_cbp'] ?? '',
      ownOutlet: json['own_outlet'] ?? '',
      ownPromoType: json['own_promo_type'] ?? '',
      ownPromoMechanism: json['own_promo_mechanism'] ?? '',
      ownPeriode: json['own_periode'] ?? '',
      ownImageUrl: json['own_image_url'],
      
      // Competitor product data
      competitorProductName: json['competitor_product_name'] ?? '',
      competitorNormal: json['competitor_normal'] ?? '',
      competitorCbp: json['competitor_cbp'] ?? '',
      competitorOutlet: json['competitor_outlet'] ?? '',
      competitorPromoType: json['competitor_promo_type'] ?? '',
      competitorPromoMechanism: json['competitor_promo_mechanism'] ?? '',
      competitorPeriode: json['competitor_periode'] ?? '',
      competitorImageUrl: json['competitor_image_url'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      
      // Own product data
      'own_product_name': ownProductName,
      'own_rbp': ownRbp,
      'own_cbp': ownCbp,
      'own_outlet': ownOutlet,
      'own_promo_type': ownPromoType,
      'own_promo_mechanism': ownPromoMechanism,
      'own_periode': ownPeriode,
      if (ownImageUrl != null) 'own_image_url': ownImageUrl,
      
      // Competitor product data
      'competitor_product_name': competitorProductName,
      'competitor_normal': competitorNormal,
      'competitor_cbp': competitorCbp,
      'competitor_outlet': competitorOutlet,
      'competitor_promo_type': competitorPromoType,
      'competitor_promo_mechanism': competitorPromoMechanism,
      'competitor_periode': competitorPeriode,
      if (competitorImageUrl != null) 'competitor_image_url': competitorImageUrl,
    };
  }
}