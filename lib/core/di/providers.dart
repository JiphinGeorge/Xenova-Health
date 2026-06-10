import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase.dart';
import '../network/dio_client.dart';
import '../services/services.dart';

/// ─── Firebase Service Providers ───

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final firebaseStorageServiceProvider = Provider<FirebaseStorageService>(
  (ref) => FirebaseStorageService(),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);

final crashlyticsServiceProvider = Provider<CrashlyticsService>(
  (ref) => CrashlyticsService(),
);

final messagingServiceProvider = Provider<MessagingService>(
  (ref) => MessagingService(),
);

/// ─── Core Service Providers ───

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return SyncService(connectivityService: connectivity);
});
