// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
    final String? idLogin;
    final String? idpriciple;
    final String? user;
    final String? firstname;
    final String? lastname;
    final String? email;
    final String? pass;
    final String? forgot;
    final String? level;
    final String? jabatan;
    final String? provinsi;
    final String? area;
    final String? noInduk;
    final String? idjamsostek;
    final String? npwp;
    final String? jk;
    final String? ibukandung;
    final String? agama;
    final String? pendididkanterakhir;
    final DateTime? tglmasuk;
    final DateTime? tgllahir;
    final String? alamat;
    final String? nohp;
    final String? userOperator;
    final String? modelPhone;
    final String? gcmId;
    final String? devId;
    final String? tlId;
    final String? kooId;
    final String? picId;
    final String? imageUrl;
    final String? typeUser;
    final String? status;
    final dynamic rememberToken;
    final String? doc;

    User({
        required this.idLogin,
        required this.idpriciple,
        required this.user,
        required this.firstname,
        required this.lastname,
        required this.email,
        required this.pass,
        required this.forgot,
        required this.level,
        required this.jabatan,
        required this.provinsi,
        required this.area,
        required this.noInduk,
        required this.idjamsostek,
        required this.npwp,
        required this.jk,
        required this.ibukandung,
        required this.agama,
        required this.pendididkanterakhir,
        required this.tglmasuk,
        required this.tgllahir,
        required this.alamat,
        required this.nohp,
        required this.userOperator,
        required this.modelPhone,
        required this.gcmId,
        required this.devId,
        required this.tlId,
        required this.kooId,
        required this.picId,
        required this.imageUrl,
        required this.typeUser,
        required this.status,
        required this.rememberToken,
        required this.doc,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        idLogin: json["idLogin"],
        idpriciple: json["idpriciple"],
        user: json["user"],
        firstname: json["firstname"],
        lastname: json["lastname"],
        email: json["email"],
        pass: json["pass"],
        forgot: json["forgot"],
        level: json["level"],
        jabatan: json["jabatan"],
        provinsi: json["provinsi"],
        area: json["area"],
        noInduk: json["no_induk"],
        idjamsostek: json["idjamsostek"],
        npwp: json["npwp"],
        jk: json["jk"],
        ibukandung: json["ibukandung"],
        agama: json["agama"],
        pendididkanterakhir: json["pendididkanterakhir"],
        tglmasuk: json["tglmasuk"] == null ? null : DateTime.parse(json["tglmasuk"]),
        tgllahir: json["tgllahir"] == null ? null : DateTime.parse(json["tgllahir"]),
        alamat: json["alamat"],
        nohp: json["nohp"],
        userOperator: json["operator"],
        modelPhone: json["model_phone"],
        gcmId: json["gcm_id"],
        devId: json["dev_id"],
        tlId: json["tl_id"],
        kooId: json["koo_id"],
        picId: json["pic_id"],
        imageUrl: json["image_url"],
        typeUser: json["type_user"],
        status: json["status"],
        rememberToken: json["remember_token"],
        doc: json["doc"],
    );

    Map<String, dynamic> toJson() => {
        "idLogin": idLogin,
        "idpriciple": idpriciple,
        "user": user,
        "firstname": firstname,
        "lastname": lastname,
        "email": email,
        "pass": pass,
        "forgot": forgot,
        "level": level,
        "jabatan": jabatan,
        "provinsi": provinsi,
        "area": area,
        "no_induk": noInduk,
        "idjamsostek": idjamsostek,
        "npwp": npwp,
        "jk": jk,
        "ibukandung": ibukandung,
        "agama": agama,
        "pendididkanterakhir": pendididkanterakhir,
        "tglmasuk": tglmasuk == null ? null : "${tglmasuk!.year.toString().padLeft(4, '0')}-${tglmasuk!.month.toString().padLeft(2, '0')}-${tglmasuk!.day.toString().padLeft(2, '0')}",
        "tgllahir": tgllahir == null ? null : "${tgllahir!.year.toString().padLeft(4, '0')}-${tgllahir!.month.toString().padLeft(2, '0')}-${tgllahir!.day.toString().padLeft(2, '0')}",
        "alamat": alamat,
        "nohp": nohp,
        "operator": userOperator,
        "model_phone": modelPhone,
        "gcm_id": gcmId,
        "dev_id": devId,
        "tl_id": tlId,
        "koo_id": kooId,
        "pic_id": picId,
        "image_url": imageUrl,
        "type_user": typeUser,
        "status": status,
        "remember_token": rememberToken,
        "doc": doc,
    };
}
