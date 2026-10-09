import 'package:flutter/material.dart';

/// Xenova Health brand color palette: Porcelain Clinical (Medical-Grade & High Contrast).
///
/// Palette 1 Specification:
/// - Canvas Background: #F8FAFC
/// - Card Surface: #FFFFFF (Border: #E2E8F0)
/// - Text: Primary #0F172A | Secondary #475569 | Muted #94A3B8
/// - AI Vitality / Score: #6366F1
/// - Nutrition / Hero: #059669
/// - Protein: #E11D48
/// - Carbohydrates: #D97706
/// - Healthy Fats: #0D9488
/// - Fasting: #EA580C
/// - Hydration: #0284C7
abstract final class AppColors {
  // ─── Primary - Nutrition / Hero (Vibrant Clinical Emerald) ───
  static const Color primary = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF065F46);
  static const Color primarySurface = Color(0xFFECFDF5);
  static const Color primaryContainer = Color(0xFF059669);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // ─── AI Vitality / Health Score (Indigo Medical Grade) ───
  static const Color aiVitality = Color(0xFF6366F1);
  static const Color aiVitalityDark = Color(0xFF4F46E5);
  static const Color aiVitalityLight = Color(0xFF818CF8);
  static const Color aiVitalitySurface = Color(0xFFEEF2FF);

  // ─── Secondary - Fasting / Milestones (Vibrant Coral Amber) ───
  static const Color secondary = Color(0xFFEA580C);
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFC2410C);
  static const Color secondarySurface = Color(0xFFFFF7ED);
  static const Color fasting = Color(0xFFEA580C);

  // ─── Accent / Tertiary - AI Indigo ───
  static const Color accent = Color(0xFF6366F1);
  static const Color accentLight = Color(0xFF818CF8);
  static const Color accentDark = Color(0xFF4338CA);
  static const Color accentSurface = Color(0xFFEEF2FF);

  // ─── Health & Metric Accents ───
  static const Color hydration = Color(0xFF0284C7); // Clinical Sky Blue
  static const Color lipids = Color(0xFF0D9488); // Healthy Fats Teal
  static const Color carbs = Color(0xFFD97706); // Carbohydrates Amber
  static const Color protein = Color(0xFFE11D48); // Protein Crimson Rose

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFE11D48);
  static const Color errorLight = Color(0xFFFFE4E6);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // ─── Neutral - Light Mode (Porcelain Clinical) ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFC); // Canvas Background #F8FAFC
  static const Color surfaceLight = Color(0xFFFFFFFF); // Card Surface #FFFFFF
  static const Color surfaceContainerLight = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color elevatedLight = Color(0xFFF8FAFC);
  static const Color dividerLight = Color(0xFFE2E8F0); // Border #E2E8F0
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Text Primary #0F172A
  static const Color textSecondaryLight = Color(0xFF475569); // Text Secondary #475569
  static const Color textTertiaryLight = Color(0xFF94A3B8); // Text Muted #94A3B8
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  // ─── Neutral - Dark Mode (Deep Obsidian - Pure White Text) ───
  static const Color black = Color(0xFF000000);
  static const Color backgroundDark = Color(0xFF121A15);
  static const Color surfaceDark = Color(0xFF1A241E);
  static const Color surfaceContainerDark = Color(0xFF232E27);
  static const Color cardDark = Color(0xFF1A241E);
  static const Color elevatedDark = Color(0xFF232E27);
  static const Color dividerDark = Color(0xFF2D3A31);
  static const Color borderDark = Color(0xFF2D3A31);
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondaryDark = Color(0xFFFFFFFF); // Pure White
  static const Color textTertiaryDark = Color(0xFFEDEDED); // Near White
  static const Color textDisabledDark = Color(0xFFB5B5B5);

  // ─── Gradient Presets ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient aiVitalityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
  );

  static const LinearGradient terracottaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
  );

  static const LinearGradient fastingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A241E), Color(0xFF121A15)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
  );

  // ─── Chart Colors (Porcelain Clinical) ───
  static const List<Color> chartPalette = [
    Color(0xFF059669), // Emerald
    Color(0xFF6366F1), // Indigo AI
    Color(0xFFEA580C), // Orange Fasting
    Color(0xFF0284C7), // Blue Hydration
    Color(0xFFE11D48), // Rose Protein
    Color(0xFFD97706), // Amber Carbs
    Color(0xFF0D9488), // Teal Fats
  ];
}
