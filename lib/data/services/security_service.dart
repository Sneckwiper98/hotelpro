import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// HotelPro Enterprise Security & Anti-Tamper Service
///
/// Implements zero-trust security controls across Android & Desktop:
/// 1. Native FLAG_SECURE: Prevents screenshots, screen recording, and task-switcher previews.
/// 2. Device Integrity: Root detection & unauthorized environment detection.
/// 3. Anti-Tamper Digital Signatures: SHA-256 HMAC cryptographic checksums for invoices & transactions.
/// 4. PII Redaction: Masking Aadhaar, PAN, phone numbers, and financial accounts.
/// 5. Input Sanitization: Protection against SQL injection, XSS, and parameter pollution.
class SecurityService {
  static const MethodChannel _nativeChannel = MethodChannel('com.isecuresystem.hotelpro/installer');
  static const String _appIntegritySalt = 'HOTELPRO_SECURE_VAULT_2026_HMAC_KEY';

  static bool _screenProtectionActive = false;
  static bool get isScreenProtectionActive => _screenProtectionActive;

  /// Enables Android FLAG_SECURE to prevent screenshots, screen recording,
  /// and task-switcher previews of sensitive customer data and payments.
  static Future<bool> enableScreenProtection() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final success = await _nativeChannel.invokeMethod<bool>('setSecureScreen', {'enabled': true});
      _screenProtectionActive = success ?? true;
      return _screenProtectionActive;
    } catch (e) {
      debugPrint('[SecurityService] Error enabling screen protection: $e');
      return false;
    }
  }

  /// Disables Android FLAG_SECURE when returning to non-sensitive screens.
  static Future<bool> disableScreenProtection() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final success = await _nativeChannel.invokeMethod<bool>('setSecureScreen', {'enabled': false});
      _screenProtectionActive = !(success ?? true);
      return true;
    } catch (e) {
      debugPrint('[SecurityService] Error disabling screen protection: $e');
      return false;
    }
  }

  /// Checks if the host device has been compromised (rooted, su binaries, test-keys).
  static Future<bool> isDeviceRootedOrCompromised() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final isRooted = await _nativeChannel.invokeMethod<bool>('isDeviceRooted');
      return isRooted ?? false;
    } catch (e) {
      debugPrint('[SecurityService] Error checking device root status: $e');
      return false;
    }
  }

  /// Generates a cryptographic SHA-256 digital signature for an invoice, payment, or audit log.
  /// Prevents offline database tampering or unauthorized record modifications.
  static String generateTamperProofHash(String payload) {
    final keyBytes = utf8.encode(_appIntegritySalt);
    final dataBytes = utf8.encode(payload);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    return digest.toString();
  }

  /// Verifies whether the record payload matches its cryptographic signature.
  static bool verifyTamperProofHash(String payload, String expectedHash) {
    if (expectedHash.trim().isEmpty) return false;
    final computed = generateTamperProofHash(payload);
    return computed.toLowerCase() == expectedHash.toLowerCase().trim();
  }

  /// Generates a standard SHA-256 hash (e.g. for API keys or voucher hashes).
  static String sha256Hex(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Masks Indian 12-digit Aadhaar number per UIDAI privacy standards: `XXXX-XXXX-1234`
  static String maskAadhaar(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return 'XXXX-XXXX-XXXX';
    final last4 = digits.substring(digits.length - 4);
    return 'XXXX-XXXX-$last4';
  }

  /// Masks Indian 10-character PAN Card: `ABCDE****F`
  static String maskPan(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final clean = raw.trim().toUpperCase();
    if (clean.length != 10) return clean;
    return '${clean.substring(0, 5)}****${clean.substring(9)}';
  }

  /// Masks Indian 10-digit mobile number: `+91 ***** 12345`
  static String maskPhoneNumber(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) return '*****';
    final last5 = digits.substring(digits.length - 5);
    return '+91 ***** $last5';
  }

  /// Masks bank account number: `******1234`
  static String maskBankAccount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final digits = raw.trim();
    if (digits.length <= 4) return '****';
    final last4 = digits.substring(digits.length - 4);
    return '${'*' * (digits.length - 4)}$last4';
  }

  /// Sanitizes SQL strings to prevent basic SQL injection in local search filters
  static String sanitizeSqlInput(String input) {
    return input
        .replaceAll("'", "''")
        .replaceAll(';', '')
        .replaceAll('--', '')
        .replaceAll('/*', '')
        .replaceAll('*/', '');
  }

  /// Sanitizes HTML / script input to prevent XSS in customer order notes or guest special requests
  static String sanitizeHtmlInput(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }
}
