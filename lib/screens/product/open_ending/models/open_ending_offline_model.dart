// lib/models/open_ending_offline_model.dart

// Model untuk detail produk dalam satu grup Open Ending offline
class OfflineOpenEndingProduct {
  final int dbId; // Primary key dari tabel open_ending_data
  final String productId;
  final String productName;
  final int sf; // Open
  final int si; // In
  final int sa; // Ending
  final int so; // Sell Out
  final String? ket; // Keterangan
  final String? selving;
  final String? expiredDate; // YYYY-MM-DD
  final String? listing;
  final int? returnQty;
  final String? returnReason;
  // Tambahkan field lain jika perlu ditampilkan di list per produk

  OfflineOpenEndingProduct({
    required this.dbId,
    required this.productId,
    required this.productName,
    required this.sf,
    required this.si,
    required this.sa,
    required this.so,
    this.ket,
    this.selving,
    this.expiredDate,
    this.listing,
    this.returnQty,
    this.returnReason,
  });

  factory OfflineOpenEndingProduct.fromMap(Map<String, dynamic> map) {
    return OfflineOpenEndingProduct(
      dbId: map['id'] as int,
      productId: map['id_product'] as String? ?? '',
      productName: map['product_name'] as String? ?? 'N/A',
      sf: map['sf'] as int? ?? 0,
      si: map['si'] as int? ?? 0,
      sa: map['sa'] as int? ?? 0,
      so: map['so'] as int? ?? 0,
      ket: map['ket'] as String?,
      selving: map['selving'] as String?,
      expiredDate: map['expired'] as String?, // Sesuai nama kolom di DB ('expired')
      listing: map['listing'] as String?,
      returnQty: map['return'] as int?, // Sesuai nama kolom di DB ('return')
      returnReason: map['return_reason'] as String?,
    );
  }
}

// Model untuk grup Open Ending offline (per outlet dan tanggal)
class OfflineOpenEndingGroup {
  final String outletId;
  final String outletName;
  final String tgl; // Tanggal (YYYY-MM-DD)
  final String principleId;
  final String userId; // sender
  final List<OfflineOpenEndingProduct> products;

  OfflineOpenEndingGroup({
    required this.outletId,
    required this.outletName,
    required this.tgl,
    required this.principleId,
    required this.userId,
    required this.products,
  });
}
