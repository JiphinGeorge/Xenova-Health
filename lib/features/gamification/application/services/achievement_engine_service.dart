import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/data/repositories/lifetime_stats_repository.dart';
import '../../../profile/domain/models/lifetime_stats_model.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../domain/config/achievement_config.dart';
import '../../domain/models/achievement_model.dart';
import '../../domain/models/user_level_model.dart';
import '../../../../core/analytics/analytics_service.dart';

import '../../presentation/widgets/celebration_overlay.dart';

class AchievementEngineService {
  AchievementEngineService(this._ref, this._repo);

  final Ref _ref;
  final AchievementRepository _repo;

  final _eventController = StreamController<GamificationEvent>.broadcast();
  Stream<GamificationEvent> get eventStream => _eventController.stream;

  /// Private state so we don't query Firestore repeatedly during rapid events
  List<AchievementModel>? _cachedAchievements;
  UserLevelModel? _cachedUserLevel;

  Future<void> _init(String userId) async {
    if (_cachedAchievements == null || _cachedUserLevel == null) {
      _cachedAchievements = await _repo.getUnlockedAchievements(userId);
      _cachedUserLevel = await _repo.getUserLevel(userId);

      // Sync stats just in case
      final totalUnlocked = _cachedAchievements!.where((a) => a.isUnlocked).length;
      final totalAvailable = AchievementConfig.predefinedAchievements.length;
      final completionPercent = totalAvailable > 0 
          ? ((totalUnlocked / totalAvailable) * 100) 
          : 0.0;
          
      if (_cachedUserLevel!.totalAchievementsUnlocked != totalUnlocked ||
          _cachedUserLevel!.totalAchievementsAvailable != totalAvailable) {
        _cachedUserLevel = _cachedUserLevel!.copyWith(
          totalAchievementsUnlocked: totalUnlocked,
          totalAchievementsAvailable: totalAvailable,
          completionPercentage: completionPercent,
        );
        await _repo.saveUserLevel(_cachedUserLevel!);
      }
    }
  }

  /// Helper to increment lifetime statistics in users/{uid}/stats/lifetime
  Future<void> _incrementLifetimeStat(
    String userId, {
    int weightEntries = 0,
    int mealsLogged = 0,
    int fastsCompleted = 0,
    int progressPhotos = 0,
    int aiChats = 0,
  }) async {
    final repo = _ref.read(lifetimeStatsRepositoryProvider);
    var stats = await repo.getStats(userId);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    bool isNewDay = false;
    if (stats.lastTrackedDay == null) {
      isNewDay = true;
    } else {
      final lastDay = DateTime(
        stats.lastTrackedDay!.year,
        stats.lastTrackedDay!.month,
        stats.lastTrackedDay!.day,
      );
      if (today.difference(lastDay).inDays >= 1) {
        isNewDay = true;
      }
    }
    
    stats = stats.copyWith(
      totalWeightEntries: stats.totalWeightEntries + weightEntries,
      totalMealsLogged: stats.totalMealsLogged + mealsLogged,
      totalFastsCompleted: stats.totalFastsCompleted + fastsCompleted,
      totalProgressPhotos: stats.totalProgressPhotos + progressPhotos,
      totalAIChats: stats.totalAIChats + aiChats,
      totalDaysTracked: stats.totalDaysTracked + (isNewDay ? 1 : 0),
      lastTrackedDay: now,
      updatedAt: now,
    );
    
    await repo.saveStats(userId, stats);
  }

  /// Entry point for weight events
  Future<void> processWeightEvent(double currentWeight) async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null) return;
    await _init(user.uid);

    // Track lifetime stats
    await _incrementLifetimeStat(user.uid, weightEntries: 1);

    // Give XP for the entry
    await _addXp(user.uid, 5); // General weight log XP

    // First Entry
    await _checkAndUnlock(user.uid, 'weight_first_entry');

    // Progress logic
    final startWeight = user.currentWeightKg;
    if (startWeight != null) {
      final lost = startWeight - currentWeight;
      if (lost >= 1) await _checkAndUnlock(user.uid, 'weight_lose_1kg');
      if (lost >= 5) await _checkAndUnlock(user.uid, 'weight_lose_5kg');
      if (lost >= 10) await _checkAndUnlock(user.uid, 'weight_lose_10kg');
    }

    final target = user.targetWeightKg;
    if (target != null && currentWeight <= target) {
      await _checkAndUnlock(user.uid, 'weight_reach_goal');
    }
  }

  /// Entry point for fasting events
  Future<void> processFastingEvent(int streakDays, int durationHours) async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null) return;
    await _init(user.uid);

    // Track lifetime stats
    await _incrementLifetimeStat(user.uid, fastsCompleted: 1);

    await _addXp(user.uid, 5); // Completed fast XP
    await _checkAndUnlock(user.uid, 'fasting_first_fast');

    if (durationHours >= 23) {
      await _checkAndUnlock(user.uid, 'fasting_first_omad');
    }

    // Cumulative Streaks
    await _progressAchievement(user.uid, 'fasting_7_day_streak', streakDays);
    await _progressAchievement(user.uid, 'fasting_30_day_streak', streakDays);
  }

  /// Entry point for nutrition events
  Future<void> processNutritionEvent() async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null) return;
    await _init(user.uid);

    // Track lifetime stats
    await _incrementLifetimeStat(user.uid, mealsLogged: 1);

    await _addXp(user.uid, 2); // Meal logged XP
    await _checkAndUnlock(user.uid, 'nutrition_first_meal');
  }

  /// Entry point for Progress Photos
  Future<void> processProgressPhotoEvent(int daysSinceFirstPhoto) async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null) return;
    await _init(user.uid);

    // Track lifetime stats
    await _incrementLifetimeStat(user.uid, progressPhotos: 1);

    await _addXp(user.uid, 10);
    await _checkAndUnlock(user.uid, 'photos_first_photo');
    
    await _progressAchievement(user.uid, 'photos_30_days', daysSinceFirstPhoto);
    await _progressAchievement(user.uid, 'photos_90_days', daysSinceFirstPhoto);
  }

  /// Entry point for AI Coach events
  Future<void> processAiCoachEvent(bool isSummary) async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null) return;
    await _init(user.uid);

    if (isSummary) {
      await _addXp(user.uid, 5);
      await _checkAndUnlock(user.uid, 'ai_coach_weekly_summary');
    } else {
      // Track lifetime stats for chats
      await _incrementLifetimeStat(user.uid, aiChats: 1);
      await _addXp(user.uid, 1);
      await _checkAndUnlock(user.uid, 'ai_coach_first_chat');
    }
  }

  /// Handles Login Streak Logic
  Future<void> processLoginEvent() async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null) return;
    await _init(user.uid);

    // Track login activity in lifetime stats
    await _incrementLifetimeStat(user.uid);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var levelModel = _cachedUserLevel!;
    final lastLogin = levelModel.lastLoginDate;

    if (lastLogin != null) {
      final lastLoginDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      final diff = today.difference(lastLoginDay).inDays;

      if (diff == 1) {
        // Consecutive day
        levelModel = levelModel.copyWith(
          currentLoginStreak: levelModel.currentLoginStreak + 1,
        );
      } else if (diff > 1) {
        // Streak broken
        levelModel = levelModel.copyWith(currentLoginStreak: 1);
      }
    } else {
      // First login
      levelModel = levelModel.copyWith(currentLoginStreak: 1);
    }

    if (levelModel.currentLoginStreak > levelModel.longestLoginStreak) {
      levelModel = levelModel.copyWith(longestLoginStreak: levelModel.currentLoginStreak);
    }

    levelModel = levelModel.copyWith(lastLoginDate: now);

    _cachedUserLevel = levelModel;
    await _repo.saveUserLevel(levelModel);

    // Check Streak Achievements
    await _progressAchievement(user.uid, 'consistency_3_day_streak', levelModel.currentLoginStreak);
    await _progressAchievement(user.uid, 'consistency_7_day_streak', levelModel.currentLoginStreak);
    await _progressAchievement(user.uid, 'consistency_30_day_streak', levelModel.currentLoginStreak);
  }

  // --- Internal Core Logic ---

  Future<void> _checkAndUnlock(String userId, String achievementId) async {
    final def = AchievementConfig.predefinedAchievements.firstWhere((a) => a.id == achievementId);
    await _progressAchievement(userId, achievementId, def.targetProgress);
  }

  Future<void> _progressAchievement(String userId, String achievementId, int newProgress) async {
    final def = AchievementConfig.predefinedAchievements.firstWhere((a) => a.id == achievementId);
    
    // Check cache
    AchievementModel? current = _cachedAchievements!.cast<AchievementModel?>().firstWhere(
      (a) => a?.id == achievementId,
      orElse: () => null,
    );

    if (current != null && current.isUnlocked) return; // Already unlocked

    int progress = (current?.currentProgress ?? 0);
    if (newProgress > progress) {
      progress = newProgress;
    }

    bool isNowUnlocked = progress >= def.targetProgress;
    
    final updated = def.copyWith(
      currentProgress: progress,
      isUnlocked: isNowUnlocked,
      unlockedAt: isNowUnlocked ? DateTime.now() : null,
    );

    if (current == null) {
      _cachedAchievements!.add(updated);
    } else {
      final index = _cachedAchievements!.indexWhere((a) => a.id == achievementId);
      _cachedAchievements![index] = updated;
    }

    await _repo.saveAchievementProgress(userId, updated);

    if (isNowUnlocked) {
      debugPrint('[GAMIFICATION] Unlocked Achievement: ${def.title}');
      
      _ref.read(analyticsServiceProvider).logAchievementUnlocked(achievementId: def.id);

      _eventController.add(GamificationEvent(
        title: 'Achievement Unlocked!',
        message: def.title,
        rarity: def.rarity,
      ));

      // Update level statistics before adding XP
      final totalUnlocked = _cachedAchievements!.where((a) => a.isUnlocked).length;
      final totalAvailable = AchievementConfig.predefinedAchievements.length;
      final completionPercent = totalAvailable > 0 
          ? ((totalUnlocked / totalAvailable) * 100) 
          : 0.0;

      _cachedUserLevel = _cachedUserLevel!.copyWith(
        totalAchievementsUnlocked: totalUnlocked,
        totalAchievementsAvailable: totalAvailable,
        completionPercentage: completionPercent,
      );

      await _addXp(userId, def.xpReward);
    }
  }

  Future<void> _addXp(String userId, int amount) async {
    var levelModel = _cachedUserLevel!;
    
    final newXp = levelModel.totalXp + amount;
    final oldLevel = levelModel.currentLevel;
    final newLevel = AchievementConfig.getLevelFromXp(newXp);
    final nextLevelXp = AchievementConfig.calculateXpForLevel(newLevel + 1);

    levelModel = levelModel.copyWith(
      totalXp: newXp,
      currentLevel: newLevel,
      xpForNextLevel: nextLevelXp,
    );

    if (newLevel > oldLevel) {
      debugPrint('[GAMIFICATION] LEVEL UP! You are now Level $newLevel');
      _eventController.add(GamificationEvent(
        title: 'Level Up!',
        message: 'You reached Level $newLevel!',
        isLevelUp: true,
      ));
    }

    _cachedUserLevel = levelModel;
    await _repo.saveUserLevel(levelModel);
  }
}

final achievementEngineProvider = Provider<AchievementEngineService>((ref) {
  return AchievementEngineService(ref, ref.watch(achievementRepositoryProvider));
});

