import '../models/achievement_model.dart';

class AchievementConfig {
  static const List<AchievementModel> predefinedAchievements = [
    // Weight Achievements
    AchievementModel(
      id: 'weight_first_entry',
      title: 'First Step',
      description: 'Log your first weight entry',
      category: AchievementCategory.weight,
      rarity: BadgeRarity.common,
      xpReward: 25,
      targetProgress: 1,
    ),
    AchievementModel(
      id: 'weight_lose_1kg',
      title: 'Getting Started',
      description: 'Lose 1kg from your starting weight',
      category: AchievementCategory.weight,
      rarity: BadgeRarity.common,
      xpReward: 50,
      targetProgress: 1,
    ),
    AchievementModel(
      id: 'weight_lose_5kg',
      title: 'On a Roll',
      description: 'Lose 5kg from your starting weight',
      category: AchievementCategory.weight,
      rarity: BadgeRarity.rare,
      xpReward: 200,
      targetProgress: 5,
    ),
    AchievementModel(
      id: 'weight_lose_10kg',
      title: 'Transformation',
      description: 'Lose 10kg from your starting weight',
      category: AchievementCategory.weight,
      rarity: BadgeRarity.epic,
      xpReward: 500,
      targetProgress: 10,
    ),
    AchievementModel(
      id: 'weight_reach_goal',
      title: 'Goal Crusher',
      description: 'Reach your goal weight',
      category: AchievementCategory.weight,
      rarity: BadgeRarity.legendary,
      xpReward: 1000,
      targetProgress: 1,
    ),

    // Nutrition Achievements
    AchievementModel(
      id: 'nutrition_first_meal',
      title: 'Food Aware',
      description: 'Log your first meal',
      category: AchievementCategory.nutrition,
      rarity: BadgeRarity.common,
      xpReward: 25,
      targetProgress: 1,
    ),
    AchievementModel(
      id: 'nutrition_protein_7_days',
      title: 'Protein Master',
      description: 'Meet your protein goal for 7 days',
      category: AchievementCategory.nutrition,
      rarity: BadgeRarity.rare,
      xpReward: 150,
      targetProgress: 7,
    ),
    AchievementModel(
      id: 'nutrition_water_7_days',
      title: 'Hydrated',
      description: 'Meet your water goal for 7 days',
      category: AchievementCategory.nutrition,
      rarity: BadgeRarity.rare,
      xpReward: 100,
      targetProgress: 7,
    ),

    // Fasting Achievements
    AchievementModel(
      id: 'fasting_first_fast',
      title: 'First Fast',
      description: 'Complete your first fasting session',
      category: AchievementCategory.fasting,
      rarity: BadgeRarity.common,
      xpReward: 25,
      targetProgress: 1,
    ),
    AchievementModel(
      id: 'fasting_7_day_streak',
      title: 'Fasting Habit',
      description: 'Complete a fast for 7 consecutive days',
      category: AchievementCategory.fasting,
      rarity: BadgeRarity.rare,
      xpReward: 150,
      targetProgress: 7,
    ),
    AchievementModel(
      id: 'fasting_30_day_streak',
      title: 'Fasting Master',
      description: 'Complete a fast for 30 consecutive days',
      category: AchievementCategory.fasting,
      rarity: BadgeRarity.epic,
      xpReward: 500,
      targetProgress: 30,
    ),
    AchievementModel(
      id: 'fasting_first_omad',
      title: 'OMAD Champion',
      description: 'Complete your first 23+ hour fast',
      category: AchievementCategory.fasting,
      rarity: BadgeRarity.rare,
      xpReward: 200,
      targetProgress: 1,
    ),

    // Progress Photos Achievements
    AchievementModel(
      id: 'photos_first_photo',
      title: 'Day One',
      description: 'Take your first progress photo',
      category: AchievementCategory.progressPhotos,
      rarity: BadgeRarity.common,
      xpReward: 25,
      targetProgress: 1,
    ),
    AchievementModel(
      id: 'photos_30_days',
      title: 'Visible Progress',
      description: 'Log progress photos for 30 days',
      category: AchievementCategory.progressPhotos,
      rarity: BadgeRarity.rare,
      xpReward: 150,
      targetProgress: 30,
    ),
    AchievementModel(
      id: 'photos_90_days',
      title: 'Transformation Journey',
      description: 'Log progress photos for 90 days',
      category: AchievementCategory.progressPhotos,
      rarity: BadgeRarity.epic,
      xpReward: 500,
      targetProgress: 90,
    ),

    // AI Coach Achievements
    AchievementModel(
      id: 'ai_coach_first_chat',
      title: 'Hello AI',
      description: 'Have your first conversation with the AI Coach',
      category: AchievementCategory.aiCoach,
      rarity: BadgeRarity.common,
      xpReward: 10,
      targetProgress: 1,
    ),
    AchievementModel(
      id: 'ai_coach_weekly_summary',
      title: 'Insight Seeker',
      description: 'View your first weekly health summary',
      category: AchievementCategory.aiCoach,
      rarity: BadgeRarity.common,
      xpReward: 20,
      targetProgress: 1,
    ),

    // Consistency Achievements (e.g. Login Streaks)
    AchievementModel(
      id: 'consistency_3_day_streak',
      title: 'Getting Consistent',
      description: 'Log in for 3 consecutive days',
      category: AchievementCategory.consistency,
      rarity: BadgeRarity.common,
      xpReward: 50,
      targetProgress: 3,
    ),
    AchievementModel(
      id: 'consistency_7_day_streak',
      title: 'Solid Routine',
      description: 'Log in for 7 consecutive days',
      category: AchievementCategory.consistency,
      rarity: BadgeRarity.rare,
      xpReward: 100,
      targetProgress: 7,
    ),
    AchievementModel(
      id: 'consistency_30_day_streak',
      title: 'Unstoppable',
      description: 'Log in for 30 consecutive days',
      category: AchievementCategory.consistency,
      rarity: BadgeRarity.epic,
      xpReward: 300,
      targetProgress: 30,
    ),

    // Milestones (e.g. Total Weight Logged count)
    AchievementModel(
      id: 'milestone_weight_logs_20',
      title: 'Weight Watcher',
      description: 'Log your weight 20 times',
      category: AchievementCategory.milestones,
      rarity: BadgeRarity.rare,
      xpReward: 100,
      targetProgress: 20,
    ),
    AchievementModel(
      id: 'milestone_fasts_15',
      title: 'Fasting Enthusiast',
      description: 'Complete 15 fasting sessions',
      category: AchievementCategory.milestones,
      rarity: BadgeRarity.rare,
      xpReward: 150,
      targetProgress: 15,
    ),
    // Monthly Challenges
    AchievementModel(
      id: 'challenge_monthly_protein',
      title: 'Protein Power Month',
      description: 'Meet Protein Goal 10 Days in a month',
      category: AchievementCategory.milestones,
      rarity: BadgeRarity.epic,
      xpReward: 300,
      targetProgress: 10,
    ),
    AchievementModel(
      id: 'challenge_monthly_water',
      title: 'Hydration Month',
      description: 'Meet Water Goal 20 Days in a month',
      category: AchievementCategory.milestones,
      rarity: BadgeRarity.epic,
      xpReward: 300,
      targetProgress: 20,
    ),
  ];

  static int calculateXpForLevel(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 100;
    if (level == 3) return 250;
    if (level == 4) return 500;
    if (level == 5) return 1000;
    
    // After Level 5: Previous XP * 1.5
    double xp = 1000.0;
    for (int i = 6; i <= level; i++) {
      xp *= 1.5;
    }
    return xp.round();
  }

  static int getLevelFromXp(int totalXp) {
    int level = 1;
    while (true) {
      if (totalXp < calculateXpForLevel(level + 1)) {
        return level;
      }
      level++;
    }
  }
}
