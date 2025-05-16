// lib/models/product_sales_model.dart (atau di mana pun Anda mendefinisikannya)
import 'package:impact_app/screens/setting/model/product_model.dart';

class ProductSales {
  final String id; // Harus bisa di-parse ke int untuk id_product API OOS
  final String? name;
  final String? code;
  // Tambahkan field lain yang mungkin Anda tampilkan atau butuhkan
  // final double? price;

  ProductSales({
    required this.id,
    this.name,
    this.code,
    // this.price,
  });

  // Factory constructor opsional untuk membuat dari ProductModel
  factory ProductSales.fromProductModel(ProductModel productModel) {
    return ProductSales(
      id: productModel.idProduk, // Asumsi idProduk adalah String, jika int, ubah jadi .toString()
      name: productModel.nama,
      code: productModel.kode,
      // price: double.tryParse(productModel.harga ?? "0"),
    );
  }
}