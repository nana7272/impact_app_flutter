// screens/activity/model/oos_report.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // Untuk Color

List<OosReport> oosReportFromJson(String str) => List<OosReport>.from(json.decode(str).map((x) => OosReport.fromJson(x)));

String oosReportToJson(List<OosReport> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OosReport {
    String outletName;
    String transactionDate;
    List<OosProduct> products;
    String motoristName;

    OosReport({
        required this.outletName,
        required this.transactionDate,
        required this.products,
        required this.motoristName,
    });

    factory OosReport.fromJson(Map<String, dynamic> json) => OosReport(
        outletName: json["outlet_name"],
        transactionDate: json["transaction_date"],
        products: List<OosProduct>.from(json["products"].map((x) => OosProduct.fromJson(x))),
        motoristName: json["motorist_name"],
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "transaction_date": transactionDate,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
        "motorist_name": motoristName,
    };
}

class OosProduct {
    String productName;
    int quantity;
    String keterangan;
    String availabilityStatus;
    String cardColor;

    OosProduct({
        required this.productName,
        required this.quantity,
        required this.keterangan,
        required this.availabilityStatus,
        required this.cardColor,
    });

    factory OosProduct.fromJson(Map<String, dynamic> json) => OosProduct(
        productName: json["product_name"],
        quantity: json["quantity"],
        keterangan: json["keterangan"],
        availabilityStatus: json["availability_status"],
        cardColor: json["card_color"],
    );

    Map<String, dynamic> toJson() => {
        "product_name": productName,
        "quantity": quantity,
        "keterangan": keterangan,
        "availability_status": availabilityStatus,
        "card_color": cardColor,
    };

    Color get getCardColor {
        switch (cardColor.toLowerCase()) {
            case "green":
                return Colors.green.shade400;
            case "red":
                return Colors.red.shade400;
            case "yellow":
                return Colors.yellow.shade600;
            default:
                return Colors.grey.shade400;
        }
    }

    Color get getStatusChipColor {
        // Warna chip status bisa sama dengan warna kartu atau berbeda
        // Sesuai UI, "Tersedia" (hijau) dan "Kosong" (merah)
        switch (availabilityStatus.toLowerCase()) {
            case "tersedia":
                return Colors.teal.shade400; // Warna hijau yang sedikit berbeda untuk chip
            case "kosong":
                return Colors.red.shade600;
            default:
                return Colors.grey.shade500;
        }
    }
}