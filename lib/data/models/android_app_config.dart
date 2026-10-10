import 'dart:convert';
import 'dart:typed_data';

enum AndroidAppType {
  customer('customer', 'Customer Food & Room Dining App', '🛵', 'Zomato/Swiggy-style guest ordering & in-room dining'),
  waiter('waiter', 'Staff Waiter & Captain POS App', '🍽️', 'Table-side digital ordering & instant KOT punch'),
  housekeeping('housekeeping', 'Housekeeping & Room Inspection App', '🧹', 'Real-time room status update & cleanliness checklist'),
  manager('manager', 'Owner & Manager Live ERP MIS App', '📊', 'Executive mobile dashboard for occupancy & daily sales'),
  deliveryBoy('delivery_boy', 'Delivery Boy & Rider Partner App', '🏍️', 'Live order pickup, customer navigation & delivery confirmation');

  final String id;
  final String label;
  final String icon;
  final String description;
  const AndroidAppType(this.id, this.label, this.icon, this.description);
}

class AndroidAppConfig {
  final String appId; // 'customer', 'waiter', 'housekeeping', 'manager'
  final String appTitle;
  final String appName;
  final String packageName;
  final String versionName;
  final int versionCode;
  final String hotelName;
  final String hotelTagline;
  final String hotelAddress;
  final String hotelCity;
  final String hotelState;
  final String hotelPhone;
  final String hotelGstin;
  final String hotelFssai;
  final String supportEmail;
  final String logoPreset; // 'royal_palace', 'fine_dining', 'express_delivery', 'butler_bell', 'beach_resort'
  final String? customLogoPath;
  final Uint8List? customLogoBytes;
  final String targetSdk;
  final String architecture;
  final String buildChannel;
  final DateTime lastBuiltDate;
  final String apkFileSize;

  const AndroidAppConfig({
    required this.appId,
    required this.appTitle,
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.hotelName,
    required this.hotelTagline,
    required this.hotelAddress,
    required this.hotelCity,
    required this.hotelState,
    required this.hotelPhone,
    required this.hotelGstin,
    required this.hotelFssai,
    required this.supportEmail,
    this.logoPreset = 'royal_palace',
    this.customLogoPath,
    this.customLogoBytes,
    this.targetSdk = 'Android 15 (API 35)',
    this.architecture = 'Universal APK (ARM64 / v7a / x86_64)',
    this.buildChannel = 'Production Signed Release',
    required this.lastBuiltDate,
    this.apkFileSize = '48.5 MB',
  });

  AndroidAppConfig copyWith({
    String? appName,
    String? packageName,
    String? versionName,
    int? versionCode,
    String? hotelName,
    String? hotelTagline,
    String? hotelAddress,
    String? hotelCity,
    String? hotelState,
    String? hotelPhone,
    String? hotelGstin,
    String? hotelFssai,
    String? supportEmail,
    String? logoPreset,
    String? customLogoPath,
    Uint8List? customLogoBytes,
    String? targetSdk,
    String? architecture,
    String? buildChannel,
    DateTime? lastBuiltDate,
    String? apkFileSize,
  }) {
    return AndroidAppConfig(
      appId: appId,
      appTitle: appTitle,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      hotelName: hotelName ?? this.hotelName,
      hotelTagline: hotelTagline ?? this.hotelTagline,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      hotelCity: hotelCity ?? this.hotelCity,
      hotelState: hotelState ?? this.hotelState,
      hotelPhone: hotelPhone ?? this.hotelPhone,
      hotelGstin: hotelGstin ?? this.hotelGstin,
      hotelFssai: hotelFssai ?? this.hotelFssai,
      supportEmail: supportEmail ?? this.supportEmail,
      logoPreset: logoPreset ?? this.logoPreset,
      customLogoPath: customLogoPath ?? this.customLogoPath,
      customLogoBytes: customLogoBytes ?? this.customLogoBytes,
      targetSdk: targetSdk ?? this.targetSdk,
      architecture: architecture ?? this.architecture,
      buildChannel: buildChannel ?? this.buildChannel,
      lastBuiltDate: lastBuiltDate ?? this.lastBuiltDate,
      apkFileSize: apkFileSize ?? this.apkFileSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'appTitle': appTitle,
      'appName': appName,
      'packageName': packageName,
      'versionName': versionName,
      'versionCode': versionCode,
      'hotelName': hotelName,
      'hotelTagline': hotelTagline,
      'hotelAddress': hotelAddress,
      'hotelCity': hotelCity,
      'hotelState': hotelState,
      'hotelPhone': hotelPhone,
      'hotelGstin': hotelGstin,
      'hotelFssai': hotelFssai,
      'supportEmail': supportEmail,
      'logoPreset': logoPreset,
      'customLogoPath': customLogoPath,
      'customLogoBase64': customLogoBytes != null ? base64Encode(customLogoBytes!) : null,
      'targetSdk': targetSdk,
      'architecture': architecture,
      'buildChannel': buildChannel,
      'lastBuiltDate': lastBuiltDate.toIso8601String(),
      'apkFileSize': apkFileSize,
    };
  }

  factory AndroidAppConfig.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    if (json['customLogoBase64'] != null) {
      try {
        bytes = base64Decode(json['customLogoBase64'] as String);
      } catch (_) {}
    }
    return AndroidAppConfig(
      appId: json['appId'] as String? ?? 'customer',
      appTitle: json['appTitle'] as String? ?? 'Customer Ordering App',
      appName: json['appName'] as String? ?? 'Shivshree Holidays Delivery',
      packageName: json['packageName'] as String? ?? 'com.shivshree.holidays',
      versionName: json['versionName'] as String? ?? 'v4.9.2',
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 42,
      hotelName: json['hotelName'] as String? ?? 'Shivshree Holidays',
      hotelTagline: json['hotelTagline'] as String? ?? 'Luxury Beachfront Resort & Fine Dining',
      hotelAddress: json['hotelAddress'] as String? ?? 'Beach Road, Tarkarli, Malvan',
      hotelCity: json['hotelCity'] as String? ?? 'Malvan',
      hotelState: json['hotelState'] as String? ?? 'Maharashtra',
      hotelPhone: json['hotelPhone'] as String? ?? '+91 98765 43210',
      hotelGstin: json['hotelGstin'] as String? ?? '27ABCDE1234F1Z5',
      hotelFssai: json['hotelFssai'] as String? ?? '11521000000123',
      supportEmail: json['supportEmail'] as String? ?? 'contact@shivshreeholidays.com',
      logoPreset: json['logoPreset'] as String? ?? 'royal_palace',
      customLogoPath: json['customLogoPath'] as String?,
      customLogoBytes: bytes,
      targetSdk: json['targetSdk'] as String? ?? 'Android 15 (API 35)',
      architecture: json['architecture'] as String? ?? 'Universal APK (ARM64 / v7a / x86_64)',
      buildChannel: json['buildChannel'] as String? ?? 'Production Signed Release',
      lastBuiltDate: json['lastBuiltDate'] != null
          ? DateTime.tryParse(json['lastBuiltDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      apkFileSize: json['apkFileSize'] as String? ?? '48.5 MB',
    );
  }
}
