import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Xenova Health typography system based on Warm Organic Wellness:
/// - Headlines, Displays & Screen Titles: Newsreader (Editorial Serif)
/// - Body, Labels, Metrics & Buttons: Plus Jakarta Sans (Modern Humanist Sans)
abstract final class AppTextStyles {
  // ─── Display (Editorial Serif - Newsreader) ───
  static TextStyle displayLarge({Color? color}) => GoogleFonts.newsreader(
    fontSize: 44,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.88,
    height: 1.18,
    color: color,
  );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.newsreader(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.54,
    height: 1.2,
    color: color,
  );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.newsreader(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    height: 1.25,
    color: color,
  );

  // ─── Headline (Editorial Serif - Newsreader) ───
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.newsreader(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.32,
    height: 1.19,
    color: color,
  );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.newsreader(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.24,
    height: 1.27,
    color: color,
  );

  static TextStyle headlineSmall({Color? color}) => GoogleFonts.newsreader(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
    color: color,
  );

  // ─── Title (Newsreader for TitleLarge, Plus Jakarta Sans for Medium/Small) ───
  static TextStyle titleLarge({Color? color}) => GoogleFonts.newsreader(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
    color: color,
  );

  static TextStyle titleMedium({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle titleSmall({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: color,
      );

  // ─── Body (Plus Jakarta Sans) ───
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
    color: color,
  );

  static TextStyle bodyMedium({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.43,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.33,
    color: color,
  );

  // ─── Label (Plus Jakarta Sans) ───
  static TextStyle labelLarge({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.43,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.33,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.27,
        color: color,
      );

  // ─── Special Styles (Plus Jakarta Sans - Tabular Figures) ───
  static TextStyle metricValue({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.11,
        color: color ?? AppColors.primary,
      );

  static TextStyle metricUnit({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.43,
        color: color ?? AppColors.textSecondaryLight,
      );

  static TextStyle chartLabel({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.2,
        color: color ?? AppColors.textTertiaryLight,
      );

  static TextStyle buttonText({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.25,
        color: color ?? AppColors.white,
      );

  /// Generates the [TextTheme] used in [ThemeData].
  static TextTheme textTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return TextTheme(
      displayLarge: displayLarge(color: primaryColor),
      displayMedium: displayMedium(color: primaryColor),
      displaySmall: displaySmall(color: primaryColor),
      headlineLarge: headlineLarge(color: primaryColor),
      headlineMedium: headlineMedium(color: primaryColor),
      headlineSmall: headlineSmall(color: primaryColor),
      titleLarge: titleLarge(color: primaryColor),
      titleMedium: titleMedium(color: primaryColor),
      titleSmall: titleSmall(color: primaryColor),
      bodyLarge: bodyLarge(color: primaryColor),
      bodyMedium: bodyMedium(color: primaryColor),
      bodySmall: bodySmall(color: secondaryColor),
      labelLarge: labelLarge(color: primaryColor),
      labelMedium: labelMedium(color: secondaryColor),
      labelSmall: labelSmall(color: secondaryColor),
    );
  }
}
