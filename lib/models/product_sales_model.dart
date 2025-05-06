class ProductSales {
  final String? id;
  final String? code;
  final String? name;
  final double? price;
  final int? stock;
  final String? image;
  
  // Fields khusus untuk sales print out
  int sellOutQty = 0;
  double sellOutValue = 0;
  String periode = '';
  String? salesPhoto;

  ProductSales({
    this.id,
    this.code,
    this.name,
    this.price,
    this.stock,
    this.image,
    this.sellOutQty = 0,
    this.sellOutValue = 0,
    this.periode = '',
    this.salesPhoto,
  });
  
  factory ProductSales.fromJson(Map<String, dynamic> json) {
    return ProductSales(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0,
      stock: json['stock'] != null ? int.parse(json['stock'].toString()) : 0,
      image: json['image'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (price != null) 'price': price.toString(),
      if (stock != null) 'stock': stock.toString(),
      'sell_out_qty': sellOutQty.toString(),
      'sell_out_value': sellOutValue.toString(),
      'periode': periode,
    };
  }
}