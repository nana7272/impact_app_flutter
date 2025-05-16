// lib/models/oos_item_model.dart

class OOSItem {
  final int? localId; // ID untuk database lokal, nullable karena belum ada saat dibuat objek baru
  final int idPrinciple;
  final String? outletName;
  final int idOutlet;
  final int idProduct;
  final String productName; // Untuk tampilan di list offline
  final int quantity;
  final String ket;
  final String type; // e.g., "REGULAR"
  final int sender; // id_user
  final String tgl; // YYYY-MM-DD
  final bool isEmpty; // Status dari UI (Kosong/Tersedia)
  int isSynced; // 0 = false, 1 = true (untuk database lokal)

  OOSItem({
    this.localId,
    required this.idPrinciple,
    required this.idOutlet,
    required this.outletName,
    required this.idProduct,
    required this.productName,
    required this.quantity,
    required this.ket,
    required this.type,
    required this.sender,
    required this.tgl,
    required this.isEmpty,
    this.isSynced = 0,
  });

  // Untuk kirim ke API
  Map<String, dynamic> toJsonAPI() {
    return {
      'id_principle': idPrinciple,
      'id_outlet': idOutlet,
      'id_product': idProduct,
      'quantity': isEmpty ? 0 : quantity, // Jika kosong, quantity = 0
      'ket': ket,
      'type': type,
      'sender': sender,
      'tgl': tgl,
    };
  }

  // Untuk simpan/ambil dari database lokal
  Map<String, dynamic> toMapLocal() {
    return {
      'local_id': localId, // sqflite akan handle auto-increment jika null
      'id_principle': idPrinciple,
      'id_outlet': idOutlet,
      'id_product': idProduct,
      'product_name': productName,
      'quantity': quantity,
      'ket': ket,
      'type': type,
      'sender': sender,
      'tgl': tgl,
      'is_empty': isEmpty ? 1 : 0,
      'is_synced': isSynced,
      'outlet_name': outletName,
    };
  }

  factory OOSItem.fromMapLocal(Map<String, dynamic> map) {
    return OOSItem(
      localId: map['local_id'] as int?,
      idPrinciple: map['id_principle'] as int,
      idOutlet: map['id_outlet'] as int,
      idProduct: map['id_product'] as int,
      productName: map['product_name'] as String,
      quantity: map['quantity'] as int,
      ket: map['ket'] as String,
      type: map['type'] as String,
      sender: map['sender'] as int,
      tgl: map['tgl'] as String,
      isEmpty: (map['is_empty'] as int) == 1,
      isSynced: map['is_synced'] as int? ?? 0,
      outletName: map['outlet_name'] as String?,
    );
  }
}