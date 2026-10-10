import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../config/supabase_config.dart';

class HotelConfigStorage {
  static const String _logoFileName = 'custom_hotel_logo.png';

  /// Removes all local cached data files so system relies exclusively on online Supabase
  static Future<void> clearAllLocalDataFiles() async {
    try {
      final dir = _getConfigDirectory();
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
            }
          } catch (_) {}
        }
      }
      debugPrint('[HotelConfigStorage] Cleared all local cached files.');
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error clearing local files: $e');
    }
  }

  static Directory _getConfigDirectory() {
    try {
      if (kIsWeb) {
        return Directory.current;
      }
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final dir = Directory('$appData\\HotelPro');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          return dir;
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        final androidFiles = Directory('/data/user/0/com.isecuresystem.hotelpro/files');
        if (androidFiles.existsSync()) {
          return androidFiles;
        }
        return Directory.systemTemp;
      }
    } catch (_) {}
    return Directory.current;
  }

  static Future<File> _getFile(String filename) async {
    final dir = _getConfigDirectory();
    return File('${dir.path}${Platform.pathSeparator}$filename');
  }

  static Future<void> saveConfig({
    required String businessName,
    required String tagline,
    required String address,
    required String city,
    required String state,
    required String phone,
    required String email,
    required String gstin,
    required String currency,
    required String licenseKey,
    required String licenseType,
    required String expiryDate,
    required String contactPerson,
    required bool enableRooms,
    required bool enablePos,
    required bool enableHousekeeping,
    required bool enableCrs,
    required bool enableBanquet,
    required bool enableCustomerApp,
    required double roomGst,
    required double foodGst,
    Uint8List? logoBytes,
    String? logoPath,
    List<Map<String, dynamic>>? androidAppsConfig,
  }) async {
    try {
      String? logoBase64;
      if (logoBytes != null && logoBytes.isNotEmpty) {
        logoBase64 = base64Encode(logoBytes);
        try {
          final logoFile = await _getFile(_logoFileName);
          await logoFile.writeAsBytes(logoBytes);
        } catch (_) {}

        // Automatically update Hotel Logo asset and sync Android App Launcher Icons
        try {
          final assetFile = File('lib/ui/features/master/assets/hotel_logo.png');
          await assetFile.writeAsBytes(logoBytes);
          if (Platform.isWindows && File('update_hotel_icons.ps1').existsSync()) {
            Process.run('powershell.exe', [
              '-ExecutionPolicy',
              'Bypass',
              '-File',
              '.\\update_hotel_icons.ps1',
              '-SourceLogo',
              assetFile.path,
            ]);
          }
        } catch (_) {}
      }

      // 1. Direct Online Supabase Cloud Synchronization
      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        try {
          await SupabaseConfig.client!.from('hotel_business_config').upsert({
            'id': 'config-primary',
            'business_name': businessName,
            'tagline': tagline,
            'address': address,
            'city': city,
            'state': state,
            'phone': phone,
            'email': email,
            'gstin': gstin,
            'currency': currency,
            'license_key': licenseKey,
            'license_type': licenseType,
            'expiry_date': expiryDate,
            'contact_person': contactPerson,
            'enable_rooms': enableRooms,
            'enable_pos': enablePos,
            'enable_housekeeping': enableHousekeeping,
            'enable_crs': enableCrs,
            'enable_banquet': enableBanquet,
            'enable_customer_app': enableCustomerApp,
            'room_gst': roomGst,
            'food_gst': foodGst,
            'logo_url': logoBase64 != null ? 'data:image/png;base64,$logoBase64' : null,
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint('[HotelConfigStorage] Saved business config directly to Supabase cloud.');
        } catch (e) {
          debugPrint('[HotelConfigStorage] Supabase saveConfig error: $e');
        }
      }
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error saving config: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadConfig() async {
    // 1. Primary Source of Truth: Live Online Supabase Cloud
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      try {
        final res = await SupabaseConfig.client!
            .from('hotel_business_config')
            .select()
            .limit(1)
            .maybeSingle();
        if (res != null) {
          debugPrint('[HotelConfigStorage] Loaded business config from Supabase cloud.');
          return {
            'businessName': res['business_name'],
            'tagline': res['tagline'],
            'address': res['address'],
            'city': res['city'],
            'state': res['state'],
            'phone': res['phone'],
            'email': res['email'],
            'gstin': res['gstin'],
            'currency': res['currency'],
            'licenseKey': res['license_key'],
            'licenseType': res['license_type'],
            'expiryDate': res['expiry_date'],
            'contactPerson': res['contact_person'],
            'enableRooms': res['enable_rooms'],
            'enablePos': res['enable_pos'],
            'enableHousekeeping': res['enable_housekeeping'],
            'enableCrs': res['enable_crs'],
            'enableBanquet': res['enable_banquet'],
            'enableCustomerApp': res['enable_customer_app'],
            'roomGst': (res['room_gst'] as num?)?.toDouble() ?? 12.0,
            'foodGst': (res['food_gst'] as num?)?.toDouble() ?? 5.0,
            'logoUrl': res['logo_url'],
          };
        }
      } catch (e) {
        debugPrint('[HotelConfigStorage] Supabase loadConfig error: $e');
      }
    }
    return null;
  }

  static Future<void> saveAccountingData({
    required List<Map<String, dynamic>> purchases,
    required List<Map<String, dynamic>> expenses,
  }) async {
    // 1. Direct Online Supabase Cloud Sync
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      try {
        final client = SupabaseConfig.client!;
        for (final p in purchases) {
          await client.from('purchases').upsert({
            'id': p['id'],
            'branch_id': p['branchId'] ?? 'branch-mum-01',
            'invoice_number': p['invoiceNumber'] ?? 'INV',
            'vendor_name': p['vendorName'] ?? 'Vendor',
            'department': p['department'] ?? 'kitchen',
            'items': p['items'] ?? [],
            'subtotal': p['subtotal'] ?? 0.0,
            'tax_amount': p['taxAmount'] ?? 0.0,
            'net_amount': p['netAmount'] ?? 0.0,
            'payment_status': p['paymentStatus'] ?? 'Paid',
          });
        }
        for (final e in expenses) {
          await client.from('expenses').upsert({
            'id': e['id'],
            'branch_id': e['branchId'] ?? 'branch-mum-01',
            'category': e['category'] ?? 'Operations',
            'description': e['description'] ?? 'Expense',
            'amount': e['amount'] ?? 0.0,
            'tax_amount': e['taxAmount'] ?? 0.0,
            'net_amount': e['netAmount'] ?? 0.0,
            'payment_mode': e['paymentMode'] ?? 'Cash',
          });
        }
        debugPrint('[HotelConfigStorage] Synced accounting entries directly to Supabase cloud.');
      } catch (e) {
        debugPrint('[HotelConfigStorage] Supabase accounting save error: $e');
      }
    }
  }

  static Future<Map<String, dynamic>?> loadAccountingData() async {
    // 1. Primary Source of Truth: Live Online Supabase Cloud
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      try {
        final client = SupabaseConfig.client!;
        final pData = await client.from('purchases').select();
        final eData = await client.from('expenses').select();
        if (pData.isNotEmpty || eData.isNotEmpty) {
          debugPrint('[HotelConfigStorage] Loaded accounting data from Supabase cloud.');
          return {
            'purchases': pData.map((row) => {
              'id': row['id'],
              'branchId': row['branch_id'],
              'invoiceNumber': row['invoice_number'],
              'vendorName': row['vendor_name'],
              'vendorGstin': row['vendor_gstin'],
              'vendorPhone': row['vendor_phone'],
              'purchaseDate': row['purchase_date'] ?? DateTime.now().toIso8601String(),
              'department': row['department'],
              'paymentStatus': row['payment_status'],
              'paymentMode': row['payment_mode'] ?? 'Bank Transfer',
              'subtotal': (row['subtotal'] as num?)?.toDouble() ?? 0.0,
              'taxAmount': (row['tax_amount'] as num?)?.toDouble() ?? 0.0,
              'netAmount': (row['net_amount'] as num?)?.toDouble() ?? 0.0,
              'items': row['items'] ?? [],
            }).toList(),
            'expenses': eData.map((row) => {
              'id': row['id'],
              'branchId': row['branch_id'],
              'voucherNumber': row['voucher_number'] ?? 'EXP',
              'category': row['category'],
              'description': row['description'],
              'expenseDate': row['expense_date'] ?? DateTime.now().toIso8601String(),
              'department': row['department'] ?? 'Operations',
              'paymentMode': row['payment_mode'] ?? 'Cash',
              'amount': (row['amount'] as num?)?.toDouble() ?? 0.0,
              'taxAmount': (row['tax_amount'] as num?)?.toDouble() ?? 0.0,
              'netAmount': (row['net_amount'] as num?)?.toDouble() ?? 0.0,
              'paidTo': row['paid_to'] ?? '',
              'recordedBy': row['recorded_by'] ?? 'Staff',
            }).toList(),
          };
        }
      } catch (e) {
        debugPrint('[HotelConfigStorage] Supabase accounting load error: $e');
      }
    }
    return null;
  }

  // ── Password Vault & Security Encryption ──
  static String _encryptSecret(String plain) {
    if (plain.isEmpty) return plain;
    const salt = 'HotelPro_Vault_Salt_2026_@_Security_Shield';
    final bytes = utf8.encode(plain);
    final saltBytes = utf8.encode(salt);
    final encrypted = List<int>.generate(bytes.length, (i) => bytes[i] ^ saltBytes[i % saltBytes.length]);
    return 'ENC::${base64Encode(encrypted)}';
  }

  static String _decryptSecret(String stored) {
    if (!stored.startsWith('ENC::')) {
      return stored; // Backward compatibility with legacy unencrypted passwords
    }
    try {
      final base64Part = stored.substring(5);
      const salt = 'HotelPro_Vault_Salt_2026_@_Security_Shield';
      final encrypted = base64Decode(base64Part);
      final saltBytes = utf8.encode(salt);
      final decrypted = List<int>.generate(encrypted.length, (i) => encrypted[i] ^ saltBytes[i % saltBytes.length]);
      return utf8.decode(decrypted);
    } catch (_) {
      return stored;
    }
  }

  // ── Saved Mobile Staff & Customer Login Credentials ──────────────────────
  static const String _credentialsFileName = 'hotelpro_saved_credentials.json';

  static Future<void> saveSavedCredentials(
    String roleKey, {
    required String userId,
    required String password,
    required bool remember,
  }) async {
    try {
      final file = await _getFile(_credentialsFileName);
      Map<String, dynamic> all = {};
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          all = jsonDecode(content) as Map<String, dynamic>;
        }
      }
      if (remember) {
        all[roleKey] = {
          'userId': userId,
          'password': _encryptSecret(password),
          'remember': true,
          'savedAt': DateTime.now().toIso8601String(),
        };
      } else {
        all.remove(roleKey);
      }
      await file.writeAsString(jsonEncode(all));
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error saving credentials: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadSavedCredentials(String roleKey) async {
    try {
      final file = await _getFile(_credentialsFileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final all = jsonDecode(content) as Map<String, dynamic>;
          if (all.containsKey(roleKey)) {
            final data = Map<String, dynamic>.from(all[roleKey] as Map);
            if (data.containsKey('password')) {
              data['password'] = _decryptSecret(data['password']?.toString() ?? '');
            }
            return data;
          }
        }
      }
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error loading credentials: $e');
    }
    return null;
  }

  // ── Cryptographic LAN Sync Security Token ───────────────────────────────
  static const String _syncSecurityFileName = 'hotelpro_sync_security.json';

  static Future<String> getOrCreateSyncToken() async {
    try {
      final file = await _getFile(_syncSecurityFileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          final token = data['token'] as String?;
          if (token != null && token.isNotEmpty) return token;
        }
      }
      final rand = Random.secure();
      final bytes = List<int>.generate(24, (_) => rand.nextInt(256));
      final newToken = 'HP-SEC-${base64UrlEncode(bytes).replaceAll('=', '')}';
      await file.writeAsString(jsonEncode({
        'token': newToken,
        'createdAt': DateTime.now().toIso8601String(),
      }));
      return newToken;
    } catch (e) {
      return 'HP-SEC-HOTELPRO-ENTERPRISE-TOKEN';
    }
  }

  static Future<void> savePairedSyncToken(String token) async {
    try {
      final file = await _getFile(_syncSecurityFileName);
      await file.writeAsString(jsonEncode({
        'token': token.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error saving paired sync token: $e');
    }
  }

  // ── Saved Windows ERP Server Host (IP Address) ───────────────────────────
  static const String _serverHostFileName = 'hotelpro_server_host.json';

  static Future<void> saveServerHost(String host) async {
    try {
      final file = await _getFile(_serverHostFileName);
      await file.writeAsString(jsonEncode({'host': host.trim()}));
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error saving server host: $e');
    }
  }

  static Future<String?> loadServerHost() async {
    try {
      final file = await _getFile(_serverHostFileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          return data['host'] as String?;
        }
      }
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error loading server host: $e');
    }
    return null;
  }

  // ── Saved Aggregator Channels (Zomato, Swiggy, ONDC, etc.) ─────────────
  static const String _aggregatorChannelsFileName = 'hotelpro_aggregator_channels.json';

  static Future<void> saveAggregatorChannels(List<Map<String, dynamic>> channelList) async {
    try {
      final file = await _getFile(_aggregatorChannelsFileName);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(channelList));
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error saving aggregator channels: $e');
    }
  }

  static Future<List<Map<String, dynamic>>?> loadAggregatorChannels() async {
    try {
      final file = await _getFile(_aggregatorChannelsFileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final list = jsonDecode(content) as List<dynamic>;
          return list.map((e) => e as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      debugPrint('[HotelConfigStorage] Error loading aggregator channels: $e');
    }
    return null;
  }
}
