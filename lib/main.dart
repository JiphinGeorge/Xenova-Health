import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'core/firebase/crashlytics_service.dart';
import 'core/services/hive_service.dart';
import 'firebase_options.dart' as prod_options;
import 'firebase_options_dev.dart' as dev_options;
import 'firebase_options_staging.dart' as staging_options;

/// Entry point for the Xenova Health application.
/// Initializes Firebase, Hive, Crashlytics, environment variables,
/// and wraps the app in [ProviderScope] for Riverpod DI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Determine Environment & Load .env ───
  final packageInfo = await PackageInfo.fromPlatform();
  String envFile = 'assets/env/prod.env'; // Default to prod
  FirebaseOptions firebaseOptions = prod_options.DefaultFirebaseOptions.currentPlatform;
  
  if (packageInfo.packageName.endsWith('.dev')) {
    envFile = 'assets/env/dev.env';
    firebaseOptions = dev_options.DefaultFirebaseOptions.currentPlatform;
  } else if (packageInfo.packageName.endsWith('.staging')) {
    envFile = 'assets/env/staging.env';
    firebaseOptions = staging_options.DefaultFirebaseOptions.currentPlatform;
  }
  
  await dotenv.load(fileName: envFile);

  // ─── Initialize Firebase ───
  await Firebase.initializeApp(
    options: firebaseOptions,
  );

  // ─── Initialize App Check ───
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidAppCheckProvider.playIntegrity,
    appleProvider: AppleAppCheckProvider.deviceCheck,
  );

  // ─── Initialize Crashlytics ───
  final crashlytics = CrashlyticsService()..initialize();

  // ─── Initialize Hive ───
  final hiveService = HiveService();
  await hiveService.initialize();

  // ─── System UI Configuration ───
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Suppress unused variable warning for crashlytics
  debugPrint('Crashlytics initialized: ${crashlytics.hashCode}');

  // ─── Launch App ───
  runApp(const ProviderScope(child: XenovaHealthApp()));
}
