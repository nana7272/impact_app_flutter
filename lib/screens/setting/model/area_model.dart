class AreaModel {
  final String idArea;
  final String kodeArea;
  final String nama;
  final String? lat;
  final String? lolat; // lolat sepertinya typo, mungkin maksudnya lng atau lon
  final String? ket;
  final String? idPropinsi;
  final String? doc; // Sebaiknya di-parse menjadi DateTime jika akan digunakan
  final String? status;

  AreaModel({
    required this.idArea,
    required this.kodeArea,
    required this.nama,
    this.lat,
    this.lolat,
    this.ket,
    this.idPropinsi,
    this.doc,
    this.status,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      idArea: json['idArea'] as String,
      kodeArea: json['kodeArea'] as String,
      nama: json['nama'] as String,
      lat: json['lat'] as String?,
      lolat: json['lolat'] as String?,
      ket: json['ket'] as String?,
      idPropinsi: json['idPropinsi'] as String?,
      doc: json['doc'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idArea': idArea,
      'kodeArea': kodeArea,
      'nama': nama,
      'lat': lat,
      'lolat': lolat,
      'ket': ket,
      'idPropinsi': idPropinsi,
      'doc': doc,
      'status': status,
    };
  }
}