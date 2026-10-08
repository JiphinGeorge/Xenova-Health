import 'package:flutter/material.dart';

/// Xenova Health brand color palette: Warm Organic Wellness.
///
/// Design Movement: Organic Warmth & Soft Editorial.
/// Primary: Deep Botanical Moss (#1B382B) — Grounding vitality & stability
/// Secondary: Terracotta Clay (#C86D51) — Mindful milestones & streaks
/// Tertiary: Warm Amber (#D9822B) — Fasting milestones & energy
/// Accents: Muted River Stone (#5B8288) for Hydration, Sage Olive (#4A6B53) for Lipids
abstract final class AppColors {
  // ─── Primary - Deep Botanical Moss ───
  static const Color primary = Color(0xFF1B382B);
  static const Color primaryLight = Color(0xFFADCEBC);
  static const Color primaryDark = Color(0xFF042217);
  static const Color primarySurface = Color(0xFFC9EAD7);
  static const Color primaryContainer = Color(0xFF1B382B);
  static const Color onPrimaryContainer = Color(0xFF82A291);

  // ─── Secondary - Terracotta Clay ───
  static const Color secondary = Color(0xFFC86D51);
  static const Color secondaryLight = Color(0xFFFE997A);
  static const Color secondaryDark = Color(0xFF97472E);
  static const Color secondarySurface = Color(0xFFFFDBD0);

  // ─── Accent / Tertiary - Warm Amber ───
  static const Color accent = Color(0xFFD9822B);
  static const Color accentLight = Color(0xFFFFB77A);
  static const Color accentDark = Color(0xFF4F2900);
  static const Color accentSurface = Color(0xFFFFDCC2);

  // ─── Health & Metric Accents ───
  static const Color hydration = Color(0xFF5B8288); // Muted River Stone
  static const Color lipids = Color(0xFF4A6B53); // Sage Olive
  static const Color carbs = Color(0xFFD9822B); // Warm Amber
  static const Color protein = Color(0xFFC86D51); // Terracotta Clay

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF2E6B48);
  static const Color successLight = Color(0xFFD1E7DD);
  static const Color warning = Color(0xFFD9822B);
  static const Color warningLight = Color(0xFFFFE8D1);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorLight = Color(0xFFFFDAD6);
  static const Color info = Color(0xFF5B8288);
  static const Color infoLight = Color(0xFFE0ECEE);

  // ─── Neutral - Light Mode (Warm Parchment & Stone) ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFFAF7F2); // Warm Parchment
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure Stone White
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color elevatedLight = Color(0xFFF3EFEA); // Warm Oat
  static const Color dividerLight = Color(0xFFECE6DC); // Light Clay Border
  static const Color borderLight = Color(0xFFECE6DC);
  static const Color textPrimaryLight = Color(0xFF1C1C19); // Charcoal Mineral
  static const Color textSecondaryLight = Color(0xFF6E6B65); // Faded Bark
  static const Color textTertiaryLight = Color(0xFF9C978F);
  static const Color textDisabledLight = Color(0xFFC2C8C2);

  // ─── Neutral - Dark Mode (Deep Botanical Obsidian) ───
  static const Color black = Color(0xFF000000);
  static const Color backgroundDark = Color(0xFF121A15); // Deep Moss Charcoal
  static const Color surfaceDark = Color(0xFF1A241E); // Elevated Deep Moss
  static const Color cardDark = Color(0xFF1A241E);
  static const Color elevatedDark = Color(0xFF232E27);
  static const Color dividerDark = Color(0xFF2D3A31);
  static const Color borderDark = Color(0xFF2D3A31);
  static const Color textPrimaryDark = Color(0xFFF3F0EB); // Warm Ivory
  static const Color textSecondaryDark = Color(0xFF9EA49E);
  static const Color textTertiaryDark = Color(0xFF6B736C);
  static const Color textDisabledDark = Color(0xFF47554E);

  // ─── Gradient Presets ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B382B), Color(0xFF304D3F)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9822B), Color(0xFFFFB77A)],
  );

  static const LinearGradient terracottaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC86D51), Color(0xFFFE997A)],
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A241E), Color(0xFF121A15)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFECE6DC), Color(0xFFF3EFEA), Color(0xFFECE6DC)],
  );

  // ─── Chart Colors (Warm Organic) ───
  static const List<Color> chartPalette = [
    Color(0xFF1B382B), // Deep Moss
    Color(0xFFC86D51), // Terracotta
    Color(0xFFD9822B), // Warm Amber
    Color(0xFF5B8288), // River Stone
    Color(0xFF4A6B53), // Sage Olive
    Color(0xFF82A291), // Soft Mint
    Color(0xFF97472E), // Burnt Clay
    Color(0xFFBA1A1A), // Rust Red
  ];
}
