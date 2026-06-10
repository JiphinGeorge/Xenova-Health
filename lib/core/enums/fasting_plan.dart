/// Represents the type of intermittent fasting plan.
enum FastingPlan {
  custom,
  twelveTwelve,
  fourteenTen,
  sixteenEight,
  eighteenSix,
  twentyFour,
  omad,
}

extension FastingPlanExtension on FastingPlan {
  String get displayName {
    switch (this) {
      case FastingPlan.custom:
        return 'Custom';
      case FastingPlan.twelveTwelve:
        return '12:12';
      case FastingPlan.fourteenTen:
        return '14:10';
      case FastingPlan.sixteenEight:
        return '16:8';
      case FastingPlan.eighteenSix:
        return '18:6';
      case FastingPlan.twentyFour:
        return '20:4';
      case FastingPlan.omad:
        return 'OMAD';
    }
  }

  double get defaultDurationHours {
    switch (this) {
      case FastingPlan.custom:
        return 16.0;
      case FastingPlan.twelveTwelve:
        return 12.0;
      case FastingPlan.fourteenTen:
        return 14.0;
      case FastingPlan.sixteenEight:
        return 16.0;
      case FastingPlan.eighteenSix:
        return 18.0;
      case FastingPlan.twentyFour:
        return 20.0;
      case FastingPlan.omad:
        return 23.0; // Typically OMAD is around 23 hours fasting, 1 hour eating
    }
  }
}
