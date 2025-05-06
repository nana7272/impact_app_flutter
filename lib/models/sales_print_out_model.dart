class SalesPrintOut {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String? createdAt;
  final List<SalesPrintOutItem> items;
  
  SalesPrintOut({
    this.id,
    this.storeId,
    this.visitId,
    this.createdAt,
    this.items = const [],
  });
  
  factory SalesPrintOut.fromJson(Map<String, dynamic> json) {
    List<SalesPrintOutItem> itemsList = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        itemsList.add(SalesPrintOutItem.fromJson(item));
      }
    }
    
    return SalesPrintOut(
      id: json['id'],
      storeId: json['store_id'],
      visitId: json['visit_id'],
      createdAt: json['created_at'],
      items: itemsList,
    );
  }
  
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> itemsList = [];
    for (var item in items) {
      itemsList.add(item.toJson());
    }
    
    return {
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (visitId != null) 'visit_id': visitId,
      'items': itemsList,
    };
  }
}

class SalesPrintOutItem {
  final String? productId;
  final String? productName;
  final int sellOutQty;
  final double sellOutValue;
  final String periode;
  final String? photo;
  
  SalesPrintOutItem({
    this.productId,
    this.productName,
    this.sellOutQty = 0,
    this.sellOutValue = 0,
    this.periode = '',
    this.photo,
  });
  
  factory SalesPrintOutItem.fromJson(Map<String, dynamic> json) {
    return SalesPrintOutItem(
      productId: json['product_id'],
      productName: json['product_name'],
      sellOutQty: json['sell_out_qty'] != null ? int.parse(json['sell_out_qty'].toString()) : 0,
      sellOutValue: json['sell_out_value'] != null ? double.parse(json['sell_out_value'].toString()) : 0,
      periode: json['periode'] ?? '',
      photo: json['photo'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      'sell_out_qty': sellOutQty.toString(),
      'sell_out_value': sellOutValue.toString(),
      'periode': periode,
      if (photo != null) 'photo': photo,
    };
  }
}