import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F1117);
  static const card       = Color(0xFF1A1D27);
  static const surface    = Color(0xFF222537);
  static const border     = Color(0xFF2A2D3E);
  static const text       = Color(0xFFE8E8F0);
  static const muted      = Color(0xFF6B7280);
  static const accent     = Color(0xFFFFB547);
  static const teal       = Color(0xFF2DD4BF);
  static const blue       = Color(0xFF60A5FA);
  static const purple     = Color(0xFFA78BFA);
  static const success    = Color(0xFF4ADE80);
  static const danger     = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.card,
      primary: AppColors.accent,
      secondary: AppColors.teal,
      error: AppColors.danger,
      onPrimary: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.muted,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      showUnselectedLabels: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 0.5),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    ),
    dividerColor: AppColors.border,
    cardColor: AppColors.card,
  );
}
