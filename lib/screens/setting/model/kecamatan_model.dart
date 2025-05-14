class KecamatanModel {
  final String id;
  final String nama;
  final String idArea; // Relasi ke AreaModel.idArea
  final String? doc;
  final String? status;

  KecamatanModel({
    required this.id,
    required this.nama,
    required this.idArea,
    this.doc,
    this.status,
  });

  factory KecamatanModel.fromJson(Map<String, dynamic> json) {
    return KecamatanModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      idArea: json['id_area'] as String, // Perhatikan underscore di JSON
      doc: json['doc'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'id_area': idArea,
      'doc': doc,
      'status': status,
    };
  }
}