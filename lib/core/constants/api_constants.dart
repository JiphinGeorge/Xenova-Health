/// API-related constants for Xenova Health.
abstract final class ApiConstants {
  // ─── USDA FoodData Central ───
  static const String usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String usdaSearchEndpoint = '/foods/search';
  static const String usdaFoodEndpoint = '/food';
  static const String usdaFoodsEndpoint = '/foods';

  // ─── Nutritionix (Alternative) ───
  static const String nutritionixBaseUrl =
      'https://trackapi.nutritionix.com/v2';
  static const String nutritionixSearchEndpoint = '/search/instant';
  static const String nutritionixNutrientsEndpoint = '/natural/nutrients';

  // ─── AI Providers ───
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1';

  // ─── Timeouts (milliseconds) ───
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 15000;
  static const int aiReceiveTimeout = 60000;

  // ─── HTTP Headers ───
  static const String contentTypeJson = 'application/json';
  static const String acceptJson = 'application/json';

  // ─── Rate Limiting ───
  static const int usdaMaxRequestsPerHour = 1000;
  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;
}
