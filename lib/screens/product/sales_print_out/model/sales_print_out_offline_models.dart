// lib/models/sales_print_out_offline_models.dart

// Model untuk detail produk dalam satu grup penjualan offline
class OfflineSalesProductDetail {
  final int dbId; // Primary key dari tabel sales_print_outs
  final String productId;
  final String productName; // Nama produk, akan disimpan di tabel sales_print_outs
  final String qty;
  final String total;
  final String periode;
  final String imagePath; // Path ke file gambar lokal

  OfflineSalesProductDetail({
    required this.dbId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.total,
    required this.periode,
    required this.imagePath,
  });

  // Factory constructor untuk membuat instance dari map (baris database)
  factory OfflineSalesProductDetail.fromMap(Map<String, dynamic> map) {
    return OfflineSalesProductDetail(
      dbId: map['id'] as int,
      productId: map['id_product'] as String,
      // Pastikan kolom 'product_name' ada di tabel sales_print_outs
      productName: map['product_name'] as String? ?? 'Nama Produk Tidak Tersedia',
      qty: map['qty'] as String,
      total: map['total'] as String,
      imagePath: map['image'] as String,
      periode: map['periode'] as String,
    );
  }
}

// Model untuk grup penjualan offline (per outlet dan periode)
class OfflineSalesGroup {
  final String outletName;    // dari kolom 'outlet'
  final String outletId;     // dari kolom 'periode'
  final String principleId;   // dari kolom 'id_principle'
  final String userId;        // dari kolom 'id_user'
  final String tgl;        // dari kolom 'tgl', jika diperlukan
  final List<OfflineSalesProductDetail> products; // Daftar produk dalam grup ini

  OfflineSalesGroup({
    required this.outletName,
    required this.outletId,
    required this.principleId,
    required this.userId,
    required this.tgl,
    required this.products,
  });
}
