/// Prompt templates for the Xenova Health AI Coach.
class AiPromptTemplates {
  static String weightAnalysis() {
    return 'Analyze my recent weight trend and give me insights on my progress.';
  }

  static String nutritionAnalysis() {
    return 'Review my nutrition consistency and suggest areas for improvement.';
  }

  static String fastingAnalysis() {
    return 'How is my fasting consistency? Give me actionable tips.';
  }

  static String weeklySummary() {
    return 'Generate a Weekly Health Summary based on my latest Analytics Snapshot. Include my weight change, fasting completions, and nutrition goal metrics. End with a focus for next week.';
  }
}
