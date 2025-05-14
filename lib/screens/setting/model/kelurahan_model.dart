class KelurahanModel {
  final String id;
  final String nama;
  final String idKecamatan; // Relasi ke KecamatanModel.id
  final String? kodepos;
  final String? doc;
  final String? status;
  final String? namaKecamatan; // Bisa disimpan untuk kemudahan atau di-join
  final String? idArea; 

  KelurahanModel({
    required this.id,
    required this.nama,
    required this.idKecamatan,
    this.kodepos,
    this.doc,
    this.status,
    this.namaKecamatan,
    this.idArea,
  });

  factory KelurahanModel.fromJson(Map<String, dynamic> json) {
    return KelurahanModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      idKecamatan: json['id_kecamatan'] as String, // Perhatikan underscore
      kodepos: json['kodepos'] as String?,
      doc: json['doc'] as String?,
      status: json['status'] as String?,
      namaKecamatan: json['nama_kecamatan'] as String?, // Perhatikan underscore
      idArea: json['id_area'] as String?, // Perhatikan underscore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'id_kecamatan': idKecamatan,
      'kodepos': kodepos,
      'doc': doc,
      'status': status,
      'nama_kecamatan': namaKecamatan,
      'id_area': idArea,
    };
  }
}