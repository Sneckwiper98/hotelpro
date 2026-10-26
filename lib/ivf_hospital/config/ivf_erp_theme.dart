import 'package:flutter/material.dart';

/// Classic Win32 ERP Theme for IVFPro 360 Enterprise
/// Developed & Technology Partner: iSecure System Pvt. Ltd.
class IvfErpTheme {
  // Brand Header & Accents
  static const Color primaryNavy = Color(0xFF0B3C5D);
  static const Color headerGradientStart = Color(0xFF0A314D);
  static const Color headerGradientEnd = Color(0xFF1B4F72);
  static const Color clinicalTeal = Color(0xFF0E86D4);
  static const Color medicalEmerald = Color(0xFF1E8449);
  static const Color alertRuby = Color(0xFFC0392B);
  static const Color warningAmber = Color(0xFFD4AC0D);
  static const Color ivfPurple = Color(0xFF6C3483);
  static const Color babyBlue = Color(0xFF2980B9);
  static const Color pinkMaternity = Color(0xFFD81B60);

  // Win32 Classic System Colors
  static const Color menuBarBg = Color(0xFFECE9D8);
  static const Color toolbarBg = Color(0xFFF4F6F7);
  static const Color dialogBg = Color(0xFFF0F2F5);
  static const Color windowBg = Color(0xFFE5E8EB);
  static const Color borderDark = Color(0xFF7F8C8D);
  static const Color borderLight = Color(0xFFBDC3C7);
  static const Color textMain = Color(0xFF2C3E50);
  static const Color textMuted = Color(0xFF566573);

  // DataGrid Row Colors
  static const Color gridHeaderBg = Color(0xFFD4E6F1);
  static const Color gridRowEven = Colors.white;
  static const Color gridRowOdd = Color(0xFFF8FBFC);
  static const Color gridRowSelected = Color(0xFFD6EAF8);

  // Text Styles
  static const TextStyle menuStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textMain,
  );

  static const TextStyle toolbarBtnStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.bold,
    color: textMain,
  );

  static const TextStyle gridHeaderStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.bold,
    color: primaryNavy,
    letterSpacing: 0.2,
  );

  static const TextStyle gridCell = TextStyle(
    fontSize: 11,
    color: textMain,
  );

  static const TextStyle statusBarStyle = TextStyle(
    fontSize: 10.5,
    color: textMuted,
    fontWeight: FontWeight.w500,
  );
}
