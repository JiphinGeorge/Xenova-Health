import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/firebase/crashlytics_service.dart';
import 'core/services/hive_service.dart';

/// Entry point for the Xenova Health application.
///
/// Initializes Firebase, Hive, Crashlytics, environment variables,
/// and wraps the app in [ProviderScope] for Riverpod DI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Load Environment Variables ───
  await dotenv.load();

  // ─── Initialize Firebase ───
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
    // TODO(firebase): Uncomment above after running `flutterfire configure`
  );

  // ─── Initialize App Check ───
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
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
