// screens/activity/model/price_monitoring_report.dart
import 'dart:convert';

List<PriceMonitoringReport> priceMonitoringReportFromJson(String str) => List<PriceMonitoringReport>.from(json.decode(str).map((x) => PriceMonitoringReport.fromJson(x)));

String priceMonitoringReportToJson(List<PriceMonitoringReport> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PriceMonitoringReport {
    String outletName;
    String outletAddress;
    String transactionDatetime;
    List<PriceProduct> products;
    String? notes; // notes bisa null
    String motoristName;

    PriceMonitoringReport({
        required this.outletName,
        required this.outletAddress,
        required this.transactionDatetime,
        required this.products,
        this.notes,
        required this.motoristName,
    });

    factory PriceMonitoringReport.fromJson(Map<String, dynamic> json) => PriceMonitoringReport(
        outletName: json["outlet_name"],
        outletAddress: json["outlet_address"],
        transactionDatetime: json["transaction_datetime"],
        products: List<PriceProduct>.from(json["products"].map((x) => PriceProduct.fromJson(x))),
        notes: json["notes"],
        motoristName: json["motorist_name"],
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "outlet_address": outletAddress,
        "transaction_datetime": transactionDatetime,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
        "notes": notes,
        "motorist_name": motoristName,
    };
}

class PriceProduct {
    String productName;
    String hargaNormal;
    String hargaPromo;

    PriceProduct({
        required this.productName,
        required this.hargaNormal,
        required this.hargaPromo,
    });

    factory PriceProduct.fromJson(Map<String, dynamic> json) => PriceProduct(
        productName: json["product_name"],
        hargaNormal: json["harga_normal"],
        hargaPromo: json["harga_promo"],
    );

    Map<String, dynamic> toJson() => {
        "product_name": productName,
        "harga_normal": hargaNormal,
        "harga_promo": hargaPromo,
    };
}