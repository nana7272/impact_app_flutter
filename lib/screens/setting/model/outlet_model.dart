class OutletModel {
  final String idOutlet;
  final String? kode;
  final String nama;
  final String? alamat;
  final String? area; // Ini adalah idArea dari outlet
  final String? provinsi;
  final String? idAccount;
  final String? ket;
  final String? doc;
  final String? status;
  final String? lat;
  final String? lolat;
  final String? idDc;
  final String? idusers;
  final String? pulau;
  final String? region;
  final String? idP; // id_p di JSON
  final String? hk;
  final String? typeStore;
  final String? image;
  final String? kecamatan;
  final String? kelurahan;
  final String? zipCode;
  final String? segmentasi;
  final String? subsegmentasi;

  OutletModel({
    required this.idOutlet,
    this.kode,
    required this.nama,
    this.alamat,
    this.area,
    this.provinsi,
    this.idAccount,
    this.ket,
    this.doc,
    this.status,
    this.lat,
    this.lolat,
    this.idDc,
    this.idusers,
    this.pulau,
    this.region,
    this.idP,
    this.hk,
    this.typeStore,
    this.image,
    this.kecamatan,
    this.kelurahan,
    this.zipCode,
    this.segmentasi,
    this.subsegmentasi,
  });

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      idOutlet: json['idOutlet'] as String,
      kode: json['kode'] as String?,
      nama: json['nama'] as String,
      alamat: json['alamat'] as String?,
      area: json['area'] as String?,
      provinsi: json['provinsi'] as String?,
      idAccount: json['idAccount'] as String?,
      ket: json['ket'] as String?,
      doc: json['doc'] as String?,
      status: json['status'] as String?,
      lat: json['lat'] as String?,
      lolat: json['lolat'] as String?,
      idDc: json['id_dc'] as String?, // Perhatikan underscore di JSON
      idusers: json['idusers'] as String?,
      pulau: json['pulau'] as String?,
      region: json['region'] as String?,
      idP: json['id_p'] as String?, // Perhatikan underscore di JSON
      hk: json['hk'] as String?,
      typeStore: json['type_store'] as String?, // Perhatikan underscore di JSON
      image: json['image'] as String?,
      kecamatan: json['kecamatan'] as String?,
      kelurahan: json['kelurahan'] as String?,
      zipCode: json['zip_code'] as String?, // Perhatikan underscore di JSON
      segmentasi: json['segmentasi'] as String?,
      subsegmentasi: json['subsegmentasi'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idOutlet': idOutlet,
      'kode': kode,
      'nama': nama,
      'alamat': alamat,
      'area': area, // Simpan idArea untuk filtering
      'provinsi': provinsi,
      'idAccount': idAccount,
      'ket': ket,
      'doc': doc,
      'status': status,
      'lat': lat,
      'lolat': lolat,
      'id_dc': idDc,
      'idusers': idusers,
      'pulau': pulau,
      'region': region,
      'id_p': idP,
      'hk': hk,
      'type_store': typeStore,
      'image': image,
      'kecamatan': kecamatan,
      'kelurahan': kelurahan,
      'zip_code': zipCode,
      'segmentasi': segmentasi,
      'subsegmentasi': subsegmentasi,
    };
  }
}