// screens/activity/model/activation_report.dart
import 'dart:convert';

ActivationReport activationReportFromJson(String str) => ActivationReport.fromJson(json.decode(str));

String activationReportToJson(ActivationReport data) => json.encode(data.toJson());

class ActivationReport {
    ActivationSummary summary;
    List<ActivationDetail> details;

    ActivationReport({
        required this.summary,
        required this.details,
    });

    factory ActivationReport.fromJson(Map<String, dynamic> json) => ActivationReport(
        summary: ActivationSummary.fromJson(json["summary"]),
        details: List<ActivationDetail>.from(json["details"].map((x) => ActivationDetail.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "summary": summary.toJson(),
        "details": List<dynamic>.from(details.map((x) => x.toJson())),
    };
}

class ActivationSummary {
    int totalSudahAktivasi;
    int totalBelumAktivasi;

    ActivationSummary({
        required this.totalSudahAktivasi,
        required this.totalBelumAktivasi,
    });

    factory ActivationSummary.fromJson(Map<String, dynamic> json) => ActivationSummary(
        totalSudahAktivasi: json["total_sudah_aktivasi"],
        totalBelumAktivasi: json["total_belum_aktivasi"],
    );

    Map<String, dynamic> toJson() => {
        "total_sudah_aktivasi": totalSudahAktivasi,
        "total_belum_aktivasi": totalBelumAktivasi,
    };
}

class ActivationDetail {
    String outletName;
    String transactionDatetime;
    List<ActivationImageData> imagesData;

    ActivationDetail({
        required this.outletName,
        required this.transactionDatetime,
        required this.imagesData,
    });

    factory ActivationDetail.fromJson(Map<String, dynamic> json) => ActivationDetail(
        outletName: json["outlet_name"],
        transactionDatetime: json["transaction_datetime"],
        imagesData: List<ActivationImageData>.from(json["images_data"].map((x) => ActivationImageData.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "transaction_datetime": transactionDatetime,
        "images_data": List<dynamic>.from(imagesData.map((x) => x.toJson())),
    };
}

class ActivationImageData {
    String imageUrl;
    String program;
    String periode;
    String keterangan;

    ActivationImageData({
        required this.imageUrl,
        required this.program,
        required this.periode,
        required this.keterangan,
    });

    factory ActivationImageData.fromJson(Map<String, dynamic> json) => ActivationImageData(
        imageUrl: json["image_url"],
        program: json["program"],
        periode: json["periode"],
        keterangan: json["keterangan"],
    );

    Map<String, dynamic> toJson() => {
        "image_url": imageUrl,
        "program": program,
        "periode": periode,
        "keterangan": keterangan,
    };
}