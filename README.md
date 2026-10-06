<div align="center">

# Xenova Health

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=24&pause=1000&color=F76B1C&center=true&vCenter=true&width=450&lines=All-in-One+Health+%26+Wellness+Platform;Weight+%26+Calorie+Management;Intermittent+Fasting+Coach;Medical-Grade+PDF+%26+CSV+Exports" alt="Typing SVG" />

**A Production-Ready, Offline-Resilient Health and Fitness Platform powered by Flutter, Firebase, Riverpod, and Hive.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Ready-FFCA28?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-State_Management-000000?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev)
[![Hive](https://img.shields.io/badge/Hive-Offline_First-FF6F00?style=for-the-badge&logo=hive&logoColor=white)](https://docs.hivedb.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

<br/>

</div>

---

## 🌟 Introduction

**Xenova Health** is an advanced, offline-first mobile health and wellness platform designed to bridge raw daily health tracking with actionable, scientific insights. Built with Flutter, it combines:
- **Comprehensive Calorie & Macro Tracking:** Intelligent food search, USDA integration, and time-of-day meal categorization.
- **Intermittent Fasting Suite:** Real-time metabolic tracking across 6 standard schedules plus interactive custom fasting timers (1h–72h).
- **Weight & Body Metrics:** Time-series logging with automatic BMI, BMR, TDEE, and calorie deficit calculations.
- **Dynamic Overall Health Score (0–100):** Real-time multi-pillar composite algorithm across Nutrition, Fasting, Weight consistency, and Hydration.
- **Medical-Grade Report Generation:** Comprehensive offline PDF health summaries and granular CSV exports for healthcare professionals.
- **Photographic Physique Tracking:** Side-by-side visual comparison with privacy-conscious cloud backup.
- **Gamified Consistency:** XP progression, streaks, and milestone achievements.

---

## 🎨 App Branding & Vision

### The Xenova Identity
The Xenova Health visual identity represents personal transformation, vitality, and human-centered technology:
- **Stylized "X" Emblem:** Symbolizes growth, multidimensional progress, and the convergence of lifestyle pillars into unified well-being.
- **Color Palette:** A balanced interplay between deep dark-mode slate surfaces (`#0F172A`), vibrant wellness teal (`#0D9488`), and energizing amber/orange accents (`#F59E0B`), meticulously tuned for both dark mode and high-contrast light mode readability.
- **Mission Statement:** To provide individuals with an uncompromising, private, and offline-reliable health management companion that turns daily discipline into lasting physical vitality.

---

## ✨ Key Features

### 🔐 Authentication & Onboarding
* **Firebase Authentication:** Secure email/password login and Google SSO.
* **Reactive Session Management:** Automatic route guarding and session restoration via Riverpod streams.
* **Personalized Onboarding Wizard:** Collects baseline metrics, activity multipliers, primary goals, and dietary protocols.
* **Expanded Dietary Preferences (`DietType`):** Full support for Omnivore, Pescatarian, Flexitarian, Vegetarian, Vegan, Eggetarian, High Protein, and No Preference with clear food guide inclusions.

### 📊 Dynamic Dashboard & Health Score
* **Daily Executive Overview:** Instant visibility into calories consumed vs. budget, water intake, active fasting state, and weight trajectory.
* **Overall Health Score Engine (0–100):** Computes a live composite health score across 4 weighted pillars:
  - 🥗 **Nutrition (35%):** Caloric goal adherence and macronutrient distribution.
  - ⏱️ **Fasting (25%):** Fasting window completion and metabolic milestones.
  - ⚖️ **Weight & Consistency (25%):** Logging regularity and progress toward target weight.
  - 💧 **Hydration (15%):** Daily water intake goal completion.
* **Interactive Pillar Breakdown Modal:** Tap the health score card to view granular scores, performance ratings, and personalized improvement tips.

### 🥗 Nutrition & Meal Logging
* **Context-Aware "+ Add Food" Logger:** Automatically selects the appropriate meal category (Breakfast, Lunch, Dinner, Snack) based on current local time, with full manual override.
* **Portion & Macro Breakdown:** Real-time protein, carb, fat, and calorie calculations per serving.
* **Local-First Serialization:** High-performance offline caching via Hive with seamless Firestore cloud sync.
* **Quick Water Tracker:** One-tap +250ml / +500ml hydration logging with reactive daily progress ring.

### ⏱️ Intermittent Fasting Suite
* **Preset Fasting Protocols:** Built-in 16:8 (LeanGains), 18:6, 20:4 (Warrior), 14:10, 12:12, and 24h OMAD schedules.
* **Interactive Custom Fast Selector:** Continuous slider (1h–72h), ±30m step adjustments, quick preset chips, and target end-time preview.
* **Live Metabolic Stage Timeline:** Real-time visual progress through Blood Sugar Stabilization (0–4h), Glycogen Depletion (4–12h), Ketosis (12–18h), Autophagy (18–24h), and Peak Growth Hormone (24h+).

### ⚖️ Weight Management & Health Calculators
* **Time-Series Weight Tracking:** Log morning weigh-ins, body fat percentage, mood, and personal notes.
* **Embedded Health Calculators:**
  - **BMI Calculator:** Body Mass Index classification based on WHO standards.
  - **BMR Calculator:** Mifflin-St Jeor basal metabolic rate.
  - **TDEE Calculator:** Total Daily Energy Expenditure factoring activity levels.
  - **Calorie Deficit Calculator:** Targeted calorie budgets for safe, sustainable weight loss or gain.

### 📄 Medical-Grade PDF & CSV Health Reports
* **Comprehensive PDF Report:** Generates multi-page summary reports formatted for consultations with doctors, dietitians, or personal coaches.
* **Granular CSV Exporters:** Export individual datasets for Weight, Nutrition, and Fasting history.
* **Native System Share Sheet:** Directly save, print, or share reports via `share_plus`.

### 📸 Progress Photos
* **Private Physique Journal:** Capture or import front, side, and back physique photos.
* **Side-by-Side Comparison:** Interactive before-and-after slider to visually inspect body composition changes over time.
* **Encrypted Storage:** Private cloud backup via Firebase Cloud Storage with offline thumbnail caching.

### 🎮 Gamification & Achievements
* **XP Progression System:** Earn experience points for every logged meal, completed fast, and daily check-in.
* **Milestone Badges:** Unlock achievements for logging streaks, fasting mastery, and hydration milestones.
* **Toast & SnackBar Feedback:** Instant confirmations across profile photo updates, fasting plan changes, and preference edits.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Framework** | Flutter 3.x (Dart 3.x), Material 3 Design System |
| **State Management** | Riverpod (`flutter_riverpod`, `AsyncNotifier`, `NotifierProvider`) |
| **Navigation & Routing** | GoRouter with reactive authentication refresh streams |
| **Local Offline Storage** | Hive (local boxes: `user_box`, `weight_box`, `meal_box`, `fasting_box`, `daily_summary_box`, `cache_box`) & SharedPreferences |
| **Cloud Backend** | Firebase Authentication, Cloud Firestore (NoSQL), Firebase Cloud Storage |
| **Quality & Observability** | Firebase Crashlytics, Firebase Analytics |
| **Document Generation** | `pdf`, `printing`, `share_plus`, `csv` |
| **Data Immutability** | Freezed & JsonSerializable code generation |

---

## 🏗️ Project Architecture

Xenova Health strictly follows **Feature-First Clean Architecture**:

```text
lib/
├── app/                  # Application configuration, routing (GoRouter), themes & dimensions
├── core/                 # Shared domain logic, calculators, constants, Hive managers, widgets
└── features/             # Independent, feature-encapsulated modules
    ├── ai_coach/         # Phase 2 roadmap view & service architecture
    ├── analytics/        # Time-series charts, trends, and data visualization
    ├── auth/             # Authentication controllers, Firebase Auth service, login & register
    ├── dashboard/        # Main hub, executive overview, live health score engine
    ├── fasting/          # Intermittent fasting timers, custom duration modal, metabolic timeline
    ├── gamification/     # XP engine, levels, streaks, and milestone badges
    ├── notifications/    # Local notification engine & reminder dispatchers
    ├── nutrition/        # Context-aware meal logging, USDA search, macro distribution, Hive repo
    ├── onboarding/       # Multi-step onboarding wizard, metric input, dietary setup
    ├── profile/          # User preferences, diet settings, unit converters, legal documents
    ├── progress_photos/  # Physique comparison gallery and Firebase storage sync
    ├── reports/          # PDF report generator and CSV export utilities
    └── weight/           # Daily weight logging, goal tracking, and progress charts
```

Each feature module is structured into three clean layers:
1. **Domain Layer:** Pure Dart entities, immutable models, and repository interfaces.
2. **Data Layer:** Local Hive storage, remote Firestore adapters, and DTO serializers.
3. **Presentation Layer:** Riverpod state controllers and Material 3 UI widgets.

---

## 🗄️ Database & Offline Storage Architecture

### Cloud Firestore Collections
- `users/{uid}`: Core profile, physical metrics, goals, and preference flags.
- `users/{uid}/weight_entries`: Time-series weight, body fat %, and notes.
- `users/{uid}/meal_logs`: Meal logs containing structured food items and macro summaries.
- `users/{uid}/fasting_sessions`: Intermittent fasting sessions with start, target, and end timestamps.
- `users/{uid}/daily_nutrition`: Pre-aggregated daily calorie and macronutrient summaries.
- `users/{uid}/achievements`: Earned badges, current XP, and level state.

### Local Hive Persistence
All write operations commit to local Hive boxes immediately, ensuring zero-latency user interactions and complete offline autonomy:
- `user_box`: Local cache of user profile state.
- `weight_box`: Local time-series weight log cache.
- `meal_box`: Local meal logs with nested item serialization.
- `fasting_box`: Active and historical fasting sessions.
- `daily_summary_box`: Computed daily nutrition totals.
- `cache_box`: General cache and offline synchronization queues.

---

## 🚀 Installation & Setup

### Prerequisites
- **Flutter SDK:** `^3.24.0` or higher
- **Dart SDK:** `^3.5.0` or higher
- **Android Studio / VS Code** with Flutter & Dart extensions
- **Java Development Kit (JDK):** JDK 17 or JDK 21 LTS

### 1. Clone the Repository
```bash
git clone https://github.com/JiphinGeorge/Xenova-Health.git
cd Xenova-Health
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Environment Configuration
Create environment files under `assets/env/` (e.g., `.env.dev`, `.env.prod`):
```env
USDA_API_KEY=your_usda_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
USE_FIREBASE_STORAGE=true
```

### 4. Firebase Setup
Ensure your Firebase project is configured using FlutterFire CLI:
```bash
flutterfire configure --project=your-firebase-project-id
```

### 5. Run the Application
```bash
# Run Development Flavor
flutter run -d <device_id> --flavor dev

# Run Production Flavor
flutter run -d <device_id> --flavor prod
```

---

## 🧪 Testing & Code Quality

```bash
# Run Dart analyzer
flutter analyze

# Run unit and widget tests
flutter test

# Regenerate Freezed and Hive serialization models
dart run build_runner build --delete-conflicting-outputs
```

---

## 🔮 Phase 2 Roadmap

- [ ] **AI Conversational Health Coach:** Deep personalized lifestyle recommendations via Gemini.
- [ ] **AI Vision Food Scanner:** Automatic macronutrient estimation from food photographs.
- [ ] **Wearable Sensor Integration:** Bi-directional sync with Google Health Connect & Apple HealthKit.
- [ ] **Biometric App Lock:** Fingerprint and Face ID biometric authentication for sensitive health data.

---

## 👨‍💻 Author & Maintainer

**Jiphin George**  
- GitHub: [@JiphinGeorge](https://github.com/JiphinGeorge)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
