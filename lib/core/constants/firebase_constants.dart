/// Firebase-related constants for Xenova Health.
abstract final class FirebaseConstants {
  // ─── Firestore Collections ───
  static const String usersCollection = 'users';
  static const String weightEntriesCollection = 'weight_entries';
  static const String customFoodsCollection = 'custom_foods';
  static const String mealLogsCollection = 'meal_logs';
  static const String dailySummariesCollection = 'daily_summaries';
  static const String fastingSessionsCollection = 'fasting_sessions';
  static const String bodyMeasurementsCollection = 'body_measurements';
  static const String progressPhotosCollection = 'progress_photos';
  static const String goalsCollection = 'goals';
  static const String achievementsCollection = 'achievements';
  static const String aiConversationsCollection = 'ai_conversations';
  static const String messagesCollection = 'messages';
  static const String globalFoodDatabaseCollection = 'food_database';

  // ─── Firestore Documents ───
  static const String preferencesDoc = 'preferences';
  static const String overviewDoc = 'overview';

  // ─── Firestore Subcollection Paths ───
  static const String settingsSubcollection = 'settings';
  static const String statsSubcollection = 'stats';

  // ─── Storage Paths ───
  static const String profileStoragePath = 'users/{uid}/profile';
  static const String progressPhotosStoragePath = 'users/{uid}/progress_photos';
  static const String reportsStoragePath = 'users/{uid}/reports';
  static const String exportsStoragePath = 'users/{uid}/exports';

  // ─── Analytics Events ───
  static const String eventWeightLogged = 'weight_logged';
  static const String eventMealLogged = 'meal_logged';
  static const String eventFastingCompleted = 'fasting_completed';
  static const String eventFastingStarted = 'fasting_started';
  static const String eventPhotoUploaded = 'photo_uploaded';
  static const String eventExportGenerated = 'export_generated';
  static const String eventFoodSearched = 'food_searched';
  static const String eventCustomFoodCreated = 'custom_food_created';
  static const String eventBarcodeScanned = 'barcode_scanned';
  static const String eventAiChatSent = 'ai_chat_sent';
  static const String eventGoalCreated = 'goal_created';
  static const String eventGoalCompleted = 'goal_completed';
  static const String eventAchievementEarned = 'achievement_earned';
  static const String eventOnboardingCompleted = 'onboarding_completed';

  // ─── Analytics User Properties ───
  static const String propActivityLevel = 'activity_level';
  static const String propFastingPlan = 'fasting_plan';
  static const String propDaysActive = 'days_active';
  static const String propSubscriptionTier = 'subscription_tier';

  // ─── FCM Topics ───
  static const String topicAll = 'all_users';
  static const String topicPremium = 'premium_users';

  /// Generates the storage path for a user's profile pictures.
  static String profilePath(String uid) => 'users/$uid/profile';

  /// Generates the storage path for a user's progress photos.
  static String progressPhotosPath(String uid) => 'users/$uid/progress_photos';

  /// Generates the storage path for a user's exported reports.
  static String reportsPath(String uid) => 'users/$uid/reports';

  /// Generates the storage path for a user's data exports.
  static String exportsPath(String uid) => 'users/$uid/exports';
}
