// screens/activity/model/planogram_report.dart
import 'dart:convert';

List<PlanogramReport> planogramReportFromJson(String str) => List<PlanogramReport>.from(json.decode(str).map((x) => PlanogramReport.fromJson(x)));

String planogramReportToJson(List<PlanogramReport> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PlanogramReport {
    String outletName;
    String transactionDate; // Format "2025-05-16"
    String motoristName;
    List<Documentation> documentations;

    PlanogramReport({
        required this.outletName,
        required this.transactionDate,
        required this.motoristName,
        required this.documentations,
    });

    factory PlanogramReport.fromJson(Map<String, dynamic> json) => PlanogramReport(
        outletName: json["outlet_name"],
        transactionDate: json["transaction_date"],
        motoristName: json["motorist_name"],
        documentations: List<Documentation>.from(json["documentations"].map((x) => Documentation.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "transaction_date": transactionDate,
        "motorist_name": motoristName,
        "documentations": List<dynamic>.from(documentations.map((x) => x.toJson())),
    };
}

class Documentation {
    String masterImageUrl;
    String displayType;
    String displayIssue;
    String fotoBeforeUrl;
    String? descGambarBefore;
    String fotoAfterUrl;
    String? descGambarAfter;
    String itemTransactionTimestamp; // Format "2025-05-16 00:00:00"

    Documentation({
        required this.masterImageUrl,
        required this.displayType,
        required this.displayIssue,
        required this.fotoBeforeUrl,
        this.descGambarBefore,
        required this.fotoAfterUrl,
        this.descGambarAfter,
        required this.itemTransactionTimestamp,
    });

    factory Documentation.fromJson(Map<String, dynamic> json) => Documentation(
        masterImageUrl: json["master_image_url"],
        displayType: json["display_type"],
        displayIssue: json["display_issue"],
        fotoBeforeUrl: json["foto_before_url"],
        descGambarBefore: json["desc_gambar_before"],
        fotoAfterUrl: json["foto_after_url"],
        descGambarAfter: json["desc_gambar_after"],
        itemTransactionTimestamp: json["item_transaction_timestamp"],
    );

    Map<String, dynamic> toJson() => {
        "master_image_url": masterImageUrl,
        "display_type": displayType,
        "display_issue": displayIssue,
        "foto_before_url": fotoBeforeUrl,
        "desc_gambar_before": descGambarBefore,
        "foto_after_url": fotoAfterUrl,
        "desc_gambar_after": descGambarAfter,
        "item_transaction_timestamp": itemTransactionTimestamp,
    };
}