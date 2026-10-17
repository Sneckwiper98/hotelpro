import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Classic Windows Desktop ERP Theme (WinForms / SAP Business One / Tally Style)
/// High-density spreadsheet typography, crisp 1px borders, deep navy headers,
/// and light desktop business surfaces.
class ClassicErpTheme {
  // Classic Desktop Neutral Palettes
  static const Color desktopBg = Color(0xFFD6DBDF);          // Windows Classic Canvas
  static const Color windowBg = Color(0xFFFFFFFF);           // Sub-Window Interior
  static const Color panelBg = Color(0xFFEAECEE);            // Filter and Form Panels
  static const Color dialogBg = Color(0xFFEAECEE);           // Modal Dialogs & Property Pages
  static const Color menuBarBg = Color(0xFFF2F4F4);          // Top Menu Bar
  static const Color toolbarBg = Color(0xFFF8F9F9);          // Quick-Action Ribbon
  static const Color borderLight = Color(0xFFBDC3C7);        // Panel / Grid borders
  static const Color borderDark = Color(0xFF7F8C8D);         // Inset field borders

  // MDI & Grid Primary Colors (Matching reference photo)
  static const Color mdiHeaderBg = Color(0xFF2C3E50);        // Deep Navy Window Bar
  static const Color mdiHeaderActive = Color(0xFF1B4F72);    // Active Sub-window Blue
  static const Color gridHeaderBg = Color(0xFF1F3A52);       // Table Column Header Navy
  static const Color gridHeaderBorder = Color(0xFF152838);   // Header Dividers
  static const Color gridRowEven = Color(0xFFFFFFFF);        // White Grid Row
  static const Color gridRowOdd = Color(0xFFF4F6F7);         // Light Zebra Row
  static const Color gridSelectedRow = Color(0xFFD4E6F1);    // Selected Row Soft Blue
  static const Color gridSelectedBorder = Color(0xFF2980B9); // Selected Row Border

  // Button & Accent Colors
  static const Color buttonBg = Color(0xFFEBEDEF);
  static const Color buttonBorder = Color(0xFFA6ACAF);
  static const Color accentGreen = Color(0xFF27AE60);        // Status OK / Clean
  static const Color accentRed = Color(0xFFC0392B);          // Urgent / Occupied
  static const Color accentAmber = Color(0xFFD35400);        // Attention / Dirty
  static const Color excelGreen = Color(0xFF1E7145);         // Excel export button
  static const Color titleGold = Color(0xFFF1C40F);          // Golden title bar icon accent
  static const Color navyHeader = Color(0xFF1B4F72);         // Win32 dialog header navy
  static const Color textMain = Color(0xFF1C2833);           // Dark Charcoal Text
  static const Color textMuted = Color(0xFF566573);          // Secondary Text
  static const Color statusBarBg = Color(0xFFD5D8DC);        // Classic Bottom Status

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: false, // Classic Windows desktop aesthetics look best with crisp Material 2/Win32 geometry
      brightness: Brightness.light,
      scaffoldBackgroundColor: desktopBg,
      primaryColor: mdiHeaderActive,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textMain, fontSize: 12),
        bodySmall: TextStyle(color: textMuted, fontSize: 11),
        titleSmall: TextStyle(color: textMain, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderDark, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderLight, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: mdiHeaderActive, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
