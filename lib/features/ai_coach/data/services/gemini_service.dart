import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../domain/models/ai_context_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/prompts/ai_prompt_templates.dart';
import 'health_advice_policy.dart';

class GeminiService {
  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Gemini API key not found in .env');
    }
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(HealthAdvicePolicy.systemInstruction),
    );
  }

  late final GenerativeModel _model;

  /// Starts a chat session with the given context and history.
  ChatSession startChat(AIContextModel contextSnapshot, List<ChatMessageModel> history) {
    // Convert context to JSON string to inject as the first hidden message.
    final contextJson = jsonEncode(contextSnapshot.toJson());
    final contextMessage = 'SYSTEM CONTEXT (DO NOT DISCLOSE RAW JSON TO USER):\n$contextJson';
    
    // Build history
    final chatHistory = <Content>[
      Content.text(contextMessage),
    ];

    for (final msg in history) {
      if (msg.messageType == ChatMessageType.user) {
        chatHistory.add(Content.model([TextPart(msg.text)])); // Assuming previous history is model output. Wait, no.
        // Actually, user messages are user, assistant is model.
        // Let's do it right.
      }
    }
    // Correct way to build history for Gemini:
    final actualHistory = <Content>[
      Content('user', [TextPart(contextMessage)]),
      Content('model', [TextPart('Acknowledged. I will use this context for future advice.')]),
    ];

    // Optimization: Keep only the last 10 messages for context memory
    final recentHistory = history.length > 10 
        ? history.sublist(history.length - 10) 
        : history;

    for (final msg in recentHistory) {
      if (msg.messageType == ChatMessageType.user) {
        actualHistory.add(Content('user', [TextPart(msg.text)]));
      } else if (msg.messageType == ChatMessageType.assistant) {
        actualHistory.add(Content('model', [TextPart(msg.text)]));
      }
    }

    return _model.startChat(history: actualHistory);
  }

  /// Generates a weekly summary directly.
  Future<String?> generateWeeklySummary(AIContextModel contextSnapshot) async {
    try {
      final session = startChat(contextSnapshot, []);
      final response = await session.sendMessage(Content.text(AiPromptTemplates.weeklySummary()));
      return response.text;
    } catch (e) {
      return null;
    }
  }

  /// Streams a response from Gemini.
  Stream<String> sendMessageStream(ChatSession session, String message) async* {
    final responseStream = session.sendMessageStream(Content.text(message));
    await for (final chunk in responseStream) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
