class Store {
  final String? id;
  final String? code;
  final String? name;
  final String? address;
  final String? description;
  final String? distributor;
  final String? segment;
  final String? province;
  final String? area;
  final String? district; // kecamatan
  final String? subDistrict; // kelurahan
  final String? account;
  final String? type;
  final String? image;
  final double? latitude;
  final double? longitude;
  final int? distance; // dalam meter
  
  Store({
    this.id,
    this.code,
    this.name,
    this.address,
    this.description,
    this.distributor,
    this.segment,
    this.province,
    this.area,
    this.district,
    this.subDistrict,
    this.account,
    this.type,
    this.image,
    this.latitude,
    this.longitude,
    this.distance,
  });
  
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      code: json['kode_outlet'],
      name: json['nama_outlet'],
      address: json['alamat'],
      description: json['keterangan'],
      distributor: json['distributor_center'],
      segment: json['segment'],
      province: json['provinsi'],
      area: json['area'],
      district: json['kecamatan'],
      subDistrict: json['kelurahan'],
      account: json['account'],
      type: json['type'],
      image: json['foto'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      distance: json['distance'],
    );
  }
  
  Map<String, String> toJson() {
    return {
      if (id != null) 'id': id!,
      if (code != null) 'kode_outlet': code!,
      if (name != null) 'nama_outlet': name!,
      if (address != null) 'alamat': address!,
      if (description != null) 'keterangan': description!,
      if (distributor != null) 'distributor_center': distributor!,
      if (segment != null) 'segment': segment!,
      if (province != null) 'provinsi': province!,
      if (area != null) 'area': area!,
      if (district != null) 'kecamatan': district!,
      if (subDistrict != null) 'kelurahan': subDistrict!,
      if (account != null) 'account': account!,
      if (type != null) 'type': type!,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    };
  }
}