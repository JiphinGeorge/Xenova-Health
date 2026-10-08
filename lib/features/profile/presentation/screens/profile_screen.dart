import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/activity_level.dart';
import '../../../../core/enums/diet_type.dart';
import '../../../../core/enums/fasting_plan.dart';
import '../../../../core/enums/gender.dart';
import '../../../../core/enums/primary_goal.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/lifetime_stats_repository.dart';
import '../widgets/profile_photo_picker.dart';

/// Screen displaying the user's profile information, vitals, lifetime stats, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final user = userAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: user == null
          ? _buildGuestOrLoading(context, ref, userAsync.isLoading)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
                vertical: AppDimensions.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Profile Avatar & Name Section
                  _buildHeader(context, ref, user),
                  const SizedBox(height: AppDimensions.spacingLg),

                  // 2. Health Vitals Card
                  _buildVitalsCard(context, ref, user),
                  const SizedBox(height: AppDimensions.spacingLg),

                  // 3. Navigation List Card
                  _buildMenuCard(context, ref, user),
                  const SizedBox(height: AppDimensions.spacingXl),

                  // 4. Lifetime Stats Grid
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

  Widget _buildGuestOrLoading(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.grey),
            const SizedBox(height: AppDimensions.spacingMd),
            const Text(
              'No active profile found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            const Text(
              'Please log in or refresh your session to view your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.login),
              icon: const Icon(Icons.login),
              label: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserModel user) {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.spacingSm),
        const Center(child: ProfilePhotoPicker(radius: 56)),
        const SizedBox(height: AppDimensions.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                user.displayName?.isNotEmpty == true
                    ? user.displayName!
                    : 'Health Enthusiast',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit Profile',
              onPressed: () => _showEditProfileModal(context, ref, user),
            ),
          ],
        ),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVitalsCard(BuildContext context, WidgetRef ref, UserModel user) {
    final weight = user.currentWeightKg;
    final targetWeight = user.targetWeightKg;
    final height = user.heightCm;
    final waterGoal = user.dailyWaterGoalMl ?? 2000;

    double? bmi;
    String bmiCategory = '';
    if (weight != null && height != null && height > 0) {
      bmi = weight / ((height / 100) * (height / 100));
      if (bmi < 18.5) {
        bmiCategory = 'Underweight';
      } else if (bmi < 25.0) {
        bmiCategory = 'Normal';
      } else if (bmi < 30.0) {
        bmiCategory = 'Overweight';
      } else {
        bmiCategory = 'Obese';
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _VitalItem(
                    label: 'Weight',
                    value: weight != null
                        ? '${weight.toStringAsFixed(1)} kg'
                        : '--',
                    subtext: targetWeight != null
                        ? 'Goal: ${targetWeight.toStringAsFixed(1)} kg'
                        : 'No target',
                    icon: Icons.monitor_weight_outlined,
                    color: Colors.orange,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _VitalItem(
                    label: 'Height',
                    value: height != null ? '${height.toInt()} cm' : '--',
                    subtext: bmi != null
                        ? 'BMI ${bmi.toStringAsFixed(1)} ($bmiCategory)'
                        : '--',
                    icon: Icons.height_outlined,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _VitalItem(
                    label: 'Hydration Goal',
                    value: '$waterGoal ml',
                    subtext: '${(waterGoal / 250).round()} glasses',
                    icon: Icons.water_drop_outlined,
                    color: Colors.cyan,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _VitalItem(
                    label: 'Primary Goal',
                    value: user.primaryGoal?.label ?? 'Healthy Living',
                    subtext: user.activityLevel?.label ?? 'Active',
                    icon: Icons.track_changes_outlined,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, WidgetRef ref, UserModel user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: const Text('Account Details'),
            subtitle: const Text('Name, Age, Height, Weight, Goals'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEditProfileModal(context, ref, user),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.timer_outlined, color: Colors.purple),
            title: const Text('Fasting Plan'),
            subtitle: Text(user.fastingPlan?.displayName ?? 'Not set'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangeFastingPlanModal(context, ref, user),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.restaurant_menu_outlined,
              color: Colors.green,
            ),
            title: const Text('Diet Type'),
            subtitle: Text(user.preferredDiet?.label ?? 'Not set'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangeDietTypeModal(context, ref, user),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.amber,
            ),
            title: const Text('Achievements & Level'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.achievements),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.photo_camera_back_outlined,
              color: Colors.teal,
            ),
            title: const Text('Progress Photos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.progressPhotos),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined, color: Colors.indigo),
            title: const Text('Analytics & Reports'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.reports),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.file_download_outlined,
              color: Colors.deepPurple,
            ),
            title: const Text('Export Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.exportData),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.blueGrey),
            title: const Text('Settings & Preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settings),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileBottomSheet(user: user, ref: ref),
    );
  }

  void _showChangeFastingPlanModal(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change Fasting Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...FastingPlan.values.map((plan) {
                  final isSelected = user.fastingPlan == plan;
                  return ListTile(
                    leading: Icon(
                      Icons.timer_outlined,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(
                      plan.displayName,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    subtitle: Text(
                      plan == FastingPlan.custom
                          ? 'Customizable fasting duration'
                          : '${plan.defaultDurationHours.toInt()} hours fasting target',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final updated = user.copyWith(fastingPlan: plan);
                        await ref
                            .read(authControllerProvider.notifier)
                            .saveUserProfile(updated);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Fasting plan updated successfully to ${plan.displayName}!',
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to update fasting plan: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeDietTypeModal(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change Diet Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...DietType.values.map((diet) {
                  final isSelected = user.preferredDiet == diet;
                  return ListTile(
                    leading: Icon(
                      Icons.restaurant_menu,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(
                      diet.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    subtitle: Text(
                      diet.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final updated = user.copyWith(preferredDiet: diet);
                        await ref
                            .read(authControllerProvider.notifier)
                            .saveUserProfile(updated);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Diet type updated successfully to ${diet.label}!',
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update diet type: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLifetimeStatsGrid(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
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
              title: 'AI Coach',
              value: 'Phase 2',
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

class _VitalItem extends StatelessWidget {
  const _VitalItem({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtext,
            style: TextStyle(fontSize: 11, color: secondaryColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EditProfileBottomSheet extends StatefulWidget {
  const _EditProfileBottomSheet({required this.user, required this.ref});

  final UserModel user;
  final WidgetRef ref;

  @override
  State<_EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _waterGoalController;

  Gender? _gender;
  PrimaryGoal? _primaryGoal;
  ActivityLevel? _activityLevel;
  DietType? _dietType;
  FastingPlan? _fastingPlan;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u.displayName ?? '');
    _ageController = TextEditingController(text: u.age?.toString() ?? '');
    _heightController = TextEditingController(
      text: u.heightCm?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: u.currentWeightKg?.toString() ?? '',
    );
    _targetWeightController = TextEditingController(
      text: u.targetWeightKg?.toString() ?? '',
    );
    _waterGoalController = TextEditingController(
      text: (u.dailyWaterGoalMl ?? 2000).toString(),
    );

    _gender = u.gender;
    _primaryGoal = u.primaryGoal;
    _activityLevel = u.activityLevel;
    _dietType = u.preferredDiet;
    _fastingPlan = u.fastingPlan;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _waterGoalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final updatedUser = widget.user.copyWith(
        displayName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : widget.user.displayName,
        age: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        heightCm: double.tryParse(_heightController.text.trim()),
        currentWeightKg: double.tryParse(_weightController.text.trim()),
        targetWeightKg: double.tryParse(_targetWeightController.text.trim()),
        dailyWaterGoalMl:
            int.tryParse(_waterGoalController.text.trim()) ?? 2000,
        primaryGoal: _primaryGoal,
        activityLevel: _activityLevel,
        preferredDiet: _dietType,
        fastingPlan: _fastingPlan,
      );

      await widget.ref
          .read(authControllerProvider.notifier)
          .saveUserProfile(updatedUser);

      // Determine what specifically changed to give a clear, informative toast
      String message = 'Profile details updated successfully!';
      final changes = <String>[];
      if (widget.user.fastingPlan != updatedUser.fastingPlan &&
          updatedUser.fastingPlan != null) {
        changes.add('Fasting plan');
      }
      if (widget.user.preferredDiet != updatedUser.preferredDiet &&
          updatedUser.preferredDiet != null) {
        changes.add('Diet type');
      }
      if (widget.user.displayName != updatedUser.displayName &&
          _nameController.text.trim().isNotEmpty) {
        changes.add('Display name');
      }
      if (widget.user.currentWeightKg != updatedUser.currentWeightKg ||
          widget.user.targetWeightKg != updatedUser.targetWeightKg) {
        changes.add('Weight goals');
      }
      if (widget.user.heightCm != updatedUser.heightCm) {
        changes.add('Height');
      }
      if (widget.user.dailyWaterGoalMl != updatedUser.dailyWaterGoalMl) {
        changes.add('Water goal');
      }
      if (widget.user.primaryGoal != updatedUser.primaryGoal &&
          updatedUser.primaryGoal != null) {
        changes.add('Primary goal');
      }
      if (widget.user.activityLevel != updatedUser.activityLevel &&
          updatedUser.activityLevel != null) {
        changes.add('Activity level');
      }

      if (changes.length == 1) {
        if (changes.first == 'Fasting plan') {
          message =
              'Fasting plan updated successfully to ${updatedUser.fastingPlan!.displayName}!';
        } else if (changes.first == 'Diet type') {
          message =
              'Diet type updated successfully to ${updatedUser.preferredDiet!.label}!';
        } else if (changes.first == 'Display name') {
          message =
              'Display name updated successfully to ${updatedUser.displayName}!';
        } else {
          message = '${changes.first} updated successfully!';
        }
      } else if (changes.isNotEmpty) {
        message = '${changes.join(", ")} updated successfully!';
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: AppDimensions.spacingLg,
        left: AppDimensions.spacingLg,
        right: AppDimensions.spacingLg,
        bottom: bottomInset + AppDimensions.spacingLg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.cake_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: DropdownButtonFormField<Gender>(
                            value: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                            ),
                            items: Gender.values.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text(g.label),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _gender = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              prefixIcon: Icon(Icons.height),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Current Wt (kg)',
                              prefixIcon: Icon(Icons.monitor_weight_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _targetWeightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Target Wt (kg)',
                              prefixIcon: Icon(Icons.flag_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: TextField(
                            controller: _waterGoalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Water Goal (ml)',
                              prefixIcon: Icon(Icons.water_drop_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    DropdownButtonFormField<PrimaryGoal>(
                      value: _primaryGoal,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Primary Goal',
                        prefixIcon: Icon(Icons.track_changes_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: PrimaryGoal.values.map((goal) {
                        return DropdownMenuItem(
                          value: goal,
                          child: Text(goal.label),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _primaryGoal = val),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    DropdownButtonFormField<ActivityLevel>(
                      value: _activityLevel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Activity Level',
                        prefixIcon: Icon(Icons.directions_run),
                        border: OutlineInputBorder(),
                      ),
                      items: ActivityLevel.values.map((act) {
                        return DropdownMenuItem(
                          value: act,
                          child: Text('${act.label} (${act.description})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _activityLevel = val),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<DietType>(
                            value: _dietType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Diet Type',
                              border: OutlineInputBorder(),
                            ),
                            items: DietType.values.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(d.label),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _dietType = val),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: DropdownButtonFormField<FastingPlan>(
                            value: _fastingPlan,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Fasting Plan',
                              border: OutlineInputBorder(),
                            ),
                            items: FastingPlan.values.map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(f.displayName),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _fastingPlan = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : const Color.fromRGBO(60, 48, 32, 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
