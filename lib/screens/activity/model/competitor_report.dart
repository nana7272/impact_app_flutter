// screens/activity/model/competitor_report.dart
import 'dart:convert';

List<CompetitorReport> competitorReportFromJson(String str) => List<CompetitorReport>.from(json.decode(str).map((x) => CompetitorReport.fromJson(x)));

String competitorReportToJson(List<CompetitorReport> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CompetitorReport {
    String outletName;
    String outletAddress;
    String periode; // Format "14 May 2025 - 15 May 2025"
    String motoristName;
    ProductSection productOwn;
    ProductSection productCompetitor;

    CompetitorReport({
        required this.outletName,
        required this.outletAddress,
        required this.periode,
        required this.motoristName,
        required this.productOwn,
        required this.productCompetitor,
    });

    factory CompetitorReport.fromJson(Map<String, dynamic> json) => CompetitorReport(
        outletName: json["outlet_name"],
        outletAddress: json["outlet_address"],
        periode: json["periode"],
        motoristName: json["motorist_name"],
        productOwn: ProductSection.fromJson(json["product_own"]),
        productCompetitor: ProductSection.fromJson(json["product_competitor"]),
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "outlet_address": outletAddress,
        "periode": periode,
        "motorist_name": motoristName,
        "product_own": productOwn.toJson(),
        "product_competitor": productCompetitor.toJson(),
    };
}

class ProductSection {
    String imageUrl;
    List<ProductItem> items;

    ProductSection({
        required this.imageUrl,
        required this.items,
    });

    factory ProductSection.fromJson(Map<String, dynamic> json) => ProductSection(
        imageUrl: json["image_url"],
        items: List<ProductItem>.from(json["items"].map((x) => ProductItem.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "image_url": imageUrl,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
    };
}

class ProductItem {
    String productName;
    String hargaRbp;
    String hargaCbp;
    String hargaOutlet;

    ProductItem({
        required this.productName,
        required this.hargaRbp,
        required this.hargaCbp,
        required this.hargaOutlet,
    });

    factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
        productName: json["product_name"],
        hargaRbp: json["harga_rbp"],
        hargaCbp: json["harga_cbp"],
        hargaOutlet: json["harga_outlet"],
    );

    Map<String, dynamic> toJson() => {
        "product_name": productName,
        "harga_rbp": hargaRbp,
        "harga_cbp": hargaCbp,
        "harga_outlet": hargaOutlet,
    };
}