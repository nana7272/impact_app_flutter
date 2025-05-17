// models/stock_report.dart
import 'dart:convert';

StockReport stockReportFromJson(String str) => StockReport.fromJson(json.decode(str));

String stockReportToJson(StockReport data) => json.encode(data.toJson());

class StockReport {
    Summary summary;
    List<StockDetail> details;

    StockReport({
        required this.summary,
        required this.details,
    });

    factory StockReport.fromJson(Map<String, dynamic> json) => StockReport(
        summary: Summary.fromJson(json["summary"]),
        details: List<StockDetail>.from(json["details"].map((x) => StockDetail.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "summary": summary.toJson(),
        "details": List<dynamic>.from(details.map((x) => x.toJson())),
    };
}

class Summary {
    int stokTersedia;
    int stokTidakTersedia;

    Summary({
        required this.stokTersedia,
        required this.stokTidakTersedia,
    });

    factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        stokTersedia: json["stok_tersedia"],
        stokTidakTersedia: json["stok_tidak_tersedia"],
    );

    Map<String, dynamic> toJson() => {
        "stok_tersedia": stokTersedia,
        "stok_tidak_tersedia": stokTidakTersedia,
    };
}

class StockDetail {
    String outletName;
    String outletAddress;
    String transactionDatetime;
    List<StockItem> items;
    String motoristName;

    StockDetail({
        required this.outletName,
        required this.outletAddress,
        required this.transactionDatetime,
        required this.items,
        required this.motoristName,
    });

    factory StockDetail.fromJson(Map<String, dynamic> json) => StockDetail(
        outletName: json["outlet_name"],
        outletAddress: json["outlet_address"],
        transactionDatetime: json["transaction_datetime"],
        items: List<StockItem>.from(json["items"].map((x) => StockItem.fromJson(x))),
        motoristName: json["motorist_name"],
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "outlet_address": outletAddress,
        "transaction_datetime": transactionDatetime,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
        "motorist_name": motoristName,
    };
}

class StockItem {
    String productName;
    int stockGudang;
    int stockDisplay;
    int totalStock;

    StockItem({
        required this.productName,
        required this.stockGudang,
        required this.stockDisplay,
        required this.totalStock,
    });

    factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        productName: json["product_name"],
        stockGudang: json["stock_gudang"],
        stockDisplay: json["stock_display"],
        totalStock: json["total_stock"],
    );

    Map<String, dynamic> toJson() => {
        "product_name": productName,
        "stock_gudang": stockGudang,
        "stock_display": stockDisplay,
        "total_stock": totalStock,
    };
}