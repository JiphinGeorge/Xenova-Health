import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Xenova Health theme data generator.
///
/// Provides system-adaptive theming with full light and dark mode support.
/// Uses Material 3 design system with Xenova Health brand colors.
abstract final class AppTheme {
  /// Light theme configuration.
  static ThemeData get light => _buildTheme(Brightness.light);

  /// Dark theme configuration.
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: isDark
          ? AppColors.primaryDark
          : AppColors.primarySurface,
      onPrimaryContainer: isDark
          ? AppColors.primaryLight
          : AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      secondaryContainer: isDark
          ? AppColors.secondaryDark
          : AppColors.secondarySurface,
      onSecondaryContainer: isDark
          ? AppColors.secondaryLight
          : AppColors.secondaryDark,
      tertiary: AppColors.accent,
      onTertiary: AppColors.white,
      tertiaryContainer: isDark
          ? AppColors.accentDark
          : AppColors.accentSurface,
      onTertiaryContainer: isDark
          ? AppColors.accentLight
          : AppColors.accentDark,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: isDark ? const Color(0xFF93000A) : AppColors.errorLight,
      onErrorContainer: isDark ? AppColors.errorLight : AppColors.error,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight,
      onSurfaceVariant: isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight,
      outline: isDark ? AppColors.borderDark : AppColors.borderLight,
      outlineVariant: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      shadow: AppColors.black.withValues(alpha: isDark ? 0.3 : 0.1),
      scrim: AppColors.black.withValues(alpha: 0.5),
      inverseSurface: isDark
          ? AppColors.textPrimaryLight
          : AppColors.textPrimaryDark,
      onInverseSurface: isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight,
      inversePrimary: isDark ? AppColors.primaryLight : AppColors.primaryDark,
      surfaceTint: AppColors.primary.withValues(alpha: 0.05),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme(brightness: brightness),
      scaffoldBackgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        foregroundColor: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.titleLarge(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),

      // ─── Bottom Navigation Bar ───
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
        selectedLabelStyle: AppTextStyles.labelSmall(),
        unselectedLabelStyle: AppTextStyles.labelSmall(),
        showUnselectedLabels: true,
      ),

      // ─── Navigation Bar (Material 3) ───
      navigationBarTheme: NavigationBarThemeData(
        height: AppDimensions.bottomNavHeight,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        indicatorColor: AppColors.primarySurface,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.labelSmall(color: AppColors.primary),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            size: 24,
          );
        }),
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : AppDimensions.elevationXs,
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: isDark
              ? const BorderSide(color: AppColors.dividerDark)
              : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingSm,
        ),
      ),

      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: isDark
              ? AppColors.elevatedDark
              : AppColors.dividerLight,
          disabledForegroundColor: isDark
              ? AppColors.textDisabledDark
              : AppColors.textDisabledLight,
          textStyle: AppTextStyles.buttonText(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXxl,
            vertical: AppDimensions.spacingMd,
          ),
        ),
      ),

      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.buttonText(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXxl,
            vertical: AppDimensions.spacingMd,
          ),
        ),
      ),

      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      ),

      // ─── Input Decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.elevatedDark : const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingLg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextStyles.bodyLarge(
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        labelStyle: AppTextStyles.bodyMedium(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        errorStyle: AppTextStyles.bodySmall(color: AppColors.error),
        prefixIconColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        suffixIconColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.elevatedDark
            : const Color(0xFFF3F4F6),
        selectedColor: AppColors.primarySurface,
        disabledColor: isDark ? AppColors.surfaceDark : AppColors.dividerLight,
        labelStyle: AppTextStyles.labelMedium(),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingXs,
        ),
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        elevation: AppDimensions.elevationLg,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        ),
        titleTextStyle: AppTextStyles.headlineSmall(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
        contentTextStyle: AppTextStyles.bodyMedium(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),

      // ─── Bottom Sheet ───
      bottomSheetTheme: BottomSheetThemeData(
        elevation: AppDimensions.elevationLg,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXxl),
          ),
        ),
        modalElevation: AppDimensions.elevationLg,
        showDragHandle: true,
        dragHandleColor: isDark ? AppColors.borderDark : AppColors.dividerLight,
        dragHandleSize: const Size(
          AppDimensions.bottomSheetHandleWidth,
          AppDimensions.bottomSheetHandleHeight,
        ),
      ),

      // ─── Floating Action Button ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: AppDimensions.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),

      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return isDark ? AppColors.textTertiaryDark : AppColors.borderLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return isDark ? AppColors.elevatedDark : const Color(0xFFE5E7EB);
        }),
      ),

      // ─── Snack Bar ───
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.elevatedDark
            : AppColors.textPrimaryLight,
        contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),

      // ─── Tab Bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        labelStyle: AppTextStyles.labelLarge(),
        unselectedLabelStyle: AppTextStyles.labelLarge(),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ─── Progress Indicator ───
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.primarySurface,
        linearTrackColor: AppColors.primarySurface,
      ),

      // ─── Splash / Ripple ───
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: AppColors.primary.withValues(alpha: 0.04),
      splashFactory: InkSparkle.splashFactory,

      // ─── Page Transitions ───
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
