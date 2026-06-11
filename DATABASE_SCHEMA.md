# Database Schema & Structure

Xenova Health relies on a highly scalable, denormalized NoSQL database structure provided by **Google Cloud Firestore**.

---

## Collections Overview

The database is built around a root `users` collection, with sub-collections storing time-series and domain-specific data to ensure incredibly fast, paginated queries.

### 1. `users` (Root Collection)
Stores global user profile and settings data.

**Document ID**: `{uid}` (Matches Firebase Auth UID)

```json
{
  "uid": "abc123xyz",
  "email": "user@example.com",
  "displayName": "Jiphin George",
  "targetWeight": 70.5,
  "dailyCalorieGoal": 2500,
  "createdAt": "2026-06-11T12:00:00Z"
}
```

---

### 2. `users/{uid}/weight_entries`
Stores historical weight data for charting and BMI tracking.

```json
{
  "id": "entry_9876",
  "weight": 75.2,
  "date": "2026-06-11T08:00:00Z",
  "bodyFatPercentage": 18.5,
  "notes": "Morning weigh-in"
}
```

---

### 3. `users/{uid}/meal_logs`
Detailed nutritional logs, categorized by meal type.

```json
{
  "id": "meal_4455",
  "mealType": "Lunch",
  "date": "2026-06-11T13:30:00Z",
  "foodName": "Grilled Chicken Salad",
  "calories": 450,
  "protein": 35.0,
  "carbs": 12.0,
  "fat": 15.0
}
```

---

### 4. `users/{uid}/fasting_sessions`
Tracks the lifecycle of an intermittent fasting period.

```json
{
  "id": "fast_1122",
  "startTime": "2026-06-10T20:00:00Z",
  "endTime": "2026-06-11T12:00:00Z",
  "targetDurationHours": 16,
  "status": "completed"
}
```

---

### 5. `users/{uid}/progress_photos`
Tracks visual transformations, pointing to Cloud Storage buckets.

```json
{
  "id": "photo_9988",
  "date": "2026-06-11T09:00:00Z",
  "imageUrl": "https://firebasestorage...",
  "thumbnailUrl": "https://firebasestorage...",
  "weightAtTime": 75.2
}
```

---

### 6. `users/{uid}/achievements`
Gamification records indicating earned badges and XP.

```json
{
  "id": "ach_7_day_streak",
  "title": "7-Day Warrior",
  "unlockedAt": "2026-06-11T10:00:00Z",
  "xpReward": 500
}
```

---

## Firebase Storage Structure

Heavy assets (images) are stored in Firebase Storage, perfectly mapped to the UID structure to enforce strict security rules.

- **Profile Avatars**: `profile_photos/{uid}/avatar.jpg`
- **Progress Images (Original)**: `progress_photos/{uid}/{timestamp}_original.jpg`
- **Progress Images (Thumbnail)**: `progress_photos/{uid}/{timestamp}_thumbnail.jpg`

---

## Security Considerations & Rules

Access is strictly constrained so that users can only read/write their own data.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own root document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Cascade rules down to all subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Indexing
Because we frequently query data by date range (e.g., fetching the last 7 days of nutrition), we utilize composite indexes on:
- `users/{uid}/meal_logs` -> `(date: DESC)`
- `users/{uid}/weight_entries` -> `(date: DESC)`
