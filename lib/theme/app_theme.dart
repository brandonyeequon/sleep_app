import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F1623);
  static const cardBackground = Color(0xFF1A2332);
  static const cardBorder = Color(0xFF243042);
  static const textPrimary = Color(0xFFE8ECF1);
  static const textSecondary = Color(0xFF8A94A6);
  static const textMuted = Color(0xFF5A6478);
  static const accentTeal = Color(0xFF2DD4BF);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentRed = Color(0xFFEF4444);
  static const accentPurple = Color(0xFFA855F7);
  static const accentOrange = Color(0xFFF97316);
  static const uploadButton = Color(0xFFE8564A);
  static const sidebarActive = Color(0xFF1E293B);
  static const scoreGreen = Color(0xFF22C55E);
  static const scoreYellow = Color(0xFFEAB308);
  static const scoreRed = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.accentTeal,
        secondary: AppColors.accentBlue,
        error: AppColors.accentRed,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dividerColor: AppColors.cardBorder,
    );
  }

  static Color scoreColor(double score) {
    if (score >= 80) return AppColors.scoreGreen;
    if (score >= 60) return AppColors.scoreYellow;
    return AppColors.scoreRed;
  }

  static Color eventColor(String type) {
    switch (type) {
      case 'normalBreathing':
        return AppColors.accentTeal;
      case 'snoring':
        return AppColors.accentBlue;
      case 'pauseEvent':
        return AppColors.accentRed;
      case 'recoveryGasp':
        return AppColors.accentPurple;
      default:
        return AppColors.textMuted;
    }
  }
}
