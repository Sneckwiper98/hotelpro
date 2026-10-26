import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hospital_config_model.dart';

/// Supabase Cloud Integration & Real-time Connectivity Service
class SupabaseService {
  static const String _prefKeyConfig = 'ivfpro_hospital_config';
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  HospitalConfigModel _config = HospitalConfigModel();
  bool _isConnected = false;

  HospitalConfigModel get config => _config;
  bool get isConnected => _isConnected;

  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKeyConfig);
      if (savedJson != null && savedJson.isNotEmpty) {
        _config = HospitalConfigModel.fromJson(savedJson);
        if (_config.isCloudSyncEnabled && _config.supabaseUrl.isNotEmpty) {
          await testConnection(_config.supabaseUrl, _config.supabaseAnonKey);
        }
      }
    } catch (e) {
      debugPrint('Error loading hospital config: $e');
    }
  }

  Future<void> saveConfig(HospitalConfigModel newConfig) async {
    _config = newConfig;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyConfig, newConfig.toJson());
      if (_config.isCloudSyncEnabled && _config.supabaseUrl.isNotEmpty) {
        await testConnection(_config.supabaseUrl, _config.supabaseAnonKey);
      }
    } catch (e) {
      debugPrint('Error saving hospital config: $e');
    }
  }

  /// Ping Supabase REST API to test connection
  Future<bool> testConnection(String url, String anonKey) async {
    if (url.isEmpty || anonKey.isEmpty) {
      _isConnected = false;
      return false;
    }

    try {
      final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final uri = Uri.parse('$cleanUrl/rest/v1/');
      final response = await http.get(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      ).timeout(const Duration(seconds: 5));

      _isConnected = response.statusCode == 200 || response.statusCode == 404;
      return _isConnected;
    } catch (e) {
      debugPrint('Supabase connection test failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Sync record to Supabase table
  Future<bool> syncRecordToTable({
    required String tableName,
    required Map<String, dynamic> record,
  }) async {
    if (!_config.isCloudSyncEnabled || _config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      // Offline mode: successfully handled locally
      return false;
    }

    try {
      final cleanUrl = _config.supabaseUrl.endsWith('/')
          ? _config.supabaseUrl.substring(0, _config.supabaseUrl.length - 1)
          : _config.supabaseUrl;

      final uri = Uri.parse('$cleanUrl/rest/v1/$tableName');
      final response = await http.post(
        uri,
        headers: {
          'apikey': _config.supabaseAnonKey,
          'Authorization': 'Bearer ${_config.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: json.encode(record),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error syncing record to Supabase $tableName: $e');
      return false;
    }
  }
}
