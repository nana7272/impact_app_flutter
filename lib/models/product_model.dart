class Product {
  final String? id;
  final String? code;
  final String? name;
  final double? price;
  final int? stock;
  final String? image;
  
  Product({
    this.id,
    this.code,
    this.name,
    this.price,
    this.stock,
    this.image,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      price: json['price'] != null ? double.parse(json['price'].toString()) : null,
      stock: json['stock'] != null ? int.parse(json['stock'].toString()) : null,
      image: json['image'],
    );
  }
  
  Map<String, String> toJson() {
    return {
      if (id != null) 'id': id!,
      if (code != null) 'code': code!,
      if (name != null) 'name': name!,
      if (price != null) 'price': price.toString(),
      if (stock != null) 'stock': stock.toString(),
    };
  }
}