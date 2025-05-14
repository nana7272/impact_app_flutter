// To parse this JSON data, do
//
//     final store = storeFromJson(jsonString?);

import 'dart:convert';

Store storeFromJson(String str) => Store.fromJson(json.decode(str));

String storeToJson(Store data) => json.encode(data.toJson());

class Store {
    final String? idOutlet;
    final String? kode;
    final String? nama;
    final String? alamat;
    final String? area;
    final String? provinsi;
    final String? idAccount;
    final String? ket;
    final String? doc;
    final String? status;
    final double? lat;
    final double? lolat;
    final String? idDc;
    final String? idusers;
    final String? pulau;
    final String? region;
    final String? idP;
    final String? hk;
    final String? typeStore;
    final String? image;
    final String? kecamatan;
    final String? kelurahan;
    final dynamic zipCode;
    final dynamic segmentasi;
    final dynamic subsegmentasi;
    final int? distance;

    Store({
        this.idOutlet,
        this.kode,
        this.nama,
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
        this.distance,
    });

    factory Store.fromJson(Map<String?, dynamic> json) => Store(
        idOutlet: json["idOutlet"],
        kode: json["kode"],
        nama: json["nama"],
        alamat: json["alamat"],
        area: json["area"],
        provinsi: json["provinsi"],
        idAccount: json["idAccount"],
        ket: json["ket"],
        doc: json["doc"],
        status: json["status"],
        lat: json["lat"],
        lolat: json["lolat"],
        idDc: json["id_dc"],
        idusers: json["idusers"],
        pulau: json["pulau"],
        region: json["region"],
        idP: json["id_p"],
        hk: json["hk"],
        typeStore: json["type_store"],
        image: json["image"],
        kecamatan: json["kecamatan"],
        kelurahan: json["kelurahan"],
        zipCode: json["zip_code"],
        segmentasi: json["segmentasi"],
        subsegmentasi: json["subsegmentasi"],
        distance: json["distance"],
    );

    Map<String?, dynamic> toJson() => {
        "idOutlet": idOutlet,
        "kode": kode,
        "nama": nama,
        "alamat": alamat,
        "area": area,
        "provinsi": provinsi,
        "idAccount": idAccount,
        "ket": ket,
        "doc": doc,
        "status": status,
        "lat": lat,
        "lolat": lolat,
        "id_dc": idDc,
        "idusers": idusers,
        "pulau": pulau,
        "region": region,
        "id_p": idP,
        "hk": hk,
        "type_store": typeStore,
        "image": image,
        "kecamatan": kecamatan,
        "kelurahan": kelurahan,
        "zip_code": zipCode,
        "segmentasi": segmentasi,
        "subsegmentasi": subsegmentasi,
        "distance": distance,
    };
}
