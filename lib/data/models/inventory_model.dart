import 'package:flutter/material.dart';

enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'IN STOCK';
      case StockStatus.lowStock:
        return 'LOW STOCK';
      case StockStatus.outOfStock:
        return 'OUT OF STOCK';
    }
  }

  Color get color {
    switch (this) {
      case StockStatus.inStock:
        return const Color(0xFF27AE60);
      case StockStatus.lowStock:
        return const Color(0xFFE67E22);
      case StockStatus.outOfStock:
        return const Color(0xFFC0392B);
    }
  }

  Color get bgColor {
    switch (this) {
      case StockStatus.inStock:
        return const Color(0xFFE8F8F5);
      case StockStatus.lowStock:
        return const Color(0xFFFEF9E7);
      case StockStatus.outOfStock:
        return const Color(0xFFFDEDEC);
    }
  }
}

class StockItemModel {
  final String id;
  final String branchId;
  final String itemCode;
  final String name;
  final String category; // Kitchen & Provisions, Housekeeping & Linen, Guest Amenities, Beverages & Bar, Maintenance & Hardware
  final String unit; // Kg, Ltr, Pcs, Box, Pack, Can, Bottle, Set
  final double currentStock;
  final double reorderLevel;
  final double unitPrice;
  final String storageLocation; // Main Central Store, Kitchen Pantry, Housekeeping Linen Room
  final DateTime lastRestockedAt;

  const StockItemModel({
    required this.id,
    required this.branchId,
    required this.itemCode,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.reorderLevel,
    required this.unitPrice,
    this.storageLocation = 'Central Store',
    required this.lastRestockedAt,
  });

  double get stockValue => currentStock * unitPrice;
  double get valuation => stockValue;
  bool get isLowStock => currentStock <= reorderLevel && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;

  StockStatus get status {
    if (currentStock <= 0) return StockStatus.outOfStock;
    if (currentStock <= reorderLevel) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchId': branchId,
    'itemCode': itemCode,
    'name': name,
    'category': category,
    'unit': unit,
    'currentStock': currentStock,
    'reorderLevel': reorderLevel,
    'unitPrice': unitPrice,
    'storageLocation': storageLocation,
    'lastRestockedAt': lastRestockedAt.toIso8601String(),
  };

  Map<String, dynamic> toSupabaseJson() => {
    'id': id,
    'branch_id': branchId,
    'item_code': itemCode,
    'name': name,
    'category': category,
    'unit': unit,
    'current_stock': currentStock,
    'reorder_level': reorderLevel,
    'unit_price': unitPrice,
    'storage_location': storageLocation,
    'last_restocked_at': lastRestockedAt.toIso8601String(),
  };

  factory StockItemModel.fromJson(Map<String, dynamic> json) => StockItemModel(
    id: json['id'] as String? ?? '',
    branchId: json['branch_id'] ?? json['branchId'] ?? '',
    itemCode: json['item_code'] ?? json['itemCode'] ?? 'STK-0000',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    unit: json['unit'] as String? ?? 'Pcs',
    currentStock: ((json['current_stock'] ?? json['currentStock']) as num?)?.toDouble() ?? 0.0,
    reorderLevel: ((json['reorder_level'] ?? json['reorderLevel']) as num?)?.toDouble() ?? 10.0,
    unitPrice: ((json['unit_price'] ?? json['unitPrice']) as num?)?.toDouble() ?? 0.0,
    storageLocation: json['storage_location'] ?? json['storageLocation'] ?? 'Central Store',
    lastRestockedAt: DateTime.tryParse((json['last_restocked_at'] ?? json['lastRestockedAt']) as String? ?? '') ?? DateTime.now(),
  );

  StockItemModel copyWith({
    String? id,
    String? branchId,
    String? itemCode,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? reorderLevel,
    double? unitPrice,
    String? storageLocation,
    DateTime? lastRestockedAt,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      itemCode: itemCode ?? this.itemCode,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unitPrice: unitPrice ?? this.unitPrice,
      storageLocation: storageLocation ?? this.storageLocation,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
    );
  }
}
