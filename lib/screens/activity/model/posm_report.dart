// screens/activity/model/posm_report.dart
import 'dart:convert';

PosmReport posmReportFromJson(String str) => PosmReport.fromJson(json.decode(str));

String posmReportToJson(PosmReport data) => json.encode(data.toJson());

class PosmReport {
    PosmSummary summary;
    List<PosmDetail> details;

    PosmReport({
        required this.summary,
        required this.details,
    });

    factory PosmReport.fromJson(Map<String, dynamic> json) => PosmReport(
        summary: PosmSummary.fromJson(json["summary"]),
        details: List<PosmDetail>.from(json["details"].map((x) => PosmDetail.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "summary": summary.toJson(),
        "details": List<dynamic>.from(details.map((x) => x.toJson())),
    };
}

class PosmSummary {
    int totalPosm;
    int posmTerpasang;
    int posmTidakTerpasang;

    PosmSummary({
        required this.totalPosm,
        required this.posmTerpasang,
        required this.posmTidakTerpasang,
    });

    factory PosmSummary.fromJson(Map<String, dynamic> json) => PosmSummary(
        totalPosm: json["total_posm"],
        posmTerpasang: json["posm_terpasang"],
        posmTidakTerpasang: json["posm_tidak_terpasang"],
    );

    Map<String, dynamic> toJson() => {
        "total_posm": totalPosm,
        "posm_terpasang": posmTerpasang,
        "posm_tidak_terpasang": posmTidakTerpasang,
    };
}

class PosmDetail {
    String outletName;
    String transactionDatetime;
    List<ImagesDatum> imagesData;

    PosmDetail({
        required this.outletName,
        required this.transactionDatetime,
        required this.imagesData,
    });

    factory PosmDetail.fromJson(Map<String, dynamic> json) => PosmDetail(
        outletName: json["outlet_name"],
        transactionDatetime: json["transaction_datetime"],
        imagesData: List<ImagesDatum>.from(json["images_data"].map((x) => ImagesDatum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "transaction_datetime": transactionDatetime,
        "images_data": List<dynamic>.from(imagesData.map((x) => x.toJson())),
    };
}

class ImagesDatum {
    String imageUrl;
    String posmTypeName;
    String posmStatusName;
    int quantity;
    String keterangan;

    ImagesDatum({
        required this.imageUrl,
        required this.posmTypeName,
        required this.posmStatusName,
        required this.quantity,
        required this.keterangan,
    });

    factory ImagesDatum.fromJson(Map<String, dynamic> json) => ImagesDatum(
        imageUrl: json["image_url"],
        posmTypeName: json["posm_type_name"],
        posmStatusName: json["posm_status_name"],
        quantity: json["quantity"],
        keterangan: json["keterangan"],
    );

    Map<String, dynamic> toJson() => {
        "image_url": imageUrl,
        "posm_type_name": posmTypeName,
        "posm_status_name": posmStatusName,
        "quantity": quantity,
        "keterangan": keterangan,
    };
}