class ProductModel {
  final String idProduk;
  final String? idBrand;
  final String? idKateogri; // Typo di API 'id_kateogri', sesuaikan
  final String? kode;
  final String nama;
  final String? ket;
  final String? doc;
  final String? status;
  final String? harga; // Bisa jadi double/int, tapi API mengirim string
  final String? category;
  final String? gambar;
  final String? merk;
  final String? idSize;
  final String? idFlavour;
  final String? sku;
  // Asumsi id_principle dibutuhkan untuk relasi atau filtering, tambahkan jika perlu disimpan
  // final String? idPrinciple; 

  ProductModel({
    required this.idProduk,
    this.idBrand,
    this.idKateogri,
    this.kode,
    required this.nama,
    this.ket,
    this.doc,
    this.status,
    this.harga,
    this.category,
    this.gambar,
    this.merk,
    this.idSize,
    this.idFlavour,
    this.sku,
    // this.idPrinciple,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json /*, {String? principleId} */) {
    return ProductModel(
      idProduk: json['idProduk'] as String,
      idBrand: json['idBrand'] as String?,
      idKateogri: json['id_kateogri'] as String?, // Sesuaikan dengan respons API
      kode: json['kode'] as String?,
      nama: json['nama'] as String,
      ket: json['ket'] as String?,
      doc: json['doc'] as String?,
      status: json['status'] as String?,
      harga: json['harga'] as String?,
      category: json['category'] as String?,
      gambar: json['gambar'] as String?,
      merk: json['merk'] as String?,
      idSize: json['id_size'] as String?,
      idFlavour: json['id_flavour'] as String?,
      sku: json['sku'] as String?,
      // idPrinciple: principleId, // Jika Anda ingin menyimpan idPrinciple bersama produk
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idProduk': idProduk,
      'idBrand': idBrand,
      'id_kateogri': idKateogri,
      'kode': kode,
      'nama': nama,
      'ket': ket,
      'doc': doc,
      'status': status,
      'harga': harga,
      'category': category,
      'gambar': gambar,
      'merk': merk,
      'id_size': idSize,
      'id_flavour': idFlavour,
      'sku': sku,
      // 'idPrinciple': idPrinciple,
    };
  }
}