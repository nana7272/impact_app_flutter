class SamplingKonsumenModel {
  final String nama;
  final String alamat;
  final String noHp;
  final int umur;
  final String? email; // Optional
  final int idOutlet;
  final int sender; // Assuming sender is the user ID
  final int idProduct; // Product Dibeli
  final int? idProductPrev; // Product Sebelumnya (Optional)
  final int qlt; // Kuantitas
  final String? keterangan; // Optional

  SamplingKonsumenModel({
    required this.nama,
    required this.alamat,
    required this.noHp,
    required this.umur,
    this.email,
    required this.idOutlet,
    required this.sender,
    required this.idProduct,
    this.idProductPrev,
    required this.qlt,
    this.keterangan,
  });

  // Method to convert the model to a JSON map for the API
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'alamat': alamat,
      'no_hp': noHp,
      'umur': umur,
      'email': email,
      'id_outlet': idOutlet,
      'sender': sender,
      'id_product': idProduct,
      'id_product_prev': idProductPrev,
      'qlt': qlt,
      'keterangan': keterangan,
    };
  }

  // Optional: fromJson method if you ever need to parse API responses into this model
  // factory SamplingKonsumenModel.fromJson(Map<String, dynamic> json) {
  //   return SamplingKonsumenModel(
  //     nama: json['nama'] as String,
  //     alamat: json['alamat'] as String,
  //     noHp: json['no_hp'] as String,
  //     umur: json['umur'] as int,
  //     email: json['email'] as String?,
  //     idOutlet: json['id_outlet'] as int,
  //     sender: json['sender'] as int,
  //     idProduct: json['id_product'] as int,
  //     idProductPrev: json['id_product_prev'] as int?,
  //     qlt: json['qlt'] as int,
  //     keterangan: json['keterangan'] as String?,
  //   );
  // }
}