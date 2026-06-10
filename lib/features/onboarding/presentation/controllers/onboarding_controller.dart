import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Holds the temporary state of the onboarding wizard.
class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.currentWeightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.primaryGoal,
    this.preferredDiet,
    this.fastingPlan,
    this.dailyWaterGoalMl,
  });

  final int currentStep;
  final String? name;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final ActivityLevel? activityLevel;
  final PrimaryGoal? primaryGoal;
  final DietType? preferredDiet;
  final FastingPlan? fastingPlan;
  final int? dailyWaterGoalMl;

  OnboardingState copyWith({
    int? currentStep,
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    PrimaryGoal? primaryGoal,
    DietType? preferredDiet,
    FastingPlan? fastingPlan,
    int? dailyWaterGoalMl,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      preferredDiet: preferredDiet ?? this.preferredDiet,
      fastingPlan: fastingPlan ?? this.fastingPlan,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setPersonalInfo({String? name, int? age, Gender? gender}) {
    state = state.copyWith(name: name, age: age, gender: gender);
  }

  void setBodyMetrics({
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
  }) {
    state = state.copyWith(
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
    );
  }

  void setActivityLevel(ActivityLevel level) {
    state = state.copyWith(activityLevel: level);
  }

  void setPrimaryGoal(PrimaryGoal goal) {
    state = state.copyWith(primaryGoal: goal);
  }

  void setDietType(DietType diet) {
    state = state.copyWith(preferredDiet: diet);
  }

  void setFastingPlan(FastingPlan plan) {
    state = state.copyWith(fastingPlan: plan);
  }

  void setWaterGoal(int? ml) {
    state = state.copyWith(dailyWaterGoalMl: ml);
  }

  /// Finalizes onboarding and saves data to the user model.
  Future<void> completeOnboarding() async {
    final authController = ref.read(authControllerProvider.notifier);
    final currentUser = ref.read(authControllerProvider).value;

    if (currentUser == null) throw Exception('User not authenticated');

    final updatedUser = currentUser.copyWith(
      displayName: state.name,
      age: state.age,
      gender: state.gender,
      heightCm: state.heightCm,
      currentWeightKg: state.currentWeightKg,
      targetWeightKg: state.targetWeightKg,
      activityLevel: state.activityLevel,
      primaryGoal: state.primaryGoal,
      preferredDiet: state.preferredDiet,
      fastingPlan: state.fastingPlan,
      dailyWaterGoalMl: state.dailyWaterGoalMl,
      isOnboardingComplete: true,
    );

    await authController.saveUserProfile(updatedUser);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(() {
      return OnboardingController();
    });
