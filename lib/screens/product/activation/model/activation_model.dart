// File BARU: /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/models/activation_model.dart
import 'dart:io';

class ActivationEntryModel {
  final int? localId; // ID dari SQLite, opsional
  final String idUser;
  final String idPinciple;
  final String idOutlet;
  final String? outletName; // Untuk tampilan di list offline
  final String tgl;
  final String program;
  final String rangePeriode;
  final String? keterangan;
  final File? imageFile; // Untuk pengiriman
  final String? imagePath; // Untuk penyimpanan lokal

  ActivationEntryModel({
    this.localId,
    required this.idUser,
    required this.idPinciple,
    required this.idOutlet,
    this.outletName,
    required this.tgl,
    required this.program,
    required this.rangePeriode,
    this.keterangan,
    this.imageFile,
    this.imagePath,
  });

  // Untuk konversi ke Map saat menyimpan ke DB lokal
  Map<String, dynamic> toMapForDb() {
    return {
      if (localId != null) 'id': localId,
      'id_user': idUser,
      'id_pinciple': idPinciple,
      'id_outlet': idOutlet,
      'outlet_name': outletName,
      'tgl': tgl,
      'program': program,
      'range_periode': rangePeriode,
      'keterangan': keterangan,
      'image_path': imagePath, // Simpan path gambar, bukan File object
      'is_synced': 0, // Default belum sinkron
    };
  }

  // Untuk konversi dari Map saat membaca dari DB lokal
  factory ActivationEntryModel.fromMapDb(Map<String, dynamic> map) {
    return ActivationEntryModel(
      localId: map['id'],
      idUser: map['id_user'],
      idPinciple: map['id_pinciple'],
      idOutlet: map['id_outlet'],
      outletName: map['outlet_name'],
      tgl: map['tgl'],
      program: map['program'],
      rangePeriode: map['range_periode'],
      keterangan: map['keterangan'],
      imagePath: map['image_path'],
      // imageFile tidak di-reconstruct dari DB, hanya path
    );
  }
}

// Model untuk pengelompokan di list offline
class OfflineActivationGroup {
  final String outletName;
  final String tgl;
  final List<ActivationEntryModel> items;

  OfflineActivationGroup({
    required this.outletName,
    required this.tgl,
    required this.items,
  });
}
