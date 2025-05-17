// screens/activity/model/sampling_konsumen_report.dart
import 'dart:convert';

List<SamplingKonsumenReport> samplingKonsumenReportFromJson(String str) => List<SamplingKonsumenReport>.from(json.decode(str).map((x) => SamplingKonsumenReport.fromJson(x)));

String samplingKonsumenReportToJson(List<SamplingKonsumenReport> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SamplingKonsumenReport {
    String outletName;
    String outletAddress;
    String transactionDate; // Format "16 May 2025"
    String motoristName;
    List<ConsumerSampling> consumerSamplings;

    SamplingKonsumenReport({
        required this.outletName,
        required this.outletAddress,
        required this.transactionDate,
        required this.motoristName,
        required this.consumerSamplings,
    });

    factory SamplingKonsumenReport.fromJson(Map<String, dynamic> json) => SamplingKonsumenReport(
        outletName: json["outlet_name"],
        outletAddress: json["outlet_address"],
        transactionDate: json["transaction_date"],
        motoristName: json["motorist_name"],
        consumerSamplings: List<ConsumerSampling>.from(json["consumer_samplings"].map((x) => ConsumerSampling.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "outlet_address": outletAddress,
        "transaction_date": transactionDate,
        "motorist_name": motoristName,
        "consumer_samplings": List<dynamic>.from(consumerSamplings.map((x) => x.toJson())),
    };
}

class ConsumerSampling {
    String consumerName;
    String? consumerEmail;
    String consumerPhone;
    String? consumerImageUrl; // Bisa null
    String samplingTime; // Format "16:34"
    List<SamplingProduct> products;

    ConsumerSampling({
        required this.consumerName,
        this.consumerEmail,
        required this.consumerPhone,
        this.consumerImageUrl,
        required this.samplingTime,
        required this.products,
    });

    factory ConsumerSampling.fromJson(Map<String, dynamic> json) => ConsumerSampling(
        consumerName: json["consumer_name"],
        consumerEmail: json["consumer_email"],
        consumerPhone: json["consumer_phone"],
        consumerImageUrl: json["consumer_image_url"],
        samplingTime: json["sampling_time"],
        products: List<SamplingProduct>.from(json["products"].map((x) => SamplingProduct.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "consumer_name": consumerName,
        "consumer_email": consumerEmail,
        "consumer_phone": consumerPhone,
        "consumer_image_url": consumerImageUrl,
        "sampling_time": samplingTime,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
    };
}

class SamplingProduct {
    String productName;
    int quantity;
    String? keteranganProduk;

    SamplingProduct({
        required this.productName,
        required this.quantity,
        this.keteranganProduk,
    });

    factory SamplingProduct.fromJson(Map<String, dynamic> json) => SamplingProduct(
        productName: json["product_name"],
        quantity: json["quantity"],
        keteranganProduk: json["keterangan_produk"],
    );

    Map<String, dynamic> toJson() => {
        "product_name": productName,
        "quantity": quantity,
        "keterangan_produk": keteranganProduk,
    };
}