import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ??
      'https://koujqdqdzklurxvbhygf.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      dotenv.env['SUPABASE_ANNON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvdWpxZHFkemtsdXJ4dmJoeWdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2NDEyMTIsImV4cCI6MjEwNjIxNzIxMn0.oejDwgrJ19TtsodUV6nC8KMR485rn_LpPUZnd3WraVQ';

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initializes Supabase gracefully. If invalid/placeholder credentials, runs in high-fidelity local engine mode.
  static Future<void> initialize() async {
    try {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('[HotelPro] .env load notice: $e');
      }

      if (supabaseUrl.contains('xyzcompany')) {
        debugPrint('[HotelPro] Supabase placeholder detected. Running in High-Fidelity Local Mock & Simulation Engine mode.');
        _isInitialized = false;
        return;
      }
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('[HotelPro] Supabase connected successfully to PostgreSQL cluster.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('[HotelPro] Supabase initialization fallback: $e');
    }
  }

  static SupabaseClient? get client {
    if (_isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }
}
