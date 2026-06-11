import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/achievement_model.dart';
import '../../domain/models/user_level_model.dart';
import '../../../../core/di/providers.dart';

class AchievementRepository {
  AchievementRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  String _achievementsPath(String userId) => 'users/$userId/achievements';
  String _userLevelPath(String userId) => 'users/$userId/user_level/main';

  /// Fetches all unlocked achievements for a user
  Future<List<AchievementModel>> getUnlockedAchievements(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_achievementsPath(userId))
        .get();

    return snapshot.docs
        .map((doc) => AchievementModel.fromJson(doc.data()))
        .toList();
  }

  /// Streams the user's unlocked achievements
  Stream<List<AchievementModel>> watchUnlockedAchievements(String userId) {
    return _firestoreService
        .streamCollection(path: _achievementsPath(userId))
        .map((snapshot) => snapshot.docs
            .map((doc) => AchievementModel.fromJson(doc.data()))
            .toList());
  }

  /// Fetches the user's level and XP details
  Future<UserLevelModel> getUserLevel(String userId) async {
    final doc = await _firestoreService.getDocument(path: _userLevelPath(userId));
    if (doc != null) {
      return UserLevelModel.fromJson(doc);
    }
    return UserLevelModel(userId: userId);
  }

  /// Streams the user's level and XP details
  Stream<UserLevelModel> watchUserLevel(String userId) {
    return FirebaseFirestore.instance
        .doc(_userLevelPath(userId))
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserLevelModel.fromJson(doc.data()!);
      }
      return UserLevelModel(userId: userId);
    });
  }

  /// Unlocks an achievement or updates its progress
  Future<void> saveAchievementProgress(String userId, AchievementModel achievement) async {
    await _firestoreService.setDocument(
      path: '${_achievementsPath(userId)}/${achievement.id}',
      data: achievement.toJson(),
    );
  }

  /// Updates the user's level/XP and login streaks
  Future<void> saveUserLevel(UserLevelModel userLevel) async {
    await _firestoreService.setDocument(
      path: _userLevelPath(userLevel.userId),
      data: userLevel.toJson(),
    );
  }
}

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.watch(firestoreServiceProvider));
});
