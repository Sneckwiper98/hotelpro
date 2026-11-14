import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Enterprise Windows Desktop Theme
/// Blends high-density Win32/MDI productivity with clean, modern Windows 11 / Fluent styling:
/// - Crisp typography with tabular numbers for perfect financial alignment
/// - Sophisticated slate & navy enterprise palette
/// - Tactile interactive states, soft depth shadows, and refined border treatments
class ClassicErpTheme {
  // Modern Desktop Neutral Palettes (Sophisticated Cool Slates)
  static const Color desktopBg = Color(0xFFE6ECF2);          // Modern Cool Slate Desktop Canvas
  static const Color windowBg = Color(0xFFFFFFFF);           // Sub-Window Interior
  static const Color panelBg = Color(0xFFF1F5F9);            // Filter and Form Panels
  static const Color dialogBg = Color(0xFFF8FAFC);           // Modal Dialogs & Property Pages
  static const Color menuBarBg = Color(0xFFF8FAFC);          // Top Menu Bar
  static const Color toolbarBg = Color(0xFFFFFFFF);          // Quick-Action Ribbon
  static const Color borderLight = Color(0xFFCBD5E1);        // Panel / Grid borders
  static const Color borderDark = Color(0xFF94A3B8);         // Inset field borders

  // MDI & Grid Primary Colors (Rich Deep Navy & Enterprise Slate)
  static const Color mdiHeaderBg = Color(0xFF1E293B);        // Deep Slate Window Bar
  static const Color mdiHeaderActive = Color(0xFF0F3A60);    // Active Sub-window Enterprise Blue
  static const Color gridHeaderBg = Color(0xFF0F2C4C);       // Table Column Header Navy
  static const Color gridHeaderBorder = Color(0xFF091E34);   // Header Dividers
  static const Color gridRowEven = Color(0xFFFFFFFF);        // White Grid Row
  static const Color gridRowOdd = Color(0xFFF8FAFC);         // Clean Light Zebra Row
  static const Color gridSelectedRow = Color(0xFFE0F2FE);    // Selected Row Soft Sky Blue
  static const Color gridSelectedBorder = Color(0xFF0284C7); // Selected Row Border

  // Button & Accent Colors
  static const Color buttonBg = Color(0xFFF1F5F9);
  static const Color buttonBorder = Color(0xFFCBD5E1);
  static const Color accentGreen = Color(0xFF10B981);        // Status OK / Clean
  static const Color accentRed = Color(0xFFEF4444);          // Urgent / Occupied
  static const Color accentAmber = Color(0xFFF59E0B);        // Attention / Dirty
  static const Color excelGreen = Color(0xFF16A34A);         // Excel export button
  static const Color titleGold = Color(0xFFF59E0B);          // Golden title bar icon accent
  static const Color navyHeader = Color(0xFF0F3A60);         // Dialog header navy
  static const Color textMain = Color(0xFF0F172A);           // Deep Charcoal Text (Slate 900)
  static const Color textMuted = Color(0xFF64748B);          // Secondary Text (Slate 500)
  static const Color statusBarBg = Color(0xFFE2E8F0);        // Modern Bottom Status Bar

  // Modern UI Shadows & Geometry
  static final BorderRadius radiusXs = BorderRadius.circular(2);
  static final BorderRadius radiusSm = BorderRadius.circular(4);
  static final BorderRadius radiusMd = BorderRadius.circular(6);
  static final BorderRadius radiusLg = BorderRadius.circular(8);
  static final BorderRadius radiusFull = BorderRadius.circular(999);

  static const List<BoxShadow> windowShadowActive = [
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 8), blurRadius: 20, spreadRadius: -2),
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 3), blurRadius: 8, spreadRadius: 0),
  ];

  static const List<BoxShadow> windowShadowInactive = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 10, spreadRadius: -1),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 3),
  ];

  static ThemeData get themeData {
    final baseFont = GoogleFonts.inter();

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      scaffoldBackgroundColor: desktopBg,
      primaryColor: mdiHeaderActive,
      fontFamily: baseFont.fontFamily,
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: textMain,
          fontSize: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 11,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleSmall: TextStyle(
          color: textMain,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: borderDark, width: 1),
          borderRadius: radiusSm,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: borderLight, width: 1),
          borderRadius: radiusSm,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: mdiHeaderActive, width: 1.5),
          borderRadius: radiusSm,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: radiusSm,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
        waitDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
