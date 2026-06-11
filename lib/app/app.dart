import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/gamification/application/services/achievement_engine_service.dart';
import '../features/gamification/presentation/widgets/celebration_overlay.dart';
import '../features/profile/presentation/controllers/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root application widget for Xenova Health.
///
/// Configures theming (system-adaptive), routing (GoRouter),
/// and localization (i18n with ARB).
class XenovaHealthApp extends ConsumerWidget {
  const XenovaHealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);

    ThemeMode themeMode;
    switch (settings.themeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'Xenova Health',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,

      // ─── Global Overlays ───
      builder: (context, child) {
        return CelebrationOverlay(
          eventStream: ref.watch(achievementEngineProvider).eventStream,
          child: child ?? const SizedBox.shrink(),
        );
      },

      // ─── Theme ───
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      // ─── Routing ───
      routerConfig: router,

      // ─── Localization ───
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}
