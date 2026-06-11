# External APIs & Artificial Intelligence

Xenova Health leverages Google's cutting-edge Generative AI (Gemini) to act as a 24/7 personal health coach, alongside the USDA Nutrition API for accurate food logging.

---

## 1. Google Gemini AI Integration

The AI Coach is powered by the `google_generative_ai` Dart SDK. Unlike standard chatbots, Xenova's AI is deeply contextual. It understands exactly what the user has eaten, their fasting status, and their recent weight trends.

### AI Context Model (RAG Approach)
When a user sends a message to the AI Coach, the application intercepts the request and builds a **System Prompt** using a Retrieval-Augmented Generation (RAG) style approach.

**Analytics Snapshot Injected into Context:**
1. **Current Weight & Goal Weight**
2. **Today's Nutritional Macros** (Calories, Protein, Carbs, Fat) vs. Targets.
3. **Current Fasting Status** (e.g., "Currently 12 hours into a 16-hour fast").
4. **Recent Achievements** (e.g., "Just unlocked the 7-day streak badge").

### Prompt Templates
The base system instructions passed to Gemini:
> "You are the Xenova Health AI Coach—a highly knowledgeable, empathetic, and professional fitness and nutrition expert. 
> The user's current data: [INJECTED_JSON_CONTEXT]. 
> Provide actionable, concise advice. Do not provide medical diagnoses."

### Safety Policies
We enforce strict safety settings via the Gemini API to ensure the coach remains professional and safe:
- `HarmCategory.harassment`: Block Medium and Above
- `HarmCategory.hateSpeech`: Block Medium and Above
- `HarmCategory.dangerousContent`: Block High

### AI Memory Management
To prevent token explosion and manage API costs, the `AICoachRepository` caches the chat history locally using **Hive**. Only the last 10 messages (along with the current live context snapshot) are sent to the Gemini API during an active session.

---

## 2. USDA Food Data Central API

To provide an exhaustive, accurate food logging experience, we integrate with the **USDA FDC API**.

### Endpoints Used
- `GET /v1/foods/search`: Queries the database for food items (e.g., "Chicken Breast").
- `GET /v1/food/{fdcId}`: Retrieves the exact macronutrient breakdown (Proteins, Carbs, Fats, Fiber) for the selected item.

### Rate Limiting & Caching
Because the USDA API has strict rate limits, Xenova Health employs **aggressive local caching**:
1. When a user searches for a food, we check the local Hive `nutrition_cache` box.
2. If the query exists, we return it instantly (0ms latency, 0 API calls).
3. If it does not exist, we fetch from the USDA API, parse the JSON into our `FoodItemModel`, and save it to the cache for future queries.
