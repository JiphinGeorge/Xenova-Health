# Xenova Health - Comprehensive Project Status & Technical Report

**Document Version:** 2.0.0  
**Generated Date:** October 2026  
**Platform:** Flutter 3.x (Android & iOS)  
**State Management:** Riverpod (Feature-First Clean Architecture)  
**Backend & Cloud Services:** Firebase (Auth, Cloud Firestore, Cloud Storage, Analytics, Crashlytics)  
**Local-First Offline Storage:** Hive (Boxes: `user_box`, `weight_box`, `food_box`, `meal_box`, `fasting_box`, `daily_summary_box`, `cache_box`) & SharedPreferences  
**Live Target Device:** Android API 34+ (Physical Device Verified)  

---

## 1. Executive Summary

**Xenova Health** is an advanced, offline-resilient mobile health and wellness platform built with Flutter. The application unifies daily weight logging, calorie and macronutrient tracking, intermittent fasting management, photographic physique tracking, gamified engagement, and medical-grade report generation.

The codebase strictly adheres to **Feature-First Clean Architecture**, separating each capability into distinct domain, data, and presentation layers with dependency injection provided by Riverpod.

### Current Build & Compilation Health
- **Static Analyzer:** **0 compilation errors**, 0 blocking warnings.
- **Runtime Execution:** Tested and running live on physical Android devices (`assembleDevDebug`) targeting Android API 34+ with Java 21 LTS.
- **Offline Reliability:** All core daily functions (logging meals, tracking hydration, running fasts, recording weight, generating PDF/CSV exports) execute seamlessly offline via local Hive storage.

---

## 2. Recent Major Fixes & Enhancements

Over recent development cycles, several critical architectural enhancements and bug fixes were completed:

1. **Nutrition & Meal Logging Serialization Fix:**
   - *Problem:* Calling `addMealLog` failed with `HiveError: Cannot write, unknown type: _$MealItemModelImpl`.
   - *Fix:* Corrected `meal_log_model.g.dart` and `meal_template_model.g.dart` to recursively serialize nested `mealItems` using `.map((e) => e.toJson()).toList()`, and added `_serializeMealLog` in `MealLogRepository` to guarantee pure `Map<String, dynamic>` storage.
2. **Context-Aware "+ Add Food" Time-of-Day Routing:**
   - Tapping the "+ Add Food" button automatically defaults the target meal category based on the user's current local time (Morning → Breakfast, Midday → Lunch, Evening → Dinner, Late Night → Snack), with an interactive selector to switch categories at will.
3. **Comprehensive Light Mode Color & Contrast Overhaul:**
   - Redesigned all ChoiceChips and ActionChips across Fasting, Portion & Nutrition, and Food Search screens with dark slate text (`#1E293B`), explicit border outlines (`#CBD5E1`), and active teal states to eliminate invisible white-on-white text in light mode.
   - Enhanced progress bar tracks (`#E2E8F0`) and elevated subtle borders on summary cards.
4. **Overall Health Score Engine (Live Multi-Pillar Computation):**
   - Implemented `health_score_provider.dart` calculating a real-time composite score (0–100) across 4 weighted pillars: Nutrition (35%), Fasting (25%), Weight & Consistency (25%), and Hydration (15%).
   - Added an interactive 4-pillar breakdown bottom sheet modal with actionable tips and tier classifications.
5. **PDF & CSV Health Data Export System:**
   - Resolved image and font loading crashes in `pdf_generator.dart`.
   - Built a local-first medical-grade PDF report generator and granular CSV exporters for Weight, Nutrition, and Fasting history, integrated with native system share sheets via `share_plus`.
6. **Expanded Dietary Protocols (`DietType`):**
   - Added `Omnivore`, `Pescatarian`, and `Flexitarian` alongside Vegetarian, Vegan, Eggetarian, High Protein, and No Preference with clear nutritional inclusions.
7. **Custom Intermittent Fasting Controls:**
   - Implemented an interactive custom duration modal with continuous sliders (1h–72h), +/- 30m steppers, popular presets (`12h`–`48h`), target completion timestamps, and metabolic stage previews.
8. **Immediate Contextual Feedback (Toasts & SnackBars):**
   - Added clear toast messages across Profile Photo uploads/removals, Fasting Plan changes, Diet Type updates, and Account Detail modifications.
9. **AI Coach Refactoring (Future Scope Designation):**
   - Designated AI Coach as **Phase 2 Future Scope** for academic and offline reliability, routing to a dedicated interactive roadmap screen and removing misleading static dashboard insight cards.

---

## 3. Feature-by-Feature Implementation Status

### Feature 1: Authentication & User Management (`lib/features/auth`)
#### Implemented:
- Firebase Authentication with email/password and Google SSO (`FirebaseAuthService`).
- Reactive session stream (`authStateChangesProvider`) handling automatic authentication routing.
- User document initialization and synchronization in Firestore (`users/{uid}`).
- Full UI suite: `LoginScreen`, `RegisterScreen`, and `ForgotPasswordScreen`.
#### Pending / Future:
- Apple Sign-In credential exchange on production iOS builds.
- Local biometric authentication (Fingerprint / Face ID lock).

---

### Feature 2: Onboarding Flow (`lib/features/onboarding`)
#### Implemented:
- Multi-step onboarding carousel showcasing Xenova Health's core tracking capabilities.
- Profile metric collection: Sex, age, height, current weight, and goal weight.
- Physical activity level selection (Sedentary through Extra Active).
- Primary goal selection (Weight Loss, Muscle Gain, Maintenance, Energy).
- Comprehensive dietary preference selection (`DietType`): Omnivore, Pescatarian, Flexitarian, Vegetarian, Vegan, Eggetarian, High Protein, and No Preference with descriptive food guides.
- Persistent onboarding completion flag in `SharedPreferences`.

---

### Feature 3: Main Dashboard (`lib/features/dashboard`)
#### Implemented:
- **Daily Executive Overview:** Summarizes daily vitals in a single high-performance view.
- **Calorie & Macro Budget Ring:** Consumed vs. remaining budget visualization.
- **Active Fasting Widget:** Real-time countdown timer with current metabolic phase indicator.
- **Quick Water Logger:** Increment/decrement buttons (+250ml / +500ml) with reactive progress.
- **Weight Trajectory Card:** Displays current weight, goal delta, and weekly trends.
- **Dynamic Overall Health Score (0–100):** Real-time multi-pillar composite score with tap-to-inspect 4-pillar bottom sheet breakdown.
- **Cleaned Dashboard Flow:** Removed misleading hardcoded AI Coach insight banner, allowing the view to flow cleanly into Today's Progress and Recent Activity.

---

### Feature 4: Weight Tracking & Health Calculators (`lib/features/weight` & `lib/core/calculators`)
#### Implemented:
- Log weight entries with timestamp, weight value (kg/lbs), optional body fat percentage, notes, and mood.
- Reactive local caching in Hive and cloud synchronization in Firestore (`users/{uid}/weight_entries`).
- Pure scientific calculators:
  - `BMICalculator`: Body Mass Index and WHO classification.
  - `BMRCalculator`: Mifflin-St Jeor basal metabolic rate computation.
  - `TDEECalculator`: Total Daily Energy Expenditure factoring activity multipliers.
  - `CalorieDeficitCalculator`: Caloric target calculation based on weight change speed.
  - `WeightPredictionCalculator`: Linear trend weight trajectory projection (4–12 weeks).
- Interactive weight chart powered by `fl_chart` with multi-timeframe filters (7D, 30D, 90D, All).

---

### Feature 5: Nutrition & Meal Tracking (`lib/features/nutrition`)
#### Implemented:
- Multi-meal logging into Breakfast, Lunch, Dinner, and Snacks.
- **Smart Time-Based Logging:** "+ Add Food" button detects current local time and automatically pre-selects the appropriate meal category.
- **Local-First Reactive Architecture:** Meals persist immediately to Hive (`meal_box`) with `watch()` stream emission, updating the UI instantly without network latency.
- **Self-Healing Aggregations:** Daily summaries automatically aggregate directly from individual meal logs if daily summary documents are missing or unsynced.
- **Dual Logging Workflows:**
  - *Quick Log Now:* Immediate single-food logging with scaled portions from the Food Details screen.
  - *Meal Builder:* Multi-item basket with portion adjustments and review before batch logging.
- **Macronutrient Tracking:** Automated summation and tracking of Calories, Protein (g), Carbohydrates (g), and Fat (g).
- **Water Tracker:** Daily hydration logging with customizable goals (e.g., 2500ml).
- **Embedded Food Database:** 26 pre-verified staple foods (eggs, chicken breast, oats, salmon, tofu, etc.) seeded automatically into Firestore.
- **Custom Foods (`custom_food_screen.dart`):** User creation and storage of private foods and recipes.
- **Light Mode UI Polish:** High-contrast meal category chips and portion selector buttons (`100g`, `50g`, etc.).

---

### Feature 6: Intermittent Fasting System (`lib/features/fasting`)
#### Implemented:
- Standard preset protocols: 16:8 (LeanGains), 14:10 (Gentle), 12:12 (Circadian), 18:6 (Warrior Lite), 20:4 (Warrior), and OMAD (23:1).
- **Custom Fasting Plan Customizer:** Interactive bottom sheet modal with 1h–72h sliders, +/- 30m steppers, popular presets (`12h`, `16h`, `24h`, etc.), live completion timestamps, and metabolic stage previews.
- **Active Fast Engine:** Real-time countdown timer surviving app restarts and background transitions.
- **Metabolic Phase Visualizer:** Highlights physiological stages: Blood Sugar Normalization, Glycogen Depletion, Fat Burning, Ketosis, and Autophagy.
- **History & Streaks:** Logs completed fasting sessions with duration, completion flags, and streak tracking.
- **Light Mode Accessibility:** ChoiceChips with dark text, subtle borders, and active teal highlighting.

---

### Feature 7: AI Coach & Health Advisor (`lib/features/ai_coach`) - *Future Scope (Phase 2)*
#### Current Milestone:
- Formally designated as **Future Scope (Phase 2)** to ensure 100% offline autonomy and remove third-party API token dependencies for academic submission.
- Interactive **"Feature Under Development • Future Scope"** screen (`ai_coach_screen.dart`) outlining upcoming capabilities (Live Metric Intelligence, Adaptive Meal Suggestions, Smart Fasting Windows).
- Prepared architecture: `OpenAIService` (Groq/Llama 3.3 70B), `ai_context_model.dart`, and `health_advice_policy.dart` ready for future cloud deployment.

---

### Feature 8: Analytics & Data Visualization (`lib/features/analytics`)
#### Implemented:
- Client-side rolling analytics across 7, 30, and 90-day timeframes (`analytics_aggregation_service.dart`).
- Visual charts powered by `fl_chart`: Calorie vs. Target bar charts, Weight trendlines with goal baselines, and Fasting compliance duration charts.
- Average daily calorie intake, macro distribution percentages (% Protein, % Carbs, % Fat), and fasting streak analytics.

---

### Feature 9: Gamification & Achievements Engine (`lib/features/gamification`)
#### Implemented:
- XP & Level progression: Meal log (+10 XP), Weight log (+15 XP), Fast completion (+25 XP), Water goal (+10 XP).
- Predefined catalog of 20+ badges across Fasting, Nutrition, Weight, and Consistency.
- Reactive `achievement_engine_service.dart` evaluating unlock conditions post-action.
- Full-screen animated celebration overlay with confetti (`confetti` package).

---

### Feature 10: Progress Photos (`lib/features/progress_photos`)
#### Implemented:
- Front, side, and back physique photo capture via camera or gallery (`image_picker`).
- Client-side image compression (`flutter_image_compress`).
- Dual storage: Saved locally for instant offline review; synchronized to Firebase Cloud Storage when connected.
- Side-by-side photo comparison screen (`photo_comparison_screen.dart`) for visual body composition tracking.

---

### Feature 11: Reports & Data Export (`lib/features/reports`)
#### Implemented:
- **Medical-Grade PDF Report (`pdf_generator.dart`):** Multi-page printable report with user profile, live Overall Health Score, BMI, weight progress charts, macro compliance, and fasting summaries.
- **Granular CSV Spreadsheets (`csv_generator.dart`):**
  - Weight History CSV (date, weight, notes).
  - Nutrition Logs CSV (date, meal type, food items, grams, calories, protein, carbs, fat).
  - Fasting Sessions CSV (start/end timestamps, target duration, completion status).
- **Universal Mobile Share (`report_export_service.dart`):** Integrates with `path_provider` and `share_plus` to dispatch exports directly to WhatsApp, Gmail, Google Drive, or File Manager.
- Offline-first execution decoupled from external API keys.

---

### Feature 12: User Profile & App Settings (`lib/features/profile`)
#### Implemented:
- Profile screen displaying user avatar, current metrics, lifetime statistics, and current level.
- Quick-access modal sheets for changing Fasting Plan and Diet Type with instant toast confirmations.
- Profile Photo picker with immediate feedback on upload and removal.
- Account Details editor with granular toast notifications indicating specifically what changed.
- Settings screen: Metric/Imperial unit toggle, Theme mode toggle (Dark/Light/System), notification preferences, and export triggers.

---

### Feature 13: Notifications & Local Scheduling (`lib/features/notifications`)
#### Implemented:
- Local notifications via `flutter_local_notifications` for Android and iOS.
- Scheduled reminders for fasting start/end, meal logging windows, and daily hydration reminders.
- In-app notification center displaying historical alerts and achievement notifications.

---

### Feature 14: Application Shell & Routing (`lib/app/router.dart` & `lib/features/shell`)
#### Implemented:
- GoRouter declarative navigation with `ShellRoute` maintaining state across tabs:
  1. Dashboard
  2. Nutrition
  3. Fasting
  4. AI Coach (Future Scope)
  5. Profile
- Quick-action top bar routing to Notifications, Settings, and Data Export.

---

## 4. Technology Stack & External Services

| Service / Tool | Purpose | Status | Notes |
|:---|:---|:---:|:---|
| **Flutter 3.x / Dart** | Cross-platform framework | **Active** | Sound null safety, Material 3 design system. |
| **Riverpod** | State management & DI | **Active** | Feature-first modular providers. |
| **Hive** | Local NoSQL key-value database | **Active** | Core offline engine for meals, fasts, summaries, and cache. |
| **Firebase Auth** | User authentication | **Active** | Email/Password & Google Sign-In. |
| **Cloud Firestore** | Remote cloud database | **Active** | Real-time backup and sync across devices. |
| **Firebase Storage** | Cloud media storage | **Active** | Progress photos storage. |
| **Firebase Analytics & Crashlytics** | Telemetry & error reporting | **Active** | Real-time crash monitoring and event logging. |
| **fl_chart** | Data visualization | **Active** | Weight trends, macro distributions, calorie charts. |
| **pdf & printing** | PDF document generation | **Active** | Medical-grade health report export. |
| **csv & share_plus** | Data export & mobile share sheet | **Active** | CSV export to WhatsApp, Drive, Mail, Files. |
| **flutter_local_notifications** | Scheduled device reminders | **Active** | Meal, fasting, and hydration alerts. |
| **Groq / Llama 3.3 70B** | LLM inference backend | **Phase 2 Scope** | Architectural scaffolding ready for live key integration. |

---

## 5. Storage Architecture

```text
Local Storage (Hive & Prefs)                  Remote Cloud (Firestore)
┌───────────────────────────────┐              ┌───────────────────────────────┐
│ • user_box                    │   Bi-directional   │ users/{uid}                   │
│ • meal_box (Reactive watch)   │ <------------> │ ├── meal_logs/{id}            │
│ • daily_summary_box           │     Sync     │ ├── daily_summaries/{date}    │
│ • fasting_box                 │              │ ├── fasting_sessions/{id}     │
│ • weight_box                  │              │ ├── weight_entries/{id}       │
│ • cache_box (Health score)    │              │ └── custom_foods/{id}         │
└───────────────────────────────┘              └───────────────────────────────┘
```

---

## 6. Verification & Quality Assurance

- **Static Analysis:** Clean pass across all 14 features (`0 errors`, `0 breaking warnings`).
- **Hardware Validation:** Hot restart, UI rendering, local database persistence, and PDF/CSV export generation verified directly on physical Android hardware.
- **Offline Reliability:** Core user flows operate without active internet connection.

---

*Report updated and validated against Xenova Health codebase.*
