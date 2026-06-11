import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_openai/dart_openai.dart';

import '../../domain/models/ai_context_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/prompts/ai_prompt_templates.dart';
import 'health_advice_policy.dart';

class OpenAIService {
  OpenAIService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_OPENAI_API_KEY_HERE') {
      throw Exception('OpenAI API key not found in .env');
    }
    
    OpenAI.apiKey = apiKey;
  }

  /// Builds the chat history for OpenAI.
  List<OpenAIChatCompletionChoiceMessageModel> buildHistory(AIContextModel contextSnapshot, List<ChatMessageModel> history) {
    final contextJson = jsonEncode(contextSnapshot.toJson());
    
    final systemMessage = '''
${HealthAdvicePolicy.systemInstruction}

SYSTEM CONTEXT (DO NOT DISCLOSE RAW JSON TO USER):
$contextJson
''';

    final actualHistory = <OpenAIChatCompletionChoiceMessageModel>[
      OpenAIChatCompletionChoiceMessageModel(
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemMessage)],
        role: OpenAIChatMessageRole.system,
      ),
    ];

    // Optimization: Keep only the last 10 messages for context memory
    final recentHistory = history.length > 10 
        ? history.sublist(history.length - 10) 
        : history;

    for (final msg in recentHistory) {
      if (msg.messageType == ChatMessageType.user) {
        actualHistory.add(
          OpenAIChatCompletionChoiceMessageModel(
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(msg.text)],
            role: OpenAIChatMessageRole.user,
          ),
        );
      } else if (msg.messageType == ChatMessageType.assistant) {
        actualHistory.add(
          OpenAIChatCompletionChoiceMessageModel(
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(msg.text)],
            role: OpenAIChatMessageRole.assistant,
          ),
        );
      }
    }

    return actualHistory;
  }

  /// Generates a weekly summary directly.
  Future<String?> generateWeeklySummary(AIContextModel contextSnapshot) async {
    try {
      final history = buildHistory(contextSnapshot, []);
      history.add(
        OpenAIChatCompletionChoiceMessageModel(
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(AiPromptTemplates.weeklySummary())],
          role: OpenAIChatMessageRole.user,
        ),
      );

      final response = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini",
        messages: history,
      );

      return response.choices.first.message.content?.first.text;
    } catch (e) {
      return null;
    }
  }

  /// Streams a response from OpenAI.
  Stream<String> sendMessageStream(List<OpenAIChatCompletionChoiceMessageModel> history, String message) async* {
    history.add(
      OpenAIChatCompletionChoiceMessageModel(
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(message)],
        role: OpenAIChatMessageRole.user,
      ),
    );

    final responseStream = OpenAI.instance.chat.createStream(
      model: "gpt-4o-mini",
      messages: history,
    );

    await for (final chunk in responseStream) {
      final content = chunk.choices.first.delta.content;
      if (content != null && content.isNotEmpty) {
        yield content.first?.text ?? "";
      }
    }
  }
}

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});
