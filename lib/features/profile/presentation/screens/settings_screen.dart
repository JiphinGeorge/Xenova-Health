import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/enums.dart';
import '../../../ai_coach/presentation/controllers/ai_coach_controller.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../core/config/app_info.dart';
import '../../../core/storage/data/storage_provider.dart';
import '../../../gamification/presentation/controllers/achievements_controller.dart';
import '../../../progress_photos/presentation/controllers/progress_photos_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/profile_photo_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _goalWeightController;
  late TextEditingController _waterGoalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _goalWeightController = TextEditingController();
    _waterGoalController = TextEditingController();
    
    // Initialize fields with current user state after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _goalWeightController.text = user.targetWeightKg?.toString() ?? '';
        _waterGoalController.text = user.dailyWaterGoalMl?.toString() ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalWeightController.dispose();
    _waterGoalController.dispose();
    super.dispose();
  }

  Future<void> _updateProfileField(UserModel user, UserModel Function(UserModel) updater) async {
    try {
      final updated = updater(user);
      await ref.read(authControllerProvider.notifier).saveUserProfile(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> _showDoubleConfirmationDialog({
    required String title,
    required String instruction,
    required String validationWord,
    required VoidCallback onConfirm,
  }) async {
    final controller = TextEditingController();
    bool isValid = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(instruction),
                  const SizedBox(height: AppDimensions.spacingMd),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Type $validationWord to confirm',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        isValid = val.trim().toUpperCase() == validationWord.toUpperCase();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: isValid
                      ? () {
                          Navigator.pop(context);
                          onConfirm();
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('CONFIRM'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  void _showMockDocument(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final appInfoAsync = ref.watch(appInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found. Please log in again.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Section
                _buildSectionTitle('Profile'),
                const SizedBox(height: AppDimensions.spacingMd),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: ProfilePhotoPicker(radius: 50)),
                        const SizedBox(height: AppDimensions.spacingLg),
                        
                        // Edit Display Name
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          onSubmitted: (val) {
                            _updateProfileField(user, (u) => u.copyWith(displayName: val.trim()));
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),

                        // Goal Weight
                        TextField(
                          controller: _goalWeightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Goal Weight (kg)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monitor_weight_outlined),
                          ),
                          onSubmitted: (val) {
                            final weight = double.tryParse(val);
                            if (weight != null) {
                              _updateProfileField(user, (u) => u.copyWith(targetWeightKg: weight));
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),

                        // Daily Water Goal
                        TextField(
                          controller: _waterGoalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Daily Water Goal (ml)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.water_drop_outlined),
                          ),
                          onSubmitted: (val) {
                            final water = int.tryParse(val);
                            if (water != null) {
                              _updateProfileField(user, (u) => u.copyWith(dailyWaterGoalMl: water));
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),

                        // Activity Level Dropdown
                        DropdownButtonFormField<ActivityLevel>(
                          value: user.activityLevel,
                          decoration: const InputDecoration(
                            labelText: 'Activity Level',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.fitness_center_outlined),
                          ),
                          items: ActivityLevel.values.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(level.displayName),
                            );
                          }).toList(),
                          onChanged: (level) {
                            if (level != null) {
                              _updateProfileField(user, (u) => u.copyWith(activityLevel: level));
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),

                        // Diet Preference Dropdown
                        DropdownButtonFormField<DietType>(
                          value: user.preferredDiet,
                          decoration: const InputDecoration(
                            labelText: 'Diet Type',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.restaurant_menu_outlined),
                          ),
                          items: DietType.values.map((diet) {
                            return DropdownMenuItem(
                              value: diet,
                              child: Text(diet.displayName),
                            );
                          }).toList(),
                          onChanged: (diet) {
                            if (diet != null) {
                              _updateProfileField(user, (u) => u.copyWith(preferredDiet: diet));
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),

                        // Fasting Plan Dropdown
                        DropdownButtonFormField<FastingPlan>(
                          value: user.fastingPlan,
                          decoration: const InputDecoration(
                            labelText: 'Fasting Plan',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          items: FastingPlan.values.map((plan) {
                            return DropdownMenuItem(
                              value: plan,
                              child: Text(plan.displayName),
                            );
                          }).toList(),
                          onChanged: (plan) {
                            if (plan != null) {
                              _updateProfileField(user, (u) => u.copyWith(fastingPlan: plan));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                // 2. Appearance Section
                _buildSectionTitle('Appearance'),
                const SizedBox(height: AppDimensions.spacingMd),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('System Default'),
                          value: 'system',
                          groupValue: settings.themeMode,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(settingsControllerProvider.notifier).updateThemeMode(val);
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Light Theme'),
                          value: 'light',
                          groupValue: settings.themeMode,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(settingsControllerProvider.notifier).updateThemeMode(val);
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Dark Theme'),
                          value: 'dark',
                          groupValue: settings.themeMode,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(settingsControllerProvider.notifier).updateThemeMode(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                // 3. Notifications Section
                _buildSectionTitle('Notifications'),
                const SizedBox(height: AppDimensions.spacingMd),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      _buildReminderSwitchTile(
                        title: 'Weight Reminders',
                        enabled: settings.weightReminderEnabled,
                        time: settings.weightReminderTime,
                        onToggle: (val) => ref.read(settingsControllerProvider.notifier).toggleWeightReminder(val),
                        onTimeTap: () => _selectTime(
                          context,
                          settings.weightReminderTime,
                          (time) => ref.read(settingsControllerProvider.notifier).updateWeightReminderTime(time),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildReminderSwitchTile(
                        title: 'Meal Reminders',
                        enabled: settings.mealReminderEnabled,
                        time: settings.mealReminderTime,
                        onToggle: (val) => ref.read(settingsControllerProvider.notifier).toggleMealReminder(val),
                        onTimeTap: () => _selectTime(
                          context,
                          settings.mealReminderTime,
                          (time) => ref.read(settingsControllerProvider.notifier).updateMealReminderTime(time),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildReminderSwitchTile(
                        title: 'Fasting Reminders',
                        enabled: settings.fastingReminderEnabled,
                        time: settings.fastingReminderTime,
                        onToggle: (val) => ref.read(settingsControllerProvider.notifier).toggleFastingReminder(val),
                        onTimeTap: () => _selectTime(
                          context,
                          settings.fastingReminderTime,
                          (time) => ref.read(settingsControllerProvider.notifier).updateFastingReminderTime(time),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildReminderSwitchTile(
                        title: 'Weekly Summary Reminders',
                        enabled: settings.weeklySummaryEnabled,
                        time: settings.weeklySummaryTime,
                        onToggle: (val) => ref.read(settingsControllerProvider.notifier).toggleWeeklySummaryEnabled(val),
                        onTimeTap: () => _selectTime(
                          context,
                          settings.weeklySummaryTime,
                          (time) => ref.read(settingsControllerProvider.notifier).updateWeeklySummaryTime(time),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                // 4. AI Coach Section
                _buildSectionTitle('AI Coach'),
                const SizedBox(height: AppDimensions.spacingMd),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingLg),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Weekly Summaries'),
                          subtitle: const Text('Let the AI Coach generate personalized weekly reports'),
                          value: settings.weeklySummaryToggle,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => ref.read(settingsControllerProvider.notifier).toggleWeeklySummary(val),
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        DropdownButtonFormField<CoachTone>(
                          value: settings.coachTone,
                          decoration: const InputDecoration(
                            labelText: 'AI Coach Tone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.psychology_outlined),
                          ),
                          items: CoachTone.values.map((tone) {
                            return DropdownMenuItem(
                              value: tone,
                              child: Text(tone.label),
                            );
                          }).toList(),
                          onChanged: (tone) {
                            if (tone != null) {
                              ref.read(settingsControllerProvider.notifier).updateCoachTone(tone);
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingLg),
                        ListTile(
                          leading: const Icon(Icons.chat_bubble_outline, color: AppColors.error),
                          title: const Text('Clear Chat History', style: TextStyle(color: AppColors.error)),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            _showDoubleConfirmationDialog(
                              title: 'Clear Chat History?',
                              instruction: 'This will delete all conversation logs with your AI Coach. This action cannot be undone.',
                              validationWord: 'DELETE',
                              onConfirm: () async {
                                await ref.read(aiCoachControllerProvider.notifier).clearChatHistory();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Chat history cleared.')),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                // 5. Data Management Section
                _buildSectionTitle('Data Management'),
                const SizedBox(height: AppDimensions.spacingMd),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.file_download_outlined),
                        title: const Text('Export Health Data'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.exportData),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                        title: const Text('Delete Progress Photos', style: TextStyle(color: AppColors.error)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showDoubleConfirmationDialog(
                            title: 'Delete All Progress Photos?',
                            instruction: 'This will permanently delete ALL progress photos from storage and metadata database.',
                            validationWord: 'DELETE',
                            onConfirm: () async {
                              await ref.read(progressPhotosControllerProvider.notifier).deleteAllPhotos();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All progress photos deleted.')),
                                );
                            },
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.error),
                        title: const Text('Clear Local Cache', style: TextStyle(color: AppColors.error)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showDoubleConfirmationDialog(
                            title: 'Clear Local Cache?',
                            instruction: 'This will clear all offline databases (logs, cache, stats) and restart databases. Active preferences remain.',
                            validationWord: 'CLEAR',
                            onConfirm: () async {
                              await ref.read(settingsControllerProvider.notifier).clearLocalCache();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Local cache cleared.')),
                                );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                // 6. About Section
                _buildSectionTitle('About'),
                const SizedBox(height: AppDimensions.spacingMd),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingLg),
                    child: Column(
                      children: [
                        appInfoAsync.when(
                          data: (dynamic info) => Column(
                            children: [
                              _buildAboutRow('Version', info.version as String),
                              const Divider(height: 1),
                              _buildAboutRow('Build Number', info.buildNumber as String),
                              const Divider(height: 1),
                              _buildAboutRow('Environment', info.environment as String),
                              const Divider(height: 1),
                              _buildAboutRow('Flutter Version', '3.x'),
                              const Divider(height: 1),
                              _buildAboutRow('Backend', 'Firebase'),
                              const Divider(height: 1),
                              _buildAboutRow('AI', 'Gemini Enabled'),
                            ],
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (err, _) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Error loading info: $err', style: const TextStyle(color: AppColors.error)),
                          ),
                        ),
                        ListTile(
                          title: const Text('Privacy Policy'),
                          contentPadding: EdgeInsets.zero,
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _showMockDocument(
                            'Privacy Policy',
                            'Xenova Health values your privacy. We store and encrypt your physical data on Firestore. We never sell your statistics, weight entries, or meal logs. Data remains yours and can be exported or purged at any time.',
                          ),
                        ),
                        ListTile(
                          title: const Text('Terms of Service'),
                          contentPadding: EdgeInsets.zero,
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _showMockDocument(
                            'Terms of Service',
                            'By using Xenova Health and the Gemini AI coach, you agree that information provided is educational and supportive only. It does not constitute medical diagnosis or certified clinical advice. Consult medical professionals before making major lifestyle adjustments.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildReminderSwitchTile({
    required String title,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    final formattedTime = time.format(context);
    return SwitchListTile(
      title: Text(title),
      subtitle: InkWell(
        onTap: enabled ? onTimeTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                formattedTime,
                style: TextStyle(
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  decoration: enabled ? TextDecoration.none : TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ),
      ),
      value: enabled,
      onChanged: onToggle,
    );
  }

  Widget _buildAboutRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
