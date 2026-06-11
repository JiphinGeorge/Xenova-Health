<div align="center">

# Xenova Health

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=24&pause=1000&color=F76B1C&center=true&vCenter=true&width=435&lines=AI-Powered+Health+Tracking;Weight+%26+Nutrition+Management;Intermittent+Fasting+Coach;Your+Personal+Wellness+Platform" alt="Typing SVG" />

**A Production-Ready Health and Fitness Platform powered by Flutter, Firebase, Riverpod, and Gemini AI.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Ready-FFCA28?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-State_Management-000000?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev)
[![Gemini](https://img.shields.io/badge/Gemini-AI_Coach-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

<br/>

![GitHub Visitor's Badge](https://komarev.com/ghpvc/?username=JiphinGeorge&label=Profile%20Views&color=0e75b6&style=flat)
<br/>
<img src="https://github-readme-stats.vercel.app/api?username=JiphinGeorge&show_icons=true&theme=radical" alt="GitHub Stats" width="400"/>
<img src="https://github-readme-streak-stats.herokuapp.com/?user=JiphinGeorge&theme=radical" alt="GitHub Streak" width="400"/>

</div>

---

## 🌟 Introduction

Xenova Health is an advanced, AI-driven wellness ecosystem designed to empower users on their health journeys. It bridges the gap between raw health data and actionable insights by seamlessly combining:
- **AI-Powered Health Tracking Platform**
- **Weight Management System**
- **Nutrition Tracking System**
- **Intermittent Fasting Platform**
- **Progress Photo Analysis**
- **Analytics Dashboard**
- **AI Coach powered by Gemini**

---

## 🎨 App Branding & Vision

### The Xenova Identity
The Xenova Health visual identity is designed to represent personal transformation, health improvement, and technology-driven wellness. The primary logo features a modern stylized "X" that symbolizes growth, progress, and the journey toward healthier living. The blue and purple gradient reflects trust, intelligence, innovation, and the integration of artificial intelligence within the platform.

For mobile deployment, Xenova Health utilizes a simplified **orange and gold icon** derived from the brand identity. The icon represents vitality, energy, achievement, and human-centered wellness. Its minimal design ensures strong recognition across Android and iOS devices while maintaining consistency with the application's mission.

**Mission Statement:** To democratize personalized health coaching by fusing state-of-the-art artificial intelligence with comprehensive lifestyle tracking, empowering individuals to take control of their well-being.

---

## ✨ Key Features

### 🔐 Authentication
* **Email Login**: Secure email/password authentication via Firebase Auth.
* **Google Login**: Seamless single sign-on experience.

### ⚖️ Health Tracking
* **Weight Tracking**: Log and visualize daily weight.
* **BMI & BMR**: Automatic Body Mass Index and Basal Metabolic Rate calculations.
* **TDEE**: Total Daily Energy Expenditure tracking based on activity levels.

### 🥗 Nutrition
* **Food Database**: Search and log meals using a comprehensive database (USDA API).
* **Meal Logging**: Track Breakfast, Lunch, Dinner, and Snacks.
* **Water Tracking**: Monitor daily hydration goals.

### ⏱️ Fasting
* **16:8 & OMAD**: Built-in popular fasting schedules.
* **Custom Plans**: Create and track personalized intermittent fasting windows.

### 🤖 AI Coach
* **Gemini AI**: Conversational health coaching powered by Google's Gemini.
* **Weekly Summary**: AI-generated health reports analyzing your 7-day trends.
* **Personalized Recommendations**: Context-aware dietary and fitness advice.

### 📸 Progress Photos
* **Before/After Comparison**: Side-by-side visual progress tracking.
* **Cloud Storage**: Secure, private backup of photos via Firebase Storage.

### 📈 Analytics & Reports
* **Charts & Trends**: Interactive charts for weight, nutrition, and fasting history.
* **PDF & CSV Export**: Generate shareable reports for personal records or healthcare providers.

### 🎮 Gamification & Notifications
* **XP & Levels**: Earn experience points for logging meals, fasting, and consistency.
* **Achievements**: Unlock badges for major milestones (e.g., "7-Day Streak").
* **Notification Center**: Centralized hub for reminders, level-ups, and AI alerts.

---

## 📸 Screenshots

*(Replace placeholders with actual app screenshots)*

| Login | Dashboard | Weight Tracker | Nutrition |
|:---:|:---:|:---:|:---:|
| <img src="assets/images/placeholder.png" width="200"/> | <img src="assets/images/placeholder.png" width="200"/> | <img src="assets/images/placeholder.png" width="200"/> | <img src="assets/images/placeholder.png" width="200"/> |

| Fasting | Analytics | AI Coach | Achievements |
|:---:|:---:|:---:|:---:|
| <img src="assets/images/placeholder.png" width="200"/> | <img src="assets/images/placeholder.png" width="200"/> | <img src="assets/images/placeholder.png" width="200"/> | <img src="assets/images/placeholder.png" width="200"/> |

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Frontend** | Flutter, Riverpod (State Management), GoRouter (Navigation), Freezed (Data Classes) |
| **Backend & Auth** | Firebase Authentication, Firebase Cloud Storage, Firebase App Check |
| **Database** | Cloud Firestore (NoSQL), Hive (Local Caching) |
| **AI Integration** | Google Gemini API (`google_generative_ai`) |
| **Analytics & Crash**| Firebase Analytics, Firebase Crashlytics |
| **CI/CD** | GitHub Actions, Environment Variables (.env), Fastlane (Planned) |

---

## 🏗️ Project Architecture

Xenova Health strictly follows **Feature-First Clean Architecture**, ensuring scalability, testability, and separation of concerns.

- **Presentation Layer**: UI Components, Screens, and Riverpod Controllers. Handles user interaction and state rendering.
- **Domain Layer**: Core business logic, Entities (Models), and Repository Interfaces. This layer is entirely independent of external frameworks.
- **Data Layer**: API integrations, Firebase implementations, and local caching (Hive). Responsible for fetching and formatting data.
- **Dependency Injection**: Riverpod is used extensively to provide Repositories, Services, and State Controllers across the app.

*(See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed diagrams and flows).*

---

## 📂 Folder Structure

```text
lib/
├── app/                  # App routing, themes, and global configuration
├── core/                 # Shared utilities, constants, and global services (Firebase, Hive)
└── features/             # Feature-first modules
    ├── ai_coach/         # Gemini chat, context building, and insights
    ├── analytics/        # Charts, trends, and data visualization
    ├── auth/             # Login, registration, and user sessions
    ├── dashboard/        # Main landing screen and daily overview
    ├── fasting/          # Timer, schedules, and fasting history
    ├── gamification/     # XP, levels, and achievements engine
    ├── notifications/    # In-app alerts and Firebase messaging
    ├── nutrition/        # USDA search, meal logging, and macro tracking
    ├── profile/          # Settings, preferences, and user details
    ├── progress_photos/  # Image capture, compression, and cloud storage
    ├── reports/          # PDF & CSV generation and export
    └── weight/           # Daily weight logging and goal tracking
```

---

## 🗄️ Database & Storage

Xenova uses a highly optimized NoSQL structure in **Firestore**:
- `users/{uid}`: Core profile and settings.
- `users/{uid}/weight_entries`: Time-series weight tracking.
- `users/{uid}/meal_logs`: Nutritional tracking.
- `users/{uid}/fasting_sessions`: Intermittent fasting records.
- `users/{uid}/achievements`: Unlocked badges and XP.

**Firebase Storage**:
- `profile_photos/{uid}/avatar.jpg`
- `progress_photos/{uid}/{timestamp}_original.jpg`

*(See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for complete entity relationships).*

---

## 🛡️ Security Features

- **Firebase Security Rules**: Strict read/write validation preventing unauthorized access.
- **Firebase App Check**: Play Integrity (Android) and DeviceCheck (iOS) to protect backend resources from abuse.
- **Environment Variables**: API keys and secrets are safely injected via `.env` files and GitHub Secrets.
- **Crashlytics**: Real-time fatal and non-fatal error reporting.

---

## 🚀 Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/JiphinGeorge/Xenova-Health.git
   cd "Xenova Health"
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup:**
   Create `.env.dev`, `.env.staging`, and `.env.prod` files inside `assets/env/`. Add your API keys:
   ```env
   USDA_API_KEY=your_key_here
   GEMINI_API_KEY=your_key_here
   USE_FIREBASE_STORAGE=true
   ```

4. **Firebase Configuration:**
   Run FlutterFire to generate platform configurations:
   ```bash
   flutterfire configure --project=your-firebase-project-id
   ```

5. **Run the App:**
   ```bash
   flutter run --flavor dev
   ```

*(See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed release and CI/CD instructions).*

---

## 🔮 Future Scope

- **Wearable Integration**: Syncing with Apple Health & Google Fit.
- **AI Nutrition Scanner**: Take a picture of food for automatic calorie estimation using Gemini Vision.
- **Advanced Coaching**: Real-time workout tracking and dynamic macro adjustments.

---

## 👨‍💻 Contributors

**Jiphin George**  
[GitHub Profile](https://github.com/JiphinGeorge)
