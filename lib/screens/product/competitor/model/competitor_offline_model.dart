// lib/screens/product/competitor/model/competitor_offline_model.dart

class OfflinePromoActivityItemDetail {
  final int dbId; // Primary key dari tabel promo_activity_entries
  final String? idProduct;
  final String? namaProduk;
  final String? categoryProduct; // 'own' or 'comp'
  final String? hargaRbp;
  final String? hargaCbp;
  final String? hargaOutlet;
  final String? promoType;
  final String? mekanismePromo;
  final String? periode;
  final String? imagePath;

  OfflinePromoActivityItemDetail({
    required this.dbId,
    this.idProduct,
    this.namaProduk,
    this.categoryProduct,
    this.hargaRbp,
    this.hargaCbp,
    this.hargaOutlet,
    this.promoType,
    this.mekanismePromo,
    this.periode,
    this.imagePath,
  });

  factory OfflinePromoActivityItemDetail.fromMap(Map<String, dynamic> map) {
    return OfflinePromoActivityItemDetail(
      dbId: map['id'] as int,
      idProduct: map['id_product'] as String?,
      namaProduk: map['nama_produk'] as String?,
      categoryProduct: map['category_product'] as String?,
      hargaRbp: map['harga_rbp'] as String?,
      hargaCbp: map['harga_cbp'] as String?,
      hargaOutlet: map['harga_outlet'] as String?,
      promoType: map['promo_type'] as String?,
      mekanismePromo: map['mekanisme_promo'] as String?,
      periode: map['periode'] as String?,
      imagePath: map['image_path'] as String?,
    );
  }
}

class OfflinePromoActivityGroup {
  final String submissionGroupId;
  final String outletId;
  final String outletName;
  final String tglSubmission; // YYYY-MM-DD
  final String userId;
  final String principleId;
  final List<OfflinePromoActivityItemDetail> items;

  OfflinePromoActivityGroup({
    required this.submissionGroupId,
    required this.outletId,
    required this.outletName,
    required this.tglSubmission,
    required this.userId,
    required this.principleId,
    required this.items,
  });
}
