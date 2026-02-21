import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens extracted from Stitch reference designs.
class AppColors {
  // Backgrounds
  static const background = Color(0xFF0E0E12);
  static const sidebar = Color(0xFF16161C);
  static const surface = Color(0xFF1C1C24);
  static const surfaceLight = Color(0xFF26262E);
  static const border = Color(0xFF2A2A35);
  static const borderDark = Color(0xFF2A2A2A);

  // Accent palette
  static const primary = Color(0xFF33C758);
  static const accentBlue = Color(0xFF0A84FF);
  static const accentPurple = Color(0xFFBF5AF2);
  static const accentOrange = Color(0xFFFF9F0A);
  static const accentRed = Color(0xFFFF453A);
  static const accentTeal = Color(0xFF64D2FF);
  static const accentYellow = Color(0xFFFFD60A);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFF636366);
  static const textSlate400 = Color(0xFF94A3B8); // slate-400
  static const textSlate500 = Color(0xFF64748B); // slate-500

  // Gradients
  static const List<Color> primaryGradient = [primary, Color(0xFF059669)];
  static const List<Color> dangerGradient = [accentRed, Color(0xFFDC2626)];
  static const List<Color> statusGradient = [primary, accentPurple];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accentPurple,
        surface: AppColors.surface,
        error: AppColors.accentRed,
      ),
      dividerColor: AppColors.border,
      cardColor: AppColors.surface,
    );
  }
}
