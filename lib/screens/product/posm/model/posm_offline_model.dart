// lib/models/posm_offline_model.dart

// Model untuk detail satu item POSM dalam grup
class OfflinePosmItemDetail {
  final int dbId; // Primary key dari tabel posm_entries
  final String? type;
  final String? posmStatus;
  final int? quantity;
  final String? ket; // Keterangan
  final String? imagePath; // Path ke file gambar lokal

  OfflinePosmItemDetail({
    required this.dbId,
    this.type,
    this.posmStatus,
    this.quantity,
    this.ket,
    this.imagePath,
  });

  factory OfflinePosmItemDetail.fromMap(Map<String, dynamic> map) {
    return OfflinePosmItemDetail(
      dbId: map['id'] as int,
      type: map['type'] as String?,
      posmStatus: map['posm_status'] as String?,
      quantity: map['quantity'] as int?,
      ket: map['ket'] as String?,
      imagePath: map['image_path'] as String?,
    );
  }
}

// Model untuk grup entri POSM offline (satu sesi input per outlet pada waktu tertentu)
class OfflinePosmGroup {
  final String outletId;
  final String outletName;
  final String timestamp; // ISO8601 string, bisa diformat untuk tampilan
  final String userId;
  final String principleId;
  final String? visitId; // Jika visitId juga disimpan dan relevan untuk grouping/pengiriman
  final List<OfflinePosmItemDetail> items;

  OfflinePosmGroup({
    required this.outletId,
    required this.outletName,
    required this.timestamp,
    required this.userId,
    required this.principleId,
    this.visitId,
    required this.items,
  });
}
