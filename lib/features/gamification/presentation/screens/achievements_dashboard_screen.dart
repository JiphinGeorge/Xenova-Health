import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../domain/config/achievement_config.dart';
import '../../domain/models/achievement_model.dart';
import '../../domain/models/user_level_model.dart';

class AchievementsDashboardScreen extends ConsumerWidget {
  const AchievementsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unlockedAsync = ref.watch(_unlockedAchievementsProvider(user.uid));
    final levelAsync = ref.watch(_userLevelProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: levelAsync.when(
        data: (levelData) {
          return unlockedAsync.when(
            data: (unlockedList) {
              return _buildDashboard(context, levelData, unlockedList);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, UserLevelModel level, List<AchievementModel> unlockedList) {
    // Map unlocked list for quick lookup
    final unlockedMap = {for (var a in unlockedList) a.id: a};

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLevelCard(context, level),
                const SizedBox(height: AppDimensions.spacingLg),
                _buildStreakCard(context, level),
                const SizedBox(height: AppDimensions.spacingXl),
                Text(
                  'Your Badges',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Group by category
        for (var category in AchievementCategory.values)
          ..._buildCategorySection(context, category, unlockedMap),
          
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildLevelCard(BuildContext context, UserLevelModel level) {
    final currentXp = level.totalXp;
    final xpForCurrentLevel = AchievementConfig.calculateXpForLevel(level.currentLevel);
    final xpForNextLevel = level.xpForNextLevel;

    // Progress in the current level band
    final progressInLevel = currentXp - xpForCurrentLevel;
    final totalInLevel = xpForNextLevel - xpForCurrentLevel;
    final progressPercent = totalInLevel == 0 ? 1.0 : (progressInLevel / totalInLevel).clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          children: [
            Text(
              'Level ${level.currentLevel}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            LinearProgressIndicator(
              value: progressPercent,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentXp XP',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                Text(
                  'Next: $xpForNextLevel XP',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, UserLevelModel level) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Current Streak',
            value: '${level.currentLoginStreak} Days',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: _StatBox(
            label: 'Best Streak',
            value: '${level.longestLoginStreak} Days',
            icon: Icons.workspace_premium,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategorySection(BuildContext context, AchievementCategory category, Map<String, AchievementModel> unlockedMap) {
    final achievements = AchievementConfig.predefinedAchievements.where((a) => a.category == category).toList();
    if (achievements.isEmpty) return [];

    final categoryName = category.name[0].toUpperCase() + category.name.substring(1);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg, vertical: AppDimensions.spacingMd),
          child: Text(
            categoryName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppDimensions.spacingMd,
            mainAxisSpacing: AppDimensions.spacingMd,
            childAspectRatio: 0.8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final def = achievements[index];
              final unlocked = unlockedMap[def.id];
              return _AchievementBadge(
                definition: def,
                unlockedState: unlocked,
              );
            },
            childCount: achievements.length,
          ),
        ),
      ),
    ];
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final AchievementModel definition;
  final AchievementModel? unlockedState;

  const _AchievementBadge({
    required this.definition,
    this.unlockedState,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = unlockedState?.isUnlocked ?? false;
    final progress = unlockedState?.currentProgress ?? 0;
    
    final color = _getColorForRarity(definition.rarity);

    return Tooltip(
      message: '${definition.title}\n${definition.description}\n($progress/${definition.targetProgress})',
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Container(
          decoration: BoxDecoration(
            color: isUnlocked ? color.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isUnlocked ? color : Theme.of(context).dividerColor,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUnlocked ? Icons.stars : Icons.lock,
                color: isUnlocked ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXs),
                child: Text(
                  definition.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isUnlocked && definition.targetProgress > 1)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.spacingXs),
                  child: Text(
                    '$progress / ${definition.targetProgress}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForRarity(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common: return Colors.blue;
      case BadgeRarity.rare: return Colors.purple;
      case BadgeRarity.epic: return Colors.orange;
      case BadgeRarity.legendary: return Colors.red;
    }
  }
}

final _unlockedAchievementsProvider = StreamProvider.family<List<AchievementModel>, String>((ref, userId) {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.watchUnlockedAchievements(userId);
});

final _userLevelProvider = StreamProvider.family<UserLevelModel, String>((ref, userId) {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.watchUserLevel(userId);
});
