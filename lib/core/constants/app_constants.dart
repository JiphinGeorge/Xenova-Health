/// Application-wide constants for Xenova Health.
abstract final class AppConstants {
  // ─── App Info ───
  static const String appName = 'Xenova Health';
  static const String appTagline = 'Your Health, Your Journey';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String packageName = 'com.xenovahealth.leanlog';

  // ─── Hive Box Names ───
  static const String userBox = 'user_box';
  static const String weightBox = 'weight_box';
  static const String foodBox = 'food_box';
  static const String mealBox = 'meal_box';
  static const String fastingBox = 'fasting_box';
  static const String measurementBox = 'measurement_box';
  static const String settingsBox = 'settings_box';
  static const String syncQueueBox = 'sync_queue_box';
  static const String cacheBox = 'cache_box';
  static const String dailySummaryBox = 'daily_summary_box';

  // ─── Hive Settings Keys ───
  static const String themeModeSetting = 'theme_mode';
  static const String localeSetting = 'locale';
  static const String isFirstLaunchSetting = 'is_first_launch';
  static const String isOnboardingCompleteSetting = 'is_onboarding_complete';
  static const String rememberLoginSetting = 'remember_login';
  static const String unitSystemSetting = 'unit_system';
  static const String aiProviderSetting = 'ai_provider';

  // ─── Secure Storage Keys ───
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // ─── Defaults ───
  static const int defaultWaterGoalMl = 2500;
  static const double defaultCalorieGoal = 2000;
  static const int maxProgressPhotos = 50;
  static const int maxCustomFoods = 500;
  static const int apiCacheDurationHours = 24;
  static const int syncRetryMaxAttempts = 3;
  static const int syncRetryDelaySeconds = 5;
  static const int imageMaxWidthPx = 1920;
  static const int imageQuality = 80;
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB

  // ─── Pagination ───
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ─── Date Formats ───
  static const String dateFormatShort = 'MMM d';
  static const String dateFormatMedium = 'MMM d, yyyy';
  static const String dateFormatLong = 'MMMM d, yyyy';
  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';
  static const String timeFormat12h = 'h:mm a';
  static const String timeFormat24h = 'HH:mm';
  static const String dateTimeFormat = 'MMM d, yyyy h:mm a';

  // ─── Validation ───
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const double minWeight = 20.0; // kg
  static const double maxWeight = 500.0; // kg
  static const double minHeight = 50.0; // cm
  static const double maxHeight = 300.0; // cm
  static const int minAge = 13;
  static const int maxAge = 120;
}
