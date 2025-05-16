// File BARU: /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/models/price_monitoring_model.dart

class PriceMonitoringEntryModel {
  final int? localId; // ID dari SQLite, opsional
  final String? idPrinciple;
  final String? idOutlet;
  final String? outletName; // Untuk tampilan di list offline
  final String? idProduct;
  final String? productName; // Untuk tampilan di list offline
  final String? hargaNormal;
  final String? hargaDiskon;
  final String? hargaGabungan;
  final String? ket;
  final String? sender; // id_user
  final String? tgl;

  PriceMonitoringEntryModel({
    this.localId,
    this.idPrinciple,
    this.idOutlet,
    this.outletName,
    this.idProduct,
    this.productName,
    this.hargaNormal,
    this.hargaDiskon,
    this.hargaGabungan,
    this.ket,
    this.sender,
    this.tgl,
  });

  // Untuk konversi ke Map saat menyimpan ke DB lokal
  Map<String, dynamic> toMapForDb() {
    return {
      if (localId != null) 'id': localId,
      'id_principle': idPrinciple,
      'id_outlet': idOutlet,
      'outlet_name': outletName,
      'id_product': idProduct,
      'product_name': productName,
      'harga_normal': hargaNormal,
      'harga_diskon': hargaDiskon,
      'harga_gabungan': hargaGabungan,
      'ket': ket,
      'sender': sender,
      'tgl': tgl,
      'is_synced': 0, // Default belum sinkron
    };
  }

  // Untuk konversi dari Map saat membaca dari DB lokal
  factory PriceMonitoringEntryModel.fromMapDb(Map<String, dynamic> map) {
    return PriceMonitoringEntryModel(
      localId: map['id'],
      idPrinciple: map['id_principle'],
      idOutlet: map['id_outlet'],
      outletName: map['outlet_name'],
      idProduct: map['id_product'],
      productName: map['product_name'],
      hargaNormal: map['harga_normal'],
      hargaDiskon: map['harga_diskon'],
      hargaGabungan: map['harga_gabungan'],
      ket: map['ket'],
      sender: map['sender'],
      tgl: map['tgl'],
    );
  }

  // Untuk konversi ke Map saat mengirim ke API
  Map<String, dynamic> toJsonApi() {
     // API expects numbers for prices and sender
    return {
      "id_principle": int.tryParse(idPrinciple ?? '0') ?? 0,
      "id_outlet": int.tryParse(idOutlet ?? '0') ?? 0,
      "id_product": int.tryParse(idProduct ?? '0') ?? 0,
      "harga_normal": int.tryParse(hargaNormal ?? '0') ?? 0, // Assuming integer prices
      "harga_diskon": int.tryParse(hargaDiskon ?? '0') ?? 0, // Assuming integer prices
      "harga_gabungan": int.tryParse(hargaGabungan ?? '0') ?? 0, // Assuming integer prices
      "ket": ket ?? '',
      "sender": int.tryParse(sender ?? '0') ?? 0, // Assuming integer sender ID
      "tgl": tgl ?? '',
    };
  }
}

// Model untuk pengelompokan di list offline
class OfflinePriceMonitoringGroup {
  final String outletName;
  final String tgl;
  final List<PriceMonitoringEntryModel> items;

  OfflinePriceMonitoringGroup({
    required this.outletName,
    required this.tgl,
    required this.items,
  });
}
