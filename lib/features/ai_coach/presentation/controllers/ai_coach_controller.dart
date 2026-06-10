import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/data/repositories/dashboard_stats_repository.dart';
import '../../../dashboard/domain/models/dashboard_stats_model.dart';
import '../../../dashboard/domain/models/ai_usage_stats_model.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/ai_rate_limiter_service.dart';
import '../../data/services/gemini_service.dart';
import '../../domain/models/ai_context_model.dart';
import '../../domain/models/chat_message_model.dart';

class AICoachState {
  final List<ChatMessageModel> messages;
  final bool isTyping;
  final String? errorMessage;
  final String partialResponse; // For streaming tokens

  AICoachState({
    required this.messages,
    this.isTyping = false,
    this.errorMessage,
    this.partialResponse = '',
  });

  AICoachState copyWith({
    List<ChatMessageModel>? messages,
    bool? isTyping,
    String? errorMessage,
    String? partialResponse,
  }) {
    return AICoachState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage,
      partialResponse: partialResponse ?? this.partialResponse,
    );
  }
}

class AICoachController extends StateNotifier<AICoachState> {
  AICoachController(this._ref, this._chatRepo, this._geminiService, this._rateLimiter)
      : super(AICoachState(messages: [])) {
    _loadHistory();
  }

  final Ref _ref;
  final ChatRepository _chatRepo;
  final GeminiService _geminiService;
  final AIRateLimiterService _rateLimiter;

  Future<void> _loadHistory() async {
    final user = _ref.read(authControllerProvider).value;
    if (user != null) {
      await _chatRepo.init();
      final history = _chatRepo.getHistory(user.uid);
      if (history.isEmpty) {
        // Add a friendly greeting if no history
        final greeting = ChatMessageModel(
          id: const Uuid().v4(),
          messageType: ChatMessageType.assistant,
          text: "Hi! I'm your Xenova Health AI Coach. How can I help you reach your goals today?",
          timestamp: DateTime.now(),
        );
        state = state.copyWith(messages: [greeting]);
      } else {
        state = state.copyWith(messages: history);
      }
    }
  }

  Future<void> sendMessage(String text) async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null || text.trim().isEmpty) return;

    final canRequest = await _rateLimiter.canMakeRequest(user.uid);
    if (!canRequest) {
      state = state.copyWith(
        errorMessage: "You've reached your AI Coach limit for now. Please try again later.",
      );
      return;
    }

    final userMessage = ChatMessageModel(
      id: const Uuid().v4(),
      messageType: ChatMessageType.user,
      text: text,
      timestamp: DateTime.now(),
    );

    // Optimistic UI update
    final updatedMessages = List<ChatMessageModel>.from(state.messages)..add(userMessage);
    state = state.copyWith(
      messages: updatedMessages,
      isTyping: true,
      errorMessage: null,
      partialResponse: '',
    );

    await _chatRepo.addMessage(user.uid, userMessage);

    try {
      // 1. Build Context Model
      final contextModel = await _buildAIContext(user.uid);

      // 2. Start Gemini Session
      final session = _geminiService.startChat(contextModel, state.messages);

      // 3. Stream Response
      final stream = _geminiService.sendMessageStream(session, text);

      await for (final chunk in stream) {
        state = state.copyWith(
          partialResponse: state.partialResponse + chunk,
          isTyping: true, // keep typing indicator alive while streaming
        );
      }

      // 4. Save Final Message
      final assistantMessage = ChatMessageModel(
        id: const Uuid().v4(),
        messageType: ChatMessageType.assistant,
        text: state.partialResponse,
        timestamp: DateTime.now(),
        contextVersionUsed: contextModel.contextVersion,
      );

      final finalMessages = List<ChatMessageModel>.from(state.messages)..add(assistantMessage);
      
      state = state.copyWith(
        messages: finalMessages,
        isTyping: false,
        partialResponse: '',
      );

      await _chatRepo.addMessage(user.uid, assistantMessage);
      await _rateLimiter.recordRequest(user.uid);
      await _updateAiUsageStats(user.uid, assistantMessage.text.length, true, text);

    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        partialResponse: '',
        errorMessage: "AI Coach is temporarily unavailable.",
      );
      await _updateAiUsageStats(user.uid, 0, false, text);
    }
  }

  Future<void> _updateAiUsageStats(String userId, int responseLength, bool success, String prompt) async {
    final statsRepo = _ref.read(dashboardStatsRepositoryProvider);
    final stats = await statsRepo.getStats(userId);
    if (stats == null) return;

    final currentAi = stats.aiStats ?? const AiUsageStats();
    
    final newAiStats = currentAi.copyWith(
      totalRequests: currentAi.totalRequests + 1,
      successfulRequests: success ? currentAi.successfulRequests + 1 : currentAi.successfulRequests,
      failedRequests: !success ? currentAi.failedRequests + 1 : currentAi.failedRequests,
      lastRequest: DateTime.now(),
      totalChats: currentAi.totalChats + 1, // simplified for now
      averageResponseLength: currentAi.averageResponseLength == 0 
          ? responseLength.toDouble() 
          : (currentAi.averageResponseLength + responseLength) / 2,
    );

    final newStats = stats.copyWith(aiStats: newAiStats);
    await statsRepo.updateStats(userId, newStats);
  }

  Future<AIContextModel> _buildAIContext(String userId) async {
    // In a real app, we'd fetch the latest AnalyticsSnapshot here from the DB or a provider.
    // For MVP, we'll build a synthetic snapshot based on dashboard stats.
    final profile = await _ref.read(userProfileRepositoryProvider).getProfile(userId);
    final stats = await _ref.read(dashboardStatsRepositoryProvider).getStats(userId);

    int? age;
    if (profile?.dateOfBirth != null) {
      age = DateTime.now().year - profile!.dateOfBirth!.year;
    }

    return AIContextModel(
      contextVersion: '1.0',
      generatedAt: DateTime.now(),
      ageRange: age,
      gender: profile?.gender,
      heightCm: profile?.heightCm,
      goalType: profile?.goalType,
      healthScore: stats?.healthScore?.overallHealthScore ?? 0.0,
      consistencyScore: 0.0, // Should come from Analytics Snapshot
      weightTrend: 0.0,
      nutritionMetrics: {},
      fastingMetrics: {},
      goalProgress: stats?.goalProgress ?? 0.0,
      proteinGoalMet: false,
      waterGoalMet: false,
      calorieTargetMet: false,
    );
  }
}

final aiCoachControllerProvider = StateNotifierProvider<AICoachController, AICoachState>((ref) {
  return AICoachController(
    ref,
    ref.watch(chatRepositoryProvider),
    ref.watch(geminiServiceProvider),
    ref.watch(aiRateLimiterServiceProvider),
  );
});
