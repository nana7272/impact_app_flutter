// lib/models/promo_audit_model.dart
class PromoAudit {
  final String? id;
  final String? storeId;
  final String? visitId;
  final bool statusPromotion;
  final bool extraDisplay;
  final bool popPromo;
  final bool hargaPromo;
  final String? keterangan;
  final String? photoUrl;
  final String? createdAt;
  final bool isSynced;

  PromoAudit({
    this.id,
    this.storeId,
    this.visitId,
    this.statusPromotion = false,
    this.extraDisplay = false,
    this.popPromo = false,
    this.hargaPromo = false,
    this.keterangan,
    this.photoUrl,
    this.createdAt,
    this.isSynced = false,
  });

  factory PromoAudit.fromJson(Map<String, dynamic> json) {
    return PromoAudit(
      id: json['id'],
      storeId: json['store_id'],
      visitId: json['visit_id'],
      statusPromotion: json['status_promotion'] == 1 || json['status_promotion'] == true,
      extraDisplay: json['extra_display'] == 1 || json['extra_display'] == true,
      popPromo: json['pop_promo'] == 1 || json['pop_promo'] == true,
      hargaPromo: json['harga_promo'] == 1 || json['harga_promo'] == true,
      keterangan: json['keterangan'],
      photoUrl: json['photo_url'],
      createdAt: json['created_at'],
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (visitId != null) 'visit_id': visitId,
      'status_promotion': statusPromotion ? 1 : 0,
      'extra_display': extraDisplay ? 1 : 0,
      'pop_promo': popPromo ? 1 : 0,
      'harga_promo': hargaPromo ? 1 : 0,
      if (keterangan != null) 'keterangan': keterangan,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  // Membuat salinan objek dengan nilai yang diperbarui
  PromoAudit copyWith({
    String? id,
    String? storeId,
    String? visitId,
    bool? statusPromotion,
    bool? extraDisplay,
    bool? popPromo,
    bool? hargaPromo,
    String? keterangan,
    String? photoUrl,
    String? createdAt,
    bool? isSynced,
  }) {
    return PromoAudit(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      visitId: visitId ?? this.visitId,
      statusPromotion: statusPromotion ?? this.statusPromotion,
      extraDisplay: extraDisplay ?? this.extraDisplay,
      popPromo: popPromo ?? this.popPromo,
      hargaPromo: hargaPromo ?? this.hargaPromo,
      keterangan: keterangan ?? this.keterangan,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}