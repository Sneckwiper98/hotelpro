import 'package:flutter/material.dart';

/// Restaurant Aggregator & Middleware Channel Model
/// Supports Zomato, Swiggy, Magicpin, ONDC, and UrbanPiper / Petpooja middleware.
class AggregatorChannelModel {
  final String id; // 'zomato', 'swiggy', 'magicpin', 'ondc', 'urbanpiper'
  final String name; // 'Zomato', 'Swiggy', 'Magicpin', 'ONDC Network', 'UrbanPiper Gateway'
  final String code; // 'ZOM', 'SWG', 'MPC', 'ONDC', 'UP'
  bool isEnabled;
  String storeId;
  String apiKey;
  String apiSecret;
  bool autoAcceptOrders;
  bool autoKotPrint;
  double commissionPercentage;
  final Color brandColor;
  final IconData icon;

  AggregatorChannelModel({
    required this.id,
    required this.name,
    required this.code,
    this.isEnabled = true,
    required this.storeId,
    this.apiKey = '',
    this.apiSecret = '',
    this.autoAcceptOrders = true,
    this.autoKotPrint = true,
    required this.commissionPercentage,
    required this.brandColor,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'isEnabled': isEnabled,
    'storeId': storeId,
    'apiKey': apiKey,
    'apiSecret': apiSecret,
    'autoAcceptOrders': autoAcceptOrders,
    'autoKotPrint': autoKotPrint,
    'commissionPercentage': commissionPercentage,
  };

  factory AggregatorChannelModel.fromJson(
    Map<String, dynamic> json, {
    required Color brandColor,
    required IconData icon,
  }) {
    return AggregatorChannelModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
      storeId: json['storeId'] ?? '',
      apiKey: json['apiKey'] ?? '',
      apiSecret: json['apiSecret'] ?? '',
      autoAcceptOrders: json['autoAcceptOrders'] ?? true,
      autoKotPrint: json['autoKotPrint'] ?? true,
      commissionPercentage: (json['commissionPercentage'] as num?)?.toDouble() ?? 18.0,
      brandColor: brandColor,
      icon: icon,
    );
  }

  static List<AggregatorChannelModel> defaultChannels() => [
    AggregatorChannelModel(
      id: 'zomato',
      name: 'Zomato Food',
      code: 'ZOMATO',
      storeId: 'ZOM-MUM-882104',
      commissionPercentage: 18.0,
      brandColor: const Color(0xFFCB202D),
      icon: Icons.delivery_dining_rounded,
    ),
    AggregatorChannelModel(
      id: 'swiggy',
      name: 'Swiggy Delivery',
      code: 'SWIGGY',
      storeId: 'SWG-DEL-559102',
      commissionPercentage: 20.0,
      brandColor: const Color(0xFFFC8019),
      icon: Icons.moped_rounded,
    ),
    AggregatorChannelModel(
      id: 'magicpin',
      name: 'Magicpin Orders',
      code: 'MAGICPIN',
      storeId: 'MPC-STR-99120',
      commissionPercentage: 12.0,
      brandColor: const Color(0xFF8E44AD),
      icon: Icons.stars_rounded,
    ),
    AggregatorChannelModel(
      id: 'ondc',
      name: 'ONDC Network',
      code: 'ONDC',
      storeId: 'ONDC-RET-30018',
      commissionPercentage: 3.5,
      brandColor: const Color(0xFF1565C0),
      icon: Icons.hub_rounded,
    ),
    AggregatorChannelModel(
      id: 'urbanpiper',
      name: 'UrbanPiper Gateway',
      code: 'URBANPIPER',
      storeId: 'UP-QUINT-77001',
      commissionPercentage: 0.0, // Fixed SaaS fee
      brandColor: const Color(0xFF00897B),
      icon: Icons.sync_alt_rounded,
    ),
  ];
}
