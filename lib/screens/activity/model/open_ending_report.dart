// screens/activity/model/open_ending_report.dart
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

List<OpenEndingReport> openEndingReportFromJson(String str) => List<OpenEndingReport>.from(json.decode(str).map((x) => OpenEndingReport.fromJson(x)));

String openEndingReportToJson(List<OpenEndingReport> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OpenEndingReport {
    String outletName;
    String transactionDate;
    List<OpenEndingProduct> products;
    String motoristName;

    OpenEndingReport({
        required this.outletName,
        required this.transactionDate,
        required this.products,
        required this.motoristName,
    });

    factory OpenEndingReport.fromJson(Map<String, dynamic> json) => OpenEndingReport(
        outletName: json["outlet_name"],
        transactionDate: json["transaction_date"],
        products: List<OpenEndingProduct>.from(json["products"].map((x) => OpenEndingProduct.fromJson(x))),
        motoristName: json["motorist_name"],
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "transaction_date": transactionDate,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
        "motorist_name": motoristName,
    };
}

class OpenEndingProduct {
    String productName;
    int openStock;
    int inStock;
    int endingStock;
    String? sellOut; // Bisa jadi string kosong atau null, atau angka dalam string
    int stockReturn;
    int stockExpired;
    String cardColor;

    OpenEndingProduct({
        required this.productName,
        required this.openStock,
        required this.inStock,
        required this.endingStock,
        this.sellOut,
        required this.stockReturn,
        required this.stockExpired,
        required this.cardColor,
    });

    factory OpenEndingProduct.fromJson(Map<String, dynamic> json) => OpenEndingProduct(
        productName: json["product_name"],
        openStock: json["open_stock"],
        inStock: json["in_stock"],
        endingStock: json["ending_stock"],
        sellOut: json["sell_out"] == null || json["sell_out"] == "" ? null : json["sell_out"].toString(), // Handle jika null atau string kosong
        stockReturn: json["stock_return"],
        stockExpired: json["stock_expired"],
        cardColor: json["card_color"],
    );

    Map<String, dynamic> toJson() => {
        "product_name": productName,
        "open_stock": openStock,
        "in_stock": inStock,
        "ending_stock": endingStock,
        "sell_out": sellOut,
        "stock_return": stockReturn,
        "stock_expired": stockExpired,
        "card_color": cardColor,
    };

    // Helper untuk mendapatkan warna berdasarkan string cardColor
    Color get getCardColor {
        switch (cardColor.toLowerCase()) {
            case "green":
                return Colors.green.shade400; // Sesuaikan shade jika perlu
            case "red":
                return Colors.red.shade400;
            case "yellow":
                return Colors.yellow.shade600;
            // Tambahkan case lain jika ada
            default:
                return Colors.grey.shade400;
        }
    }
}