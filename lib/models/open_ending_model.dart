// Simpan file ini sebagai: lib/models/open_ending_model.dart

class OpenEndingData {
  final String? id;
  final String? storeId;
  final String? visitId;
  final String? createdAt;
  final List<OpenEndingItem> items;
  
  OpenEndingData({
    this.id,
    this.storeId,
    this.visitId,
    this.createdAt,
    this.items = const [],
  });
  
  factory OpenEndingData.fromJson(Map<String, dynamic> json) {
    List<OpenEndingItem> itemsList = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        itemsList.add(OpenEndingItem.fromJson(item));
      }
    }
    
    return OpenEndingData(
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

class OpenEndingItem {
  final String? productId;
  final String? productName;
  final int openStock;
  final int inStock;
  final int endingStock;
  final int sellOut;
  final bool hasStockReturn;
  final int? stockReturnQty;
  final bool hasStockExpired;
  final int? stockExpiredQty;
  
  OpenEndingItem({
    this.productId,
    this.productName,
    this.openStock = 0,
    this.inStock = 0,
    this.endingStock = 0,
    this.sellOut = 0,
    this.hasStockReturn = false,
    this.stockReturnQty,
    this.hasStockExpired = false,
    this.stockExpiredQty,
  });
  
  factory OpenEndingItem.fromJson(Map<String, dynamic> json) {
    return OpenEndingItem(
      productId: json['product_id'],
      productName: json['product_name'],
      openStock: json['open_stock'] != null ? int.parse(json['open_stock'].toString()) : 0,
      inStock: json['in_stock'] != null ? int.parse(json['in_stock'].toString()) : 0,
      endingStock: json['ending_stock'] != null ? int.parse(json['ending_stock'].toString()) : 0,
      sellOut: json['sell_out'] != null ? int.parse(json['sell_out'].toString()) : 0,
      hasStockReturn: json['has_stock_return'] == 1 || json['has_stock_return'] == true,
      stockReturnQty: json['stock_return_qty'] != null ? int.parse(json['stock_return_qty'].toString()) : null,
      hasStockExpired: json['has_stock_expired'] == 1 || json['has_stock_expired'] == true,
      stockExpiredQty: json['stock_expired_qty'] != null ? int.parse(json['stock_expired_qty'].toString()) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      'open_stock': openStock.toString(),
      'in_stock': inStock.toString(),
      'ending_stock': endingStock.toString(),
      'sell_out': sellOut.toString(),
      'has_stock_return': hasStockReturn ? 1 : 0,
      if (stockReturnQty != null) 'stock_return_qty': stockReturnQty.toString(),
      'has_stock_expired': hasStockExpired ? 1 : 0,
      if (stockExpiredQty != null) 'stock_expired_qty': stockExpiredQty.toString(),
    };
  }
}