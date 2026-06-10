/// AI provider options for the AI Coach feature.
enum AiProvider {
  gemini(
    label: 'Google Gemini',
    description: 'Powered by Google AI',
    envKey: 'GEMINI_API_KEY',
  ),
  openai(
    label: 'OpenAI',
    description: 'Powered by GPT',
    envKey: 'OPENAI_API_KEY',
  ),
  claude(
    label: 'Claude',
    description: 'Powered by Anthropic',
    envKey: 'CLAUDE_API_KEY',
  );

  const AiProvider({
    required this.label,
    required this.description,
    required this.envKey,
  });

  final String label;
  final String description;
  final String envKey;
}
