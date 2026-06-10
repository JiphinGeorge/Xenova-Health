import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return MaterialApp.router(
      title: 'Xenova Health',
      debugShowCheckedModeBanner: false,

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
