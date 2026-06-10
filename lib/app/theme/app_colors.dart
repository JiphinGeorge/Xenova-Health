import 'package:flutter/material.dart';

/// Xenova Health brand color palette.
///
/// Primary: Teal (#14B8A6) — Health & Trust
/// Secondary: Emerald (#10B981) — Growth & Progress
/// Accent: Deep Blue (#1E40AF) — Technology & Precision
abstract final class AppColors {
  // ─── Primary Teal ───
  static const Color primary = Color(0xFF14B8A6);
  static const Color primaryLight = Color(0xFF5EEAD4);
  static const Color primaryDark = Color(0xFF0D9488);
  static const Color primarySurface = Color(0xFFCCFBF1);

  // ─── Secondary Emerald ───
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF6EE7B7);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondarySurface = Color(0xFFD1FAE5);

  // ─── Accent Deep Blue ───
  static const Color accent = Color(0xFF1E40AF);
  static const Color accentLight = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFF1E3A8A);
  static const Color accentSurface = Color(0xFFDBEAFE);

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFBBF7D0);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─── Neutral - Light Mode ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFD1D5DB);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textDisabledLight = Color(0xFFD1D5DB);

  // ─── Neutral - Dark Mode ───
  static const Color black = Color(0xFF000000);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color elevatedDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF475569);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);
  static const Color textDisabledDark = Color(0xFF475569);

  // ─── Gradient Presets ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
  );

  // ─── Chart Colors ───
  static const List<Color> chartPalette = [
    primary,
    secondary,
    accent,
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];
}
