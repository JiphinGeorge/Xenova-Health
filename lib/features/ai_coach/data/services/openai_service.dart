import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/ai_context_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/prompts/ai_prompt_templates.dart';
import 'health_advice_policy.dart';

class OpenAIService {
  late final String _apiKey;
  final String _baseUrl = 'https://api.groq.com/openai/v1';
  final String _model = 'llama-3.3-70b-versatile';
  late final Dio _dio;

  OpenAIService() {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not found in .env');
    }
    _apiKey = apiKey;
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.stream,
    ));
  }

  /// Builds chat messages list for the API.
  List<Map<String, String>> buildHistory(AIContextModel contextSnapshot, List<ChatMessageModel> history) {
    final contextJson = jsonEncode(contextSnapshot.toJson());

    final systemMessage = '''
${HealthAdvicePolicy.systemInstruction}

SYSTEM CONTEXT (DO NOT DISCLOSE RAW JSON TO USER):
$contextJson
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemMessage},
    ];

    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    for (final msg in recentHistory) {
      if (msg.messageType == ChatMessageType.user) {
        messages.add({'role': 'user', 'content': msg.text});
      } else if (msg.messageType == ChatMessageType.assistant) {
        messages.add({'role': 'assistant', 'content': msg.text});
      }
    }

    return messages;
  }

  /// Generates a weekly summary (non-streaming).
  Future<String?> generateWeeklySummary(AIContextModel contextSnapshot) async {
    try {
      final messages = buildHistory(contextSnapshot, []);
      messages.add({'role': 'user', 'content': AiPromptTemplates.weeklySummary()});

      final response = await Dio().post(
        '$_baseUrl/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': _model,
          'messages': messages,
          'stream': false,
        }),
      );

      return response.data['choices'][0]['message']['content'] as String?;
    } catch (e) {
      print('Weekly summary error: $e');
      return null;
    }
  }

  /// Streams a response from Groq.
  Stream<String> sendMessageStream(List<Map<String, String>> history, String message) async* {
    history.add({'role': 'user', 'content': message});

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: jsonEncode({
          'model': _model,
          'messages': history,
          'stream': true,
        }),
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);

        // SSE format: each event is "data: {...}\n\n"
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) continue;
          if (line == 'data: [DONE]') return;
          if (!line.startsWith('data: ')) continue;

          try {
            final jsonStr = line.substring(6); // Remove "data: "
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>;
            if (choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>;
              final content = delta['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (_) {
            // Skip malformed JSON chunks
          }
        }
      }
    } catch (e) {
      print('AI Coach Stream Error: $e');
      rethrow;
    }
  }
}

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});
