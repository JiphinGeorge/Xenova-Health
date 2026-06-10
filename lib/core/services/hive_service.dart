import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Service that manages Hive local storage initialization and access.
///
/// All Hive boxes used across the app are opened and managed here.
class HiveService {
  /// Initializes Hive and opens all required boxes.
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters here as features are added
    // Hive.registerAdapter(UserModelAdapter());

    // Open all boxes
    await Future.wait([
      Hive.openBox<dynamic>(AppConstants.userBox),
      Hive.openBox<dynamic>(AppConstants.weightBox),
      Hive.openBox<dynamic>(AppConstants.foodBox),
      Hive.openBox<dynamic>(AppConstants.mealBox),
      Hive.openBox<dynamic>(AppConstants.fastingBox),
      Hive.openBox<dynamic>(AppConstants.measurementBox),
      Hive.openBox<dynamic>(AppConstants.settingsBox),
      Hive.openBox<dynamic>(AppConstants.syncQueueBox),
      Hive.openBox<dynamic>(AppConstants.cacheBox),
      Hive.openBox<dynamic>(AppConstants.dailySummaryBox),
    ]);
  }

  /// Gets an opened Hive box by name.
  Box<dynamic> getBox(String name) => Hive.box(name);

  /// Gets the settings box.
  Box<dynamic> get settingsBox => Hive.box(AppConstants.settingsBox);

  /// Gets the user box.
  Box<dynamic> get userBox => Hive.box(AppConstants.userBox);

  /// Gets the weight entries box.
  Box<dynamic> get weightBox => Hive.box(AppConstants.weightBox);

  /// Gets the food box.
  Box<dynamic> get foodBox => Hive.box(AppConstants.foodBox);

  /// Gets the meal logs box.
  Box<dynamic> get mealBox => Hive.box(AppConstants.mealBox);

  /// Gets the fasting sessions box.
  Box<dynamic> get fastingBox => Hive.box(AppConstants.fastingBox);

  /// Gets the measurements box.
  Box<dynamic> get measurementBox => Hive.box(AppConstants.measurementBox);

  /// Gets the sync queue box.
  Box<dynamic> get syncQueueBox => Hive.box(AppConstants.syncQueueBox);

  /// Gets the API cache box.
  Box<dynamic> get cacheBox => Hive.box(AppConstants.cacheBox);

  /// Gets the daily summary box.
  Box<dynamic> get dailySummaryBox => Hive.box(AppConstants.dailySummaryBox);

  /// Clears all local data (for logout).
  Future<void> clearAll() async {
    await Future.wait([
      Hive.box<dynamic>(AppConstants.userBox).clear(),
      Hive.box<dynamic>(AppConstants.weightBox).clear(),
      Hive.box<dynamic>(AppConstants.foodBox).clear(),
      Hive.box<dynamic>(AppConstants.mealBox).clear(),
      Hive.box<dynamic>(AppConstants.fastingBox).clear(),
      Hive.box<dynamic>(AppConstants.measurementBox).clear(),
      Hive.box<dynamic>(AppConstants.syncQueueBox).clear(),
      Hive.box<dynamic>(AppConstants.cacheBox).clear(),
      Hive.box<dynamic>(AppConstants.dailySummaryBox).clear(),
    ]);
  }

  /// Closes all Hive boxes.
  Future<void> close() async {
    await Hive.close();
  }
}
