import 'package:flutter_test/flutter_test.dart';
import 'package:xenova_health/core/enums/enums.dart';
import 'package:xenova_health/features/auth/domain/models/user_model.dart';

void main() {
  group('UserModel effectiveWaterGoalMl Tests', () {
    test('returns explicitly stored dailyWaterGoalMl if present', () {
      final user = UserModel(
        uid: 'user_1',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        dailyWaterGoalMl: 3200,
        currentWeightKg: 70,
      );

      expect(user.effectiveWaterGoalMl, equals(3200));
    });

    test('calculates water goal dynamically based on weight and activity if dailyWaterGoalMl is null', () {
      final user = UserModel(
        uid: 'user_2',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        currentWeightKg: 70, // 70 * 35 = 2450
        activityLevel: ActivityLevel.veryActive, // + 500 = 2950
      );

      expect(user.effectiveWaterGoalMl, equals(2950));
    });

    test('calculates water goal with moderate activity adjustment', () {
      final user = UserModel(
        uid: 'user_3',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        currentWeightKg: 80, // 80 * 35 = 2800 + 250 = 3050
        activityLevel: ActivityLevel.moderatelyActive,
      );

      expect(user.effectiveWaterGoalMl, equals(3050));
    });

    test('falls back to 2500 if neither water goal nor weight is present', () {
      final user = UserModel(
        uid: 'user_4',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      expect(user.effectiveWaterGoalMl, equals(2500));
    });
  });
}
