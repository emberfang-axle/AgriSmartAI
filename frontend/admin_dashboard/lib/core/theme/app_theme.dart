import 'package:flutter/material.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
const Color kDeepGreen   = Color(0xFF0B3B1F);
const Color kWarmGold    = Color(0xFFD4A017);
const Color kLightGreen  = Color(0xFF2E7D32);
const Color kBackground  = Color(0xFFF4F6F8);
const Color kSurface     = Color(0xFFFFFFFF);
const Color kErrorRed    = Color(0xFFE53935);
const Color kWarningAmber = Color(0xFFFF6F00);
const Color kInfoBlue    = Color(0xFF1976D2);
const Color kSidebarText = Color(0xFFB2DFDB);

// ── Disease colours ───────────────────────────────────────────────────────────
const Map<String, Color> kDiseaseColors = {
  'Healthy':                  Color(0xFF2E7D32),
  'Bacterial Leaf Blight':    Color(0xFFE53935),
  'Brown Spot':               Color(0xFF795548),
  'Leaf Blast':               Color(0xFFFF6F00),
  'Sheath Blight':            Color(0xFF7B1FA2),
  'Tungro Virus':             Color(0xFFF57F17),
};

Color diseaseColor(String disease) =>
    kDiseaseColors[disease] ?? const Color(0xFF607D8B);

// ── Risk colours ──────────────────────────────────────────────────────────────
Color riskColor(String risk) {
  switch (risk.toLowerCase()) {
    case 'high':   return kErrorRed;
    case 'medium': return kWarningAmber;
    default:       return kLightGreen;
  }
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kDeepGreen,
        primary: kDeepGreen,
        secondary: kWarmGold,
        surface: kSurface,
        error: kErrorRed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: kBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: kSurface,
        foregroundColor: kDeepGreen,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: kDeepGreen, fontSize: 18,
          fontWeight: FontWeight.w700, letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: kSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8EAF0)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kDeepGreen, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kDeepGreen,
          side: const BorderSide(color: kDeepGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDeepGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(Color(0xFFF8F9FA)),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        dividerThickness: 1,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w700, color: kDeepGreen, fontSize: 13,
        ),
      ),
    );
  }
}
