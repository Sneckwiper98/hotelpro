import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Luxury Color Palette
  static const Color obsidianBg = Color(0xFF0C0F14);
  static const Color slateCard = Color(0xFF141923);
  static const Color slateCardElevated = Color(0xFF1B2230);
  static const Color slateBorder = Color(0xFF242C3D);
  
  // Metallic Golds
  static const Color imperialGold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color goldDark = Color(0xFFA68018);
  static const Color champagneAccent = Color(0xFFEAD7B2);

  // Status Colors (Rooms & Operations)
  static const Color statusClean = Color(0xFF10B981);      // Emerald Green
  static const Color statusInspected = Color(0xFF059669);  // Deep Emerald
  static const Color statusOccupied = Color(0xFFEF4444);   // Crimson Red
  static const Color statusDirty = Color(0xFFF59E0B);      // Amber Orange
  static const Color statusCleaning = Color(0xFF3B82F6);   // Royal Blue
  static const Color statusReserved = Color(0xFF8B5CF6);   // Amethyst Purple
  static const Color statusOutOfOrder = Color(0xFF6B7280); // Titanium Grey

  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textGold = Color(0xFFF5E6A3);

  static ThemeData get luxuryDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianBg,
      primaryColor: imperialGold,
      colorScheme: const ColorScheme.dark(
        primary: imperialGold,
        onPrimary: Color(0xFF1E1400),
        secondary: champagneAccent,
        surface: slateCard,
        onSurface: textPrimary,
        error: statusOccupied,
        outline: slateBorder,
      ),
      cardTheme: CardThemeData(
        color: slateCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: slateBorder, width: 1),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          headlineLarge: GoogleFonts.cinzel(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          headlineMedium: GoogleFonts.cinzel(
            color: textGold,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          titleLarge: GoogleFonts.inter(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          bodyLarge: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 14,
          ),
          bodyMedium: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 13,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: slateBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF10141D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: slateBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: slateBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: imperialGold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: imperialGold,
          foregroundColor: const Color(0xFF141005),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
