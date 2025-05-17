// /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/screens/product/sampling_konsument/model/sampling_konsumen_offline_model.dart

class OfflineSamplingKonsumenItem {
  final int dbId;
  final String idUser;
  final String idOutlet;
  final String? outletName;
  final String namaKonsumen;
  final String alamatKonsumen;
  final String noHpKonsumen;
  final int umurKonsumen;
  final String? emailKonsumen;
  final String idProductDibeli;
  final String? namaProductDibeli;
  final String? idProductSebelumnya;
  final String? namaProductSebelumnya;
  final int kuantitas;
  final String? keterangan;
  final String tglSubmission; // YYYY-MM-DD

  OfflineSamplingKonsumenItem({
    required this.dbId,
    required this.idUser,
    required this.idOutlet,
    this.outletName,
    required this.namaKonsumen,
    required this.alamatKonsumen,
    required this.noHpKonsumen,
    required this.umurKonsumen,
    this.emailKonsumen,
    required this.idProductDibeli,
    this.namaProductDibeli,
    this.idProductSebelumnya,
    this.namaProductSebelumnya,
    required this.kuantitas,
    this.keterangan,
    required this.tglSubmission,
  });

  factory OfflineSamplingKonsumenItem.fromMap(Map<String, dynamic> map) {
    return OfflineSamplingKonsumenItem(
      dbId: map['id'] as int,
      idUser: map['id_user'] as String,
      idOutlet: map['id_outlet'] as String,
      outletName: map['outlet_name'] as String?,
      namaKonsumen: map['nama_konsumen'] as String,
      alamatKonsumen: map['alamat_konsumen'] as String,
      noHpKonsumen: map['no_hp_konsumen'] as String,
      umurKonsumen: map['umur_konsumen'] as int,
      emailKonsumen: map['email_konsumen'] as String?,
      idProductDibeli: map['id_product_dibeli'] as String,
      namaProductDibeli: map['nama_product_dibeli'] as String?,
      idProductSebelumnya: map['id_product_sebelumnya'] as String?,
      namaProductSebelumnya: map['nama_product_sebelumnya'] as String?,
      kuantitas: map['kuantitas'] as int,
      keterangan: map['keterangan'] as String?,
      tglSubmission: map['tgl_submission'] as String,
    );
  }
}

// Untuk tampilan di list offline, kita bisa langsung menggunakan List<OfflineSamplingKonsumenItem>
// atau membuat model grup jika ada pengelompokan per outlet atau tanggal yang kompleks.
// Untuk saat ini, List<OfflineSamplingKonsumenItem> sudah cukup.
