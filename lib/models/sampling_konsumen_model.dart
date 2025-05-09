// lib/models/sampling_konsumen_model.dart
class SamplingKonsumen {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String nama;
  final String noHp;
  final String umur;
  final String alamat;
  final String email;
  final String? produkSebelumnya;
  final String? produkYangDibeli;
  final int kuantitas;
  final String keterangan;
  final String? createdAt;
  final bool isSynced;

  SamplingKonsumen({
    this.id,
    this.storeId,
    this.visitId,
    required this.nama,
    required this.noHp,
    required this.umur,
    required this.alamat,
    required this.email,
    this.produkSebelumnya,
    this.produkYangDibeli,
    required this.kuantitas,
    required this.keterangan,
    this.createdAt,
    this.isSynced = false,
  });

  factory SamplingKonsumen.fromJson(Map<String, dynamic> json) {
    return SamplingKonsumen(
      id: json['id'],
      storeId: json['store_id'],
      visitId: json['visit_id'],
      nama: json['nama'] ?? '',
      noHp: json['no_hp'] ?? '',
      umur: json['umur'] ?? '',
      alamat: json['alamat'] ?? '',
      email: json['email'] ?? '',
      produkSebelumnya: json['produk_sebelumnya'],
      produkYangDibeli: json['produk_yang_dibeli'],
      kuantitas: json['kuantitas'] != null ? int.parse(json['kuantitas'].toString()) : 0,
      keterangan: json['keterangan'] ?? '',
      createdAt: json['created_at'],
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (visitId != null) 'visit_id': visitId,
      'nama': nama,
      'no_hp': noHp,
      'umur': umur,
      'alamat': alamat,
      'email': email,
      if (produkSebelumnya != null) 'produk_sebelumnya': produkSebelumnya,
      if (produkYangDibeli != null) 'produk_yang_dibeli': produkYangDibeli,
      'kuantitas': kuantitas.toString(),
      'keterangan': keterangan,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  // Membuat salinan objek dengan nilai yang diperbarui
  SamplingKonsumen copyWith({
    String? id,
    String? storeId,
    String? visitId,
    String? nama,
    String? noHp,
    String? umur,
    String? alamat,
    String? email,
    String? produkSebelumnya,
    String? produkYangDibeli,
    int? kuantitas,
    String? keterangan,
    String? createdAt,
    bool? isSynced,
  }) {
    return SamplingKonsumen(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      visitId: visitId ?? this.visitId,
      nama: nama ?? this.nama,
      noHp: noHp ?? this.noHp,
      umur: umur ?? this.umur,
      alamat: alamat ?? this.alamat,
      email: email ?? this.email,
      produkSebelumnya: produkSebelumnya ?? this.produkSebelumnya,
      produkYangDibeli: produkYangDibeli ?? this.produkYangDibeli,
      kuantitas: kuantitas ?? this.kuantitas,
      keterangan: keterangan ?? this.keterangan,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

// Model untuk produk yang bisa dipilih
class ProdukSampling {
  final String? id;
  final String? kode;
  final String nama;
  final String? deskripsi;
  final String? kategori;
  
  ProdukSampling({
    this.id,
    this.kode,
    required this.nama,
    this.deskripsi,
    this.kategori,
  });
  
  factory ProdukSampling.fromJson(Map<String, dynamic> json) {
    return ProdukSampling(
      id: json['id'],
      kode: json['kode'],
      nama: json['nama'] ?? '',
      deskripsi: json['deskripsi'],
      kategori: json['kategori'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (kode != null) 'kode': kode,
      'nama': nama,
      if (deskripsi != null) 'deskripsi': deskripsi,
      if (kategori != null) 'kategori': kategori,
    };
  }
}