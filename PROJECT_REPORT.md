# Xenova Health - Comprehensive Project Status & Technical Report

**Document Version:** 1.0.0  
**Generated Date:** March 2026  
**Platform:** Flutter (Android & iOS)  
**State Management:** Riverpod (Feature-First Architecture)  
**Backend & Database:** Firebase (Auth, Cloud Firestore, Cloud Storage, Analytics, Crashlytics)  
**Local Storage:** Hive & SharedPreferences  

---

## 1. Executive Summary

**Xenova Health** (internally structured as an advanced health and wellness platform) is a mobile application developed in Flutter. The platform unifies daily weight logging, calorie and macronutrient tracking, intermittent fasting management, AI-driven wellness coaching, photographic progress tracking, and gamified user engagement.

The architecture strictly adheres to **Feature-First Clean Architecture**, separating each capability into distinct domain, data, and presentation layers with dependency injection provided by Riverpod.

### Current Build & Compilation Status
- **Static Analyzer:** Clean — **0 compilation errors**, **0 analyzer warnings**.
- **Android Build:** Fully verified; compiles cleanly into debug APK (`assembleDevDebug`) targeting Android API 37 using Java 21 LTS.
- **Cross-Drive Compatibility:** Configured with `kotlin.incremental=false` and root-relative Gradle subproject paths to ensure smooth compilation across drive partitions (`C:\` and `D:\`).

---

## 2. Feature-by-Feature Implementation Status

Below is the detailed audit of all 14 feature modules, specifying exact implementation details, completed capabilities, and items that remain pending or require future integration.

---

### Feature 1: Authentication & User Management (`lib/features/auth`)

#### What Has Been Implemented
- **Firebase Authentication Integration:** Complete email and password registration, login, and password reset flows via `FirebaseAuthService`.
- **Google Sign-In:** SSO authentication via Google Sign-In SDK.
- **Session Management:** Reactive user state stream (`authStateChangesProvider`) routing authenticated users to the main dashboard and unauthenticated users to the login screen.
- **Firestore User Document Sync:** Automatic creation and synchronization of user documents in Firestore (`users/{uid}`) upon first sign-in.
- **Presentation Layer:** Production-ready screens:
  - `LoginScreen`: Email/password inputs, validation, Google SSO button, forgot password navigation.
  - `RegisterScreen`: Name, email, password confirmation, terms acceptance.
  - `ForgotPasswordScreen`: Password reset email dispatch.

#### What Has NOT Been Implemented / Pending
- **Apple Sign-In Flow:** `sign_in_with_apple` is in `pubspec.yaml`, but the Apple Sign-In UI button and backend credential exchange in `auth_repository.dart` are commented or pending Apple Developer account configuration.
- **Biometric Authentication:** No local biometric authentication (Face ID / Fingerprint lock) for quick app unlock.
- **Email Verification Guard:** App currently allows users to access the dashboard without strictly enforcing email verification.

---

### Feature 2: Onboarding Flow (`lib/features/onboarding`)

#### What Has Been Implemented
- **Multi-Step Onboarding Carousel:** Introduction to Xenova Health's core value propositions (AI coaching, fasting, nutrition tracking).
- **Initial Profile Setup:** Interactive screens capturing baseline health metrics:
  - Biological sex, age, height, current weight, and goal weight.
  - Activity level (Sedentary, Lightly Active, Moderately Active, Very Active, Extra Active).
  - Primary goal selection (Weight Loss, Muscle Gain, Maintenance, Better Energy).
- **Persistent State:** Flags user completion in SharedPreferences to prevent re-displaying onboarding on subsequent launches.

#### What Has NOT Been Implemented / Pending
- **Dynamic Onboarding Preview Calculations:** Automatically showing the calculated TDEE/BMR on the final onboarding slide before reaching the dashboard.

---

### Feature 3: Main Dashboard (`lib/features/dashboard`)

#### What Has Been Implemented
- **Daily Executive Overview:** Central screen summarizing key daily vitals at a glance:
  - **Daily Calorie & Macro Budget Ring:** Shows consumed vs. remaining calories, protein, carbs, and fats.
  - **Active Fasting Widget:** Real-time countdown timer showing current fast duration, target window, and fasting stage (e.g., Anabolic, Fat Burning, Ketosis).
  - **Quick Water Logger:** Increment/decrement buttons to quickly add water intake (250ml / 500ml steps).
  - **Weight Trajectory Card:** Displays current weight, delta from goal, and recent weekly trend.
  - **Overall Health Score Engine (`health_score_provider.dart`):** Dynamic multi-pillar composite health score (0–100) calculated continuously from real-time user metrics:
    - **Nutrition & Macros (35% weight):** Calorie target adherence, protein intake compliance, and daily meal count.
    - **Intermittent Fasting (25% weight):** Active fast progress, completion status, and multi-day streaks.
    - **Weight Tracking & Consistency (25% weight):** Weigh-in recency, BMI status classification, and goal progress.
    - **Hydration (15% weight):** Daily water intake vs. 2.5L goal.
  - **Interactive 4-Pillar Breakdown Bottom Sheet:** Tapping the Health Score card on the dashboard opens a detailed analysis sheet with individual progress bars, score weights, status tier (Needs Focus, Good, Excellent), and dynamic actionable tips to boost the score.
  - **Cross-Feature Sync & Offline Resilience:** Health scores are auto-synced into `DashboardStatsModel` and cached in local Hive (`cacheBox`) for offline access, report PDF/CSV export, and AI context feeding.
  - **Quick Action Bar:** Direct shortcuts to log meal, log weight, start fast, or chat with AI Coach.
  - **Daily Motivational Quote / Health Tip:** Context-aware tip generated based on daily progress.

#### What Has NOT Been Implemented / Pending
- **Customizable Dashboard Widgets:** Inability for users to reorder, hide, or customize which summary cards appear on the dashboard.

---

### Feature 4: Weight Tracking & Health Calculators (`lib/features/weight` & `lib/core/calculators`)

#### What Has Been Implemented
- **Weight Logging:** Users can log weight entries with date/time, weight value (kg/lbs), body fat percentage (optional), notes, and mood.
- **Time-Series Storage:** Stored under `users/{uid}/weight_entries` with real-time Firestore listeners.
- **Scientific Calculators (`lib/core/calculators`):**
  - `BMICalculator`: Calculates BMI and classifies into Underweight, Normal, Overweight, Obese Class I-III.
  - `BMRCalculator`: Implements the Mifflin-St Jeor equation factoring in sex, age, weight, and height.
  - `TDEECalculator`: Multiplies BMR by physical activity factor (1.2 to 1.9).
  - `CalorieDeficitCalculator`: Computes recommended daily calorie intake based on weight target speed (e.g., -500 kcal/day for 0.5 kg/week).
  - `WeightPredictionCalculator`: Projects future weight over a 4 to 12-week timeline based on current caloric deficit trends.
- **Interactive Weight Chart:** Powered by `fl_chart`, supporting 7-day, 30-day, 90-day, and all-time zoom levels.

#### What Has NOT Been Implemented / Pending
- **Smart Scale Hardware Sync:** No direct Bluetooth Low Energy (BLE) integration with smart scales (e.g., Withings, Renpho, Xiaomi).
- **Body Circumference Tracking:** Tracking chest, waist, hips, and bicep measurements is currently not supported in the database schema.

---

### Feature 5: Nutrition & Meal Tracking (`lib/features/nutrition`)

#### What Has Been Implemented
- **Multi-Meal Logging:** Categorization of food items into Breakfast, Lunch, Dinner, and Snacks.
- **Local-First Resilience & Instant Updates (Hive):**
  - All logged meals are saved immediately to local Hive (`meal_box`) and streamed reactively with `_mealBox.watch()`, updating the UI instantly without server or connection latency.
  - Daily summaries are saved locally in Hive (`daily_summary_box`) without relying on network transactions.
  - Background Firestore synchronization ensures cross-device backup whenever connectivity is available.
- **Self-Healing Daily Summary:** If the daily summary is out of sync or absent, the nutrition dashboard automatically aggregates macros and calories directly from that day's meal logs.
- **Dual Logging Modes:**
  - **Quick Log:** One-tap logging directly from the Food Details screen straight into the chosen meal category (Breakfast, Lunch, Dinner, Snack).
  - **Meal Builder:** Multi-item meal builder with portion scaling, food item removal, and review before batch saving.
- **Macronutrient Tracking:** Automated summing of Calories, Protein (g), Carbohydrates (g), and Fat (g) with progress indicators and goal bars.
- **Water Tracker:** Persistent daily hydration intake with progress toward user-defined goals (e.g., 2500 ml).
- **Food Database Repository (`food_database_repository.dart`):**
  - Case-insensitive prefix search against Firestore `food_database` collection using `searchName`.
  - **Embedded Seed Dataset:** Includes 26 pre-verified common staple foods (eggs, chicken breast, tuna, salmon, oats, Greek yogurt, brown rice, etc.) that automatically seed into Firestore if the database is empty.
- **Custom Food Creation (`custom_food_screen.dart`):** Users can define and save private foods with custom serving sizes and macro profiles to `users/{uid}/custom_foods`.
- **Serving Size Scaling:** Dynamically recalculates macros based on grams/portions selected.

#### What Has NOT Been Implemented / Pending
- **Live USDA FoodData Central Querying:** Although `dio_client.dart` contains `usdaGet` and API endpoints are mapped in `api_constants.dart`, the UI search currently queries the Firestore database and custom foods. Direct live external search against USDA FDC is not yet hooked up.
- **Barcode Scanner Integration:** `mobile_scanner` is imported in `pubspec.yaml`, but the barcode scanning screen and OpenFoodFacts/USDA UPC lookup flow are not yet wired into the meal logger.
- **AI Camera Meal Scanner:** Taking a picture of a plate to automatically estimate calories and macros via computer vision is not yet implemented.

---

### Feature 6: Intermittent Fasting System (`lib/features/fasting`)

#### What Has Been Implemented
- **Preset & Custom Fasting Protocols:** Built-in standard fasting schedules and fully custom options:
  - 16:8 (LeanGains)
  - 14:10 (Gentle Fast)
  - 12:12 (Circadian Rhythm)
  - 18:6 (The Warrior Lite)
  - 20:4 (The Warrior Diet)
  - OMAD (One Meal A Day / 23:1)
  - **Custom Fasting Time Adjustment:** Tapping the "Custom" plan chip immediately opens an interactive bottom sheet modal allowing users to customize duration from 1h to 72h (30-min increments) using sliders, +/- stepper buttons, and popular quick presets (`12h`, `14h`, `16h`, `18h`, `20h`, `24h`, `36h`, `48h`). Also includes inline controls on the main screen with live target completion date/time calculations and physiological phase previews (Fat Burning, Autophagy, Deep Ketosis).
- **Active Fast Engine:** Real-time countdown timer and progress circle that tracks elapsed vs. target hours, surviving app restarts and background transitions.
- **Offline-First Resilience (Hive):** Fasts are instantly cached in Hive (`fasting_box`) and mirrored to Firestore, ensuring starting, ending, and viewing fasting sessions work completely offline without internet or server dependencies.
- **Metabolic Stage Visualizer:** Displays physiological milestones reached during the fast:
  - 0–4 hours: Blood Sugar Normalization
  - 4–8 hours: Glycogen Depletion
  - 8–12 hours: Fat Burning Mode
  - 12–18 hours: Ketosis Initiation
  - 18+ hours: Autophagy Stimulation
- **Fasting History & Streaks:** Logs completed fasting sessions with duration, completion percentage, streak metrics, and achievements engine synchronization.

#### What Has NOT Been Implemented / Pending
- **Live Notification Countdown:** Persistent ongoing Android notification bar showing live minutes remaining without opening the app.

---

### Feature 7: AI Coach & Health Advisor (`lib/features/ai_coach`) - *Future Scope (Phase 2)*

#### Current Status: Future Scope Milestone
- **Campus Mini-Project Scope Strategy:** To ensure the core mobile application operates 100% reliably offline on physical devices without third-party LLM API key dependencies or paid token quotas, the AI Coach is formally designated as **Future Scope (Phase 2)**.
- **Interactive "Under Development" Preview (`ai_coach_screen.dart`):**
  - Tapping the AI Coach button from the Dashboard routes to an interactive, polished **"Feature Under Development • Future Scope"** screen.
  - Showcases the upcoming capability roadmap: Live Metric Intelligence, Adaptive Meal Suggestions, Smart Fasting Windows, and Visual Body Composition Analysis.
  - Provides a "Notify When Available" feedback trigger and clean navigation back to active features.

#### Backend Architecture Prepared for Future Deployment
- **LLM Streaming Integration (`openai_service.dart`):** Ready for Groq high-speed inference (`llama-3.3-70b-versatile`) over Server-Sent Events (SSE).
- **RAG-Style Context Engine (`ai_context_model.dart`):** Aggregates user metrics (age, gender, BMI, calorie targets, fasting streaks) into system context.
- **Safety Policy & Rate Limiter (`health_advice_policy.dart`, `ai_rate_limiter_service.dart`):** Medical disclaimers and token abuse prevention guards.

---

### Feature 8: Analytics & Data Visualization (`lib/features/analytics`)

#### What Has Been Implemented
- **Client-Side Aggregation Service (`analytics_aggregation_service.dart`):**
  - Computes rolling metrics across 7, 30, and 90-day timeframes:
    - Net weight change and rate of loss per week.
    - Average daily caloric intake and macro distribution percentages (% Protein, % Carbs, % Fat).
    - Fasting compliance rate and average fast duration.
    - Streak calculations.
- **Visual Analytics Dashboard (`analytics_dashboard_screen.dart`):**
  - High-performance charts powered by `fl_chart`.
  - Calorie vs. Target bar chart.
  - Weight trendline with goal baseline.
  - Fasting duration compliance chart.

#### What Has NOT Been Implemented / Pending
- **Correlation Insights Engine:** Cross-analyzing metrics automatically (e.g., "On days you fast for 18 hours, your calorie intake is 15% lower").

---

### Feature 9: Gamification & Achievements Engine (`lib/features/gamification`)

#### What Has Been Implemented
- **XP & Level Progression System:** Users earn Experience Points (XP) for actions:
  - Logging a meal: +10 XP
  - Logging daily weight: +15 XP
  - Completing a fast: +25 XP
  - Hitting daily water target: +10 XP
  - Dynamic level calculation with progressive thresholds.
- **Predefined Achievement Catalog (`achievement_config.dart`):**
  - 20+ distinct badges across categories: Fasting (e.g., "First Fast", "Century Club"), Nutrition ("Clean Eater", "Hydration Hero"), Weight ("Goal Crusher", "First Step"), and Consistency ("7-Day Streak", "30-Day Master").
- **Achievement Evaluation Service (`achievement_engine_service.dart`):**
  - Automatically evaluates criteria after any log event.
  - Unlocks badges and awards bonus XP.
- **Celebration UI (`celebration_overlay.dart`):**
  - Full-screen animated celebration with confetti (`confetti` package) and badge presentation when an achievement is unlocked.

#### What Has NOT Been Implemented / Pending
- **Social Leaderboards:** Comparing XP and streaks with friends or global community members.

---

### Feature 10: Progress Photos (`lib/features/progress_photos`)

#### What Has Been Implemented
- **Camera & Gallery Capture:** Integrated with `image_picker` for front, side, and back physique photos.
- **Image Compression:** Uses `flutter_image_compress` to compress heavy camera captures before saving or uploading.
- **Dual Storage Strategy:**
  - Saves locally to app documents directory for offline instant viewing.
  - Uploads to Firebase Cloud Storage (`progress_photos/{uid}/...`) when network is available.
- **Photo Metadata:** Stores date taken, linked weight on that date, and posture tag (front/side/back).
- **Comparison Tool (`photo_comparison_screen.dart`):**
  - Side-by-side comparison screen allowing users to select two distinct dates and evaluate visual body composition changes.

#### What Has NOT Been Implemented / Pending
- **Interactive Slider Overlay:** An interactive swipe slider overlaying two photos directly on top of each other.
- **Privacy Lock:** Dedicated PIN or biometric lock specifically for the photo gallery.

---

### Feature 11: Reports & Data Export (`lib/features/reports`)

#### What Has Been Implemented
- **PDF Report Generator (`pdf_generator.dart`):**
  - Generates multi-page health reports using the `pdf` package.
  - Formats user vitals, weekly weight logs, macro compliance summaries, and fasting logs into printable layouts.
- **CSV Data Generator (`csv_generator.dart`):**
  - Generates raw CSV spreadsheets of all logged weights, meals, and fasting sessions.
- **Export & Share Handler (`report_export_service.dart`):**
  - Integrates with `share_plus` and `path_provider` to save files locally or share them via email, WhatsApp, or cloud drives.

#### What Has NOT Been Implemented / Pending
- **Excel (.xlsx) Multi-Tab Workbook:** `excel` dependency is present, but complete multi-tab formatted Excel export is secondary to the functional CSV exporter.

---

### Feature 12: User Profile & App Settings (`lib/features/profile`)

#### What Has Been Implemented
- **User Profile Screen:** Displays avatar, current metrics, lifetime stats (total kg lost, total hours fasted, total meals logged), and level.
- **Settings Screen (`settings_screen.dart`):**
  - Unit toggle: Metric (kg, cm, ml) vs. Imperial (lbs, in, oz).
  - Theme selection: Dark mode, Light mode, System default.
  - Default fasting protocol preference.
  - Daily calorie and macronutrient manual override.
  - Daily notification reminder toggles.
- **Data Export Screen (`export_data_screen.dart`):** UI interface to trigger PDF/CSV report exports.

#### What Has NOT Been Implemented / Pending
- **Account Deletion (GDPR Compliance):** Self-service "Delete Account and Wipe All Data" flow that purges both Firebase Auth and Firestore records.

---

### Feature 13: Notifications & Local Scheduling (`lib/features/notifications` & `lib/core/services`)

#### What Has Been Implemented
- **Local Push Notifications:** Configured via `flutter_local_notifications` for Android and iOS.
- **Scheduled Alerts:**
  - Fasting start and fasting completion alerts.
  - Daily meal logging reminders (Breakfast, Lunch, Dinner).
  - Hydration reminder pings throughout the day.
- **In-App Notification Center (`notifications_screen.dart`):**
  - Displays historical alerts, level-up announcements, and achievement alerts with read/unread statuses.

#### What Has NOT Been Implemented / Pending
- **Remote Push Notifications (FCM Backend):** While `firebase_messaging` is imported, backend Cloud Functions to dispatch push notifications remotely when the app is killed are not deployed.

---

### Feature 14: Application Shell & Routing (`lib/app/router.dart` & `lib/features/shell`)

#### What Has Been Implemented
- **GoRouter Declarative Navigation:** Structured routes for all features.
- **ShellRoute Scaffold:** Persistent bottom navigation bar maintaining state across five primary tabs:
  1. `Dashboard`
  2. `Nutrition`
  3. `Fasting`
  4. `AI Coach`
  5. `Analytics`
- **Top App Bar Actions:** Quick access to Profile, Notifications Center, and Achievements.

#### What Has NOT Been Implemented / Pending
- **Deep Linking:** External URL deep links (e.g., `xenova://fasting/start`) are not configured in AndroidManifest/Info.plist.

---

## 3. APIs & External Services: Used vs. Needed

| Service / API | Integration Status | Configuration Location | What is Working | What is Missing / Needed |
|:---|:---:|:---|:---|:---|
| **Groq AI (Llama 3.3 70B)** | **Configured & Implemented** | `lib/features/ai_coach/data/services/openai_service.dart` | RAG context injection, streaming response via SSE, daily rate limiter. | Needs valid `GROQ_API_KEY` in `.env` to execute live calls without mock fallback. |
| **Google Gemini API** | **Documented Only** | `API_AND_AI.md` & `.env.example` | Conceptual documentation and prompt definitions. | Code currently uses `OpenAIService` (Groq). Needs a dedicated `GeminiService` if Gemini is preferred. |
| **USDA FoodData Central** | **Partially Implemented** | `lib/core/network/dio_client.dart` & `api_constants.dart` | Helper HTTP client methods (`usdaGet`) and endpoints mapped. | Needs search screen wiring to query USDA endpoints and parse JSON models into `FoodItemModel`. Needs `USDA_API_KEY`. |
| **Firebase Auth** | **Fully Implemented** | `lib/core/firebase/firebase_auth_service.dart` | Email/password, Google SSO, token refresh, auth state listeners. | Production SHA-256 fingerprints needed in Firebase Console for production Google Sign-in. |
| **Cloud Firestore** | **Fully Implemented** | `lib/core/firebase/firestore_service.dart` | Full CRUD operations, real-time query streams, batch writes for food seeding. | Production Firestore Security Rules (`firestore.rules`) must be deployed. |
| **Firebase Cloud Storage** | **Fully Implemented** | `lib/core/storage/data/firebase_storage_repository_impl.dart` | Photo upload, download URL generation, local file caching fallback. | Storage rules (`storage.rules`) must be deployed to enforce user-only read/write. |
| **Firebase Messaging (FCM)** | **Stubbed** | `lib/core/firebase/messaging_service.dart` | Token retrieval and permission requests. | Server-side trigger functions for remote notifications when app is closed. |
| **Apple Health / Google Health Connect** | **Not Implemented** | Planned | None. | Native health SDK integration for automatic step and active calorie syncing. |

---

## 4. Data Repositories, Datasets & Storage Architecture

### 4.1. Remote Firestore Collections Architecture

The database utilizes a subcollection-per-user model under `users/{uid}` for privacy and security:

```text
firestore_root/
├── food_database/                     [Global pre-seeded food catalog]
│   └── {foodId}                       (e.g., 'global_chicken_breast', 'global_egg')
│
└── users/
    └── {uid}/                         [Core user profile: email, name, metrics, preferences]
        ├── weight_entries/
        │   └── {entryId}              [Weight, body fat, date, mood, note]
        ├── meal_logs/
        │   └── {logId}                [Meal type, timestamp, items array]
        ├── daily_summaries/
        │   └── {YYYY-MM-DD}           [Calories, protein, carbs, fat, water consumed]
        ├── fasting_sessions/
        │   └── {sessionId}            [Start time, end time, target hours, completed flag]
        ├── custom_foods/
        │   └── {customFoodId}         [User-created private foods and recipes]
        ├── progress_photos/
        │   └── {photoId}              [Storage URL, date, weight tag, view angle]
        ├── notifications/
        │   └── {notificationId}       [Title, body, type, isRead, timestamp]
        ├── gamification/
        │   └── stats                  [Total XP, current level, unlocked badges list]
        └── analytics_reports/
            └── {reportId}             [Aggregated weekly/monthly performance snapshots]
```

### 4.2. Embedded Datasets

1. **Pre-Seeded Food Database (`food_database_repository.dart`):**
   - Automatically bootstrapped into the Firestore `food_database` collection on first startup.
   - Contains **26 essential foods** with verified nutritional parameters per 100g/standard serving:
     - *Proteins:* Whole Large Eggs, Raw Chicken Breast, Canned Tuna, Fresh Salmon, Extra Lean Beef, Whey Protein Isolate, Firm Tofu.
     - *Carbohydrates & Grains:* Rolled Oats, Brown Rice, Sweet Potato, Quinoa, Whole Wheat Bread, White Basmati Rice.
     - *Fruits & Berries:* Banana, Medium Apple, Blueberries, Fresh Strawberries, Orange.
     - *Vegetables & Greens:* Raw Spinach, Steamed Broccoli, Hass Avocado, Cucumber, Carrots, Mixed Salad Greens.
     - *Dairy & Healthy Fats:* Greek Yogurt (0% Fat), Raw Almonds, Peanut Butter, Olive Oil.
2. **Achievement Definitions (`achievement_config.dart`):**
   - Hardcoded configuration defining unlock conditions, titles, descriptions, icons, and XP rewards for **20+ badges**.
3. **AI Health Advice Policy (`health_advice_policy.dart`):**
   - Static prompt guardrails and system rules injected into all AI Coach conversations.

### 4.3. Local Storage & Caching Layers

- **SharedPreferences:**
  - Active fast start timestamp, active fast duration goal, and active fast state.
  - User preferences: selected theme mode, unit system (Metric vs Imperial), notification preferences.
  - AI daily rate limiter counter and timestamp reset marker.
- **Hive:**
  - Local caching of AI conversation messages to minimize Firestore reads and preserve offline chat state.
  - Nutrition search query cache to avoid repetitive network requests.
- **Local File System (`path_provider`):**
  - Offline progress photo storage before cloud upload.
  - Temporary storage directory for generated PDF and CSV export files before sharing.

---

## 5. Technical Highlights & Architectural Decisions

1. **Strict Type Safety & Null Safety:**
   - 100% sound null safety across all models and repositories.
   - Explicit generics throughout HTTP and Riverpod providers (e.g., `Dio.post<ResponseBody>`, `MaterialPageRoute<void>`).
2. **Offline-First Resilience:**
   - Fasting timer continues calculating accurately regardless of internet connection.
   - Progress photos are immediately written to local disk and displayed in the UI prior to background Cloud Storage synchronization.
   - Cached foods and chat messages remain readable offline.
3. **Clean Decoupling:**
   - Domain layer models (`FoodItemModel`, `WeightEntryModel`, `FastingSessionModel`) have zero dependency on UI or Flutter packages.
   - Calculators are pure Dart classes with zero side-effects, making them instantly unit-testable.

---

## 6. Implementation Gaps & Next Steps (Action Plan)

### High Priority (Immediate)
1. **API Keys Configuration:**
   - Add a valid `GROQ_API_KEY` to `.env` to activate the live AI Coach.
   - (Optional) Wire the `usdaGet` client in `food_database_repository.dart` to enable online USDA searches when local/Firestore matches are fewer than 5 results.
2. **Firebase Rules Deployment:**
   - Deploy `firestore.rules` and `storage.rules` via Firebase CLI to lock down data access to authenticated document owners (`request.auth.uid == userId`).

### Medium Priority (Enhancements)
3. **Barcode Scanning:**
   - Connect the existing `mobile_scanner` dependency to a scanning view that queries OpenFoodFacts or USDA by UPC barcode.
4. **Apple Sign-In Production Flow:**
   - Complete Apple Sign-In credential routing for iOS compliance.

### Low Priority (Future Scope)
5. **Wearables & HealthKit/Google Fit:**
   - Integrate `health` or `flutter_health_connect` plugin for automated daily step and resting heart rate syncing.
6. **AI Vision Meal Estimation:**
   - Send camera photo captures to Gemini 1.5 Flash / Vision models to automatically predict food items and estimate portion weights.

---

*Report prepared and validated against Xenova Health codebase.*
