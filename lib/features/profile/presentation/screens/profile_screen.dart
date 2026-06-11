import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/lifetime_stats_repository.dart';
import '../widgets/profile_photo_picker.dart';

/// Screen displaying the user's profile information and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimensions.spacingXl),
                  const Center(child: ProfilePhotoPicker(radius: 64)),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Text(
                    user.displayName ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacing3xl),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.emoji_events),
                          title: const Text('Achievements & Level'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.achievements),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.photo_camera_back),
                          title: const Text('Progress Photos'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.progressPhotos),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.account_circle_outlined),
                          title: const Text('Account Details'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.bar_chart),
                          title: const Text('Analytics'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.reports),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.file_download_outlined),
                          title: const Text('Export Data'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.exportData),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.error,
                          ),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(color: AppColors.error),
                          ),
                          onTap: () {
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  Text(
                    'Lifetime Stats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _buildLifetimeStatsGrid(context, ref, user.uid),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildLifetimeStatsGrid(BuildContext context, WidgetRef ref, String userId) {
    final statsAsync = ref.watch(lifetimeStatsStreamProvider);

    return statsAsync.when(
      data: (stats) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimensions.spacingMd,
          crossAxisSpacing: AppDimensions.spacingMd,
          childAspectRatio: 1.5,
          children: [
            _LifetimeStatCard(
              title: 'Weight Logs',
              value: '${stats.totalWeightEntries}',
              icon: Icons.monitor_weight_outlined,
              color: Colors.orange,
            ),
            _LifetimeStatCard(
              title: 'Meals Logged',
              value: '${stats.totalMealsLogged}',
              icon: Icons.restaurant_outlined,
              color: Colors.blue,
            ),
            _LifetimeStatCard(
              title: 'Fasts Completed',
              value: '${stats.totalFastsCompleted}',
              icon: Icons.timer_outlined,
              color: Colors.purple,
            ),
            _LifetimeStatCard(
              title: 'Progress Photos',
              value: '${stats.totalProgressPhotos}',
              icon: Icons.photo_camera_back_outlined,
              color: Colors.green,
            ),
            _LifetimeStatCard(
              title: 'AI Chats',
              value: '${stats.totalAIChats}',
              icon: Icons.auto_awesome,
              color: Colors.cyan,
            ),
            _LifetimeStatCard(
              title: 'Days Tracked',
              value: '${stats.totalDaysTracked}',
              icon: Icons.calendar_today_outlined,
              color: Colors.amber,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _LifetimeStatCard extends StatelessWidget {
  const _LifetimeStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppDimensions.spacingXs),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
