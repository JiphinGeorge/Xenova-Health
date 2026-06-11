# Xenova Health

Xenova Health is a professional weight loss, nutrition, intermittent fasting, and fitness tracking application designed to combine health tracking, analytics, artificial intelligence, and user empowerment into a single modern wellness platform.

## Xenova Health Brand Identity

The Xenova Health visual identity is designed to represent personal transformation, health improvement, and technology-driven wellness. The primary logo features a modern stylized "X" that symbolizes growth, progress, and the journey toward healthier living. The blue and purple gradient reflects trust, intelligence, innovation, and the integration of artificial intelligence within the platform.

For mobile deployment, Xenova Health utilizes a simplified orange and gold icon derived from the brand identity. The icon represents vitality, energy, achievement, and human-centered wellness. Its minimal design ensures strong recognition across Android and iOS devices while maintaining consistency with the application's mission.

Together, the branding communicates Xenova Health's vision of combining health tracking, analytics, artificial intelligence, and user empowerment into a single modern wellness platform.

## Technology Stack
- **Framework**: Flutter
- **State Management**: Riverpod (`riverpod_annotation`, `riverpod_generator`)
- **Authentication**: Firebase Auth (Email/Password, Google, Apple)
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (with `flutter_image_compress` & `cached_network_image`)
- **Local Cache**: Hive
- **Artificial Intelligence**: Google Gemini (`google_generative_ai`)
- **Routing**: GoRouter
- **Data Models**: Freezed (`freezed_annotation`)

## Architecture
This project strictly follows the **Feature-First Architecture** inside the `lib/` folder:

```
lib/
├── app/                  # App-wide routing, theme, and localization
├── core/                 # Shared utilities, widgets, and services (Firebase, Storage)
└── features/             # Feature-based modular code
    ├── feature_name/
    │   ├── application/  # Service layer and use cases
    │   ├── data/         # Repositories and DTOs
    │   ├── domain/       # Models and entity definitions
    │   └── presentation/ # UI screens, widgets, and controllers
```

## Features & Modules Completed

- **Authentication**: Secure sign-in and account management.
- **Onboarding**: Step-by-step user onboarding and goal setting.
- **Dashboard**: High-level daily overview of all metrics.
- **Weight Tracking**: Daily weigh-ins, goals, and history.
- **Progress Photos**: Visual timeline and photo comparison.
- **Fasting Tracker**: Intermittent fasting timer with streaks and metrics.
- **Nutrition Tracking**: USDA API-powered meal logging and macro breakdown.
- **Water Tracking**: Daily hydration goals.
- **Analytics Engine**: Core logic for calculating the Health Score and generating reports.
- **AI Coach (Gemini)**: Intelligent health companion driven by analytics context.
- **Reports & Exports**: PDF/CSV exports of user data.
- **Gamification & Achievements**: Leveling system and milestone badges.
- **Notification Center**: Centralized alerts for achievements and milestones.
- **Settings & Preferences**: Customizable themes, units, and options.
- **Offline Support**: Robust local persistence with Hive.
- **Firebase Integration**: Firestore and Firebase Storage capabilities.
- **Clean Architecture**: Highly scalable feature-first codebase.
