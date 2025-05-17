// models/sales_report.dart
import 'dart:convert';

List<SalesReport> salesReportFromJson(String str) => List<SalesReport>.from(json.decode(str).map((x) => SalesReport.fromJson(x)));

String salesReportToJson(List<SalesReport> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SalesReport {
    String outletName;
    String transactionDate;
    List<Product> products;
    String motoristName;

    SalesReport({
        required this.outletName,
        required this.transactionDate,
        required this.products,
        required this.motoristName,
    });

    factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
        outletName: json["outlet_name"],
        transactionDate: json["transaction_date"],
        products: List<Product>.from(json["products"].map((x) => Product.fromJson(x))),
        motoristName: json["motorist_name"],
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "transaction_date": transactionDate,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
        "motorist_name": motoristName,
    };
}

class Product {
    String productName;
    int quantity;
    int value;

    Product({
        required this.productName,
        required this.quantity,
        required this.value,
    });

    factory Product.fromJson(Map<String, dynamic> json) => Product(
        productName: json["product_name"],
        quantity: json["quantity"],
        value: json["value"],
    );

    Map<String, dynamic> toJson() => {
        "product_name": productName,
        "quantity": quantity,
        "value": value,
    };
}