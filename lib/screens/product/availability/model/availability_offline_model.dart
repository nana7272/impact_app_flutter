// /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/screens/product/availability/model/availability_offline_model.dart

class OfflineAvailabilityItemDetail {
  final String idProduct;
  final String? productName;
  final int stockGudang;
  final int stockDisplay;
  final int totalStock;

  OfflineAvailabilityItemDetail({
    required this.idProduct,
    this.productName,
    required this.stockGudang,
    required this.stockDisplay,
    required this.totalStock,
  });

  factory OfflineAvailabilityItemDetail.fromMap(Map<String, dynamic> map) {
    return OfflineAvailabilityItemDetail(
      idProduct: map['id_product'] as String,
      productName: map['product_name'] as String?,
      stockGudang: map['stock_gudang'] as int,
      stockDisplay: map['stock_display'] as int,
      totalStock: map['total_stock'] as int,
    );
  }
}

class OfflineAvailabilityHeader {
  final int dbId; // header_id
  final String idUser;
  final String idOutlet;
  final String? outletName;
  final String? imageBeforePath;
  final String? imageAfterPath;
  final String tglSubmission; // YYYY-MM-DD
  final List<OfflineAvailabilityItemDetail> items;

  OfflineAvailabilityHeader({
    required this.dbId,
    required this.idUser,
    required this.idOutlet,
    this.outletName,
    this.imageBeforePath,
    this.imageAfterPath,
    required this.tglSubmission,
    required this.items,
  });

  factory OfflineAvailabilityHeader.fromMap(Map<String, dynamic> map) {
    var itemsList = map['items'] as List<dynamic>? ?? [];
    List<OfflineAvailabilityItemDetail> items = itemsList
        .map((itemMap) => OfflineAvailabilityItemDetail.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    return OfflineAvailabilityHeader(
      dbId: map['id'] as int,
      idUser: map['id_user'] as String,
      idOutlet: map['id_outlet'] as String,
      outletName: map['outlet_name'] as String?,
      imageBeforePath: map['image_before_path'] as String?,
      imageAfterPath: map['image_after_path'] as String?,
      tglSubmission: map['tgl_submission'] as String,
      items: items,
    );
  }
}
