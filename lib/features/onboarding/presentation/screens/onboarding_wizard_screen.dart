import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/enums.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    final state = ref.read(onboardingControllerProvider);

    if (state.currentStep < 6) {
      ref.read(onboardingControllerProvider.notifier).nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    final state = ref.read(onboardingControllerProvider);

    if (state.currentStep > 0) {
      ref.read(onboardingControllerProvider.notifier).previousStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding();
      // GoRouter redirect handles navigation automatically
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    const totalSteps = 7;
    final progress = (state.currentStep + 1) / totalSteps;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header & Progress
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
                vertical: AppDimensions.spacingMd,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: state.currentStep > 0 ? _prevPage : null,
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.primarySurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _StepPersonalInfo(),
                  _StepBodyMetrics(),
                  _StepActivityLevel(),
                  _StepPrimaryGoal(),
                  _StepNutrition(),
                  _StepFasting(),
                  _StepWaterGoal(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _nextPage,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(state.currentStep == 6 ? 'Complete Profile' : 'Continue'),
        ),
      ),
    );
  }
}

// ─── Step 1: Personal Info ───
class _StepPersonalInfo extends ConsumerStatefulWidget {
  const _StepPersonalInfo();

  @override
  ConsumerState<_StepPersonalInfo> createState() => _StepPersonalInfoState();
}

class _StepPersonalInfoState extends ConsumerState<_StepPersonalInfo> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    _nameController = TextEditingController(text: state.name);
    _ageController = TextEditingController(text: state.age?.toString());

    _nameController.addListener(_updateState);
    _ageController.addListener(_updateState);
  }

  void _updateState() {
    ref
        .read(onboardingControllerProvider.notifier)
        .setPersonalInfo(
          name: _nameController.text.trim(),
          age: int.tryParse(_ageController.text),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gender = ref.watch(
      onboardingControllerProvider.select((s) => s.gender),
    );

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Let\'s get to know you',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          TextField(
            controller: _ageController,
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          Text('Gender', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spacingMd),
          Wrap(
            spacing: AppDimensions.spacingMd,
            runSpacing: AppDimensions.spacingMd,
            children: Gender.values.map((g) {
              final isSelected = gender == g;
              return ChoiceChip(
                label: Text(g.name.toUpperCase()),
                selected: isSelected,
                onSelected: (_) {
                  ref
                      .read(onboardingControllerProvider.notifier)
                      .setPersonalInfo(gender: g);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Body Metrics ───
class _StepBodyMetrics extends ConsumerStatefulWidget {
  const _StepBodyMetrics();

  @override
  ConsumerState<_StepBodyMetrics> createState() => _StepBodyMetricsState();
}

class _StepBodyMetricsState extends ConsumerState<_StepBodyMetrics> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    _heightController = TextEditingController(text: state.heightCm?.toString());
    _weightController = TextEditingController(
      text: state.currentWeightKg?.toString(),
    );
    _targetWeightController = TextEditingController(
      text: state.targetWeightKg?.toString(),
    );

    _heightController.addListener(_updateState);
    _weightController.addListener(_updateState);
    _targetWeightController.addListener(_updateState);
  }

  void _updateState() {
    ref
        .read(onboardingControllerProvider.notifier)
        .setBodyMetrics(
          heightCm: double.tryParse(_heightController.text),
          currentWeightKg: double.tryParse(_weightController.text),
          targetWeightKg: double.tryParse(_targetWeightController.text),
        );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Body Metrics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Used to calculate your daily caloric needs.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          TextField(
            controller: _heightController,
            decoration: const InputDecoration(labelText: 'Height (cm)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: 'Current Weight (kg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          TextField(
            controller: _targetWeightController,
            decoration: const InputDecoration(labelText: 'Target Weight (kg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Activity Level ───
class _StepActivityLevel extends ConsumerWidget {
  const _StepActivityLevel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(
      onboardingControllerProvider.select((s) => s.activityLevel),
    );

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How active are you?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          Expanded(
            child: ListView.separated(
              itemCount: ActivityLevel.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppDimensions.spacingMd),
              itemBuilder: (context, index) {
                final level = ActivityLevel.values[index];
                final isSelected = activity == level;

                return _SelectionCard(
                  title: _activityLabel(level),
                  subtitle: _activitySubtitle(level),
                  isSelected: isSelected,
                  onTap: () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setActivityLevel(level);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extraActive:
        return 'Extremely Active';
    }
  }

  String _activitySubtitle(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise/sports 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.extraActive:
        return 'Very hard physical job or training twice a day';
    }
  }
}

// ─── Step 4: Primary Goal ───
class _StepPrimaryGoal extends ConsumerWidget {
  const _StepPrimaryGoal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(
      onboardingControllerProvider.select((s) => s.primaryGoal),
    );

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What is your primary goal?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          Expanded(
            child: ListView.separated(
              itemCount: PrimaryGoal.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppDimensions.spacingMd),
              itemBuilder: (context, index) {
                final g = PrimaryGoal.values[index];
                return _SelectionCard(
                  title: g.label,
                  isSelected: goal == g,
                  onTap: () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setPrimaryGoal(g);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 5: Nutrition Preferences ───
class _StepNutrition extends ConsumerWidget {
  const _StepNutrition();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diet = ref.watch(
      onboardingControllerProvider.select((s) => s.preferredDiet),
    );

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Any dietary preferences?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          Expanded(
            child: ListView.separated(
              itemCount: DietType.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppDimensions.spacingMd),
              itemBuilder: (context, index) {
                final d = DietType.values[index];
                return _SelectionCard(
                  title: d.label,
                  isSelected: diet == d,
                  onTap: () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setDietType(d);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 6: Fasting Plan ───
class _StepFasting extends ConsumerWidget {
  const _StepFasting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(
      onboardingControllerProvider.select((s) => s.fastingPlan),
    );

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Intermittent Fasting?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Choose a fasting schedule if you practice intermittent fasting.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          Expanded(
            child: ListView.separated(
              itemCount: FastingPlan.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppDimensions.spacingMd),
              itemBuilder: (context, index) {
                final p = FastingPlan.values[index];
                if (p == FastingPlan.custom) {
                  return const SizedBox.shrink(); // Hide custom
                }
                return _SelectionCard(
                  title: p.displayName,
                  isSelected: plan == p,
                  onTap: () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setFastingPlan(p);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 7: Water Goal ───
class _StepWaterGoal extends ConsumerStatefulWidget {
  const _StepWaterGoal();

  @override
  ConsumerState<_StepWaterGoal> createState() => _StepWaterGoalState();
}

class _StepWaterGoalState extends ConsumerState<_StepWaterGoal> {
  late final TextEditingController _waterController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    _waterController = TextEditingController(
      text: state.dailyWaterGoalMl?.toString() ?? '2500',
    );
    // Initialize default if null
    if (state.dailyWaterGoalMl == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onboardingControllerProvider.notifier).setWaterGoal(2500);
      });
    }

    _waterController.addListener(() {
      ref
          .read(onboardingControllerProvider.notifier)
          .setWaterGoal(int.tryParse(_waterController.text));
    });
  }

  @override
  void dispose() {
    _waterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Daily Water Goal',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Staying hydrated is key to your health journey.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          TextField(
            controller: _waterController,
            decoration: const InputDecoration(
              labelText: 'Water Intake (ml)',
              suffixText: 'ml',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}

// ─── Common Widgets ───
class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : (isDark ? AppColors.elevatedDark : Colors.white),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppColors.primaryDark : null,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppColors.primaryDark.withValues(alpha: 0.8)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
