import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/fasting/presentation/screens/fasting_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress_photos/presentation/screens/progress_photos_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/weight/presentation/screens/weight_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_dashboard_screen.dart';
import '../../features/nutrition/presentation/screens/food_search_screen.dart';
import '../../features/nutrition/presentation/screens/food_details_screen.dart';
import '../../features/nutrition/presentation/screens/meal_builder_review_screen.dart';
import '../../features/nutrition/domain/models/food_item_model.dart';
import '../../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/ai_coach/presentation/screens/ai_coach_screen.dart';

/// Route path constants.
abstract final class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';

  // Onboarding
  static const String onboarding = '/onboarding';

  // Main Shell
  static const String dashboard = '/dashboard';
  static const String weight = '/weight';
  static const String nutrition = '/nutrition';
  static const String fasting = '/fasting';
  static const String profile = '/profile';

  // Detail Screens
  static const String settings = '/settings';
  static const String mealLog = '/meal-log';
  static const String weightLog = '/weight-log';
  static const String measurements = '/measurements';
  static const String progressPhotos = '/progress-photos';
  static const String aiCoach = '/ai-coach';
  static const String reports = '/reports';
  static const String reports = '/reports';
  static const String exportData = '/export';
  static const String foodSearch = '/food-search';
  static const String foodDetails = '/food-details';
  static const String mealBuilderReview = '/meal-builder-review';
  static const String barcodeScanner = '/barcode-scanner';
}

/// GoRouter navigation keys for nested navigation.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final user = authState.value;
      final isLoggedIn = user != null;
      final isLoggingIn =
          state.uri.path == AppRoutes.login ||
          state.uri.path == AppRoutes.register ||
          state.uri.path == AppRoutes.forgotPassword;

      if (!isLoggedIn) {
        return isLoggingIn ? null : AppRoutes.login;
      }

      // User is logged in
      if (isLoggingIn) {
        if (!user.isOnboardingComplete) return AppRoutes.onboarding;
        return AppRoutes.dashboard;
      }

      // Force onboarding if not complete
      if (!user.isOnboardingComplete &&
          state.uri.path != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      // Redirect away from onboarding if already complete
      if (user.isOnboardingComplete && state.uri.path == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // ─── Auth Routes ───
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        name: 'emailVerification',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Email Verification'),
      ),

      // ─── Onboarding ───
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingWizardScreen(),
      ),

      // ─── Main Shell with Bottom Navigation ───
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.weight,
            name: 'weight',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WeightScreen()),
          ),
          GoRoute(
            path: AppRoutes.nutrition,
            name: 'nutrition',
            builder: (context, state) => const NutritionDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.fasting,
            name: 'fasting',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FastingScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // ─── Detail Routes (Outside Shell) ───
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Settings'),
      ),
      GoRoute(
        path: AppRoutes.mealLog,
        name: 'mealLog',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Meal Log'),
      ),
      GoRoute(
        path: AppRoutes.measurements,
        name: 'measurements',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Body Measurements'),
      ),
      GoRoute(
        path: AppRoutes.progressPhotos,
        name: 'progressPhotos',
        builder: (context, state) => const ProgressPhotosScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiCoach,
        name: 'aiCoach',
        builder: (context, state) => const AICoachScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.exportData,
        name: 'exportData',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Export Data'),
      ),
      GoRoute(
        path: AppRoutes.foodSearch,
        name: 'food-search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FoodSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodDetails,
        name: 'food-details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final food = state.extra as FoodItemModel;
          return FoodDetailsScreen(food: food);
        },
      ),
      GoRoute(
        path: AppRoutes.mealBuilderReview,
        name: 'meal-builder-review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MealBuilderReviewScreen(),
      ),
    ],

    // Error handler
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Temporary placeholder screen — replaced in Phase 2+.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 2',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
