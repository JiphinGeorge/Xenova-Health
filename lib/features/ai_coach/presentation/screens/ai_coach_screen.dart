import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../domain/models/chat_message_model.dart';
import '../controllers/ai_coach_controller.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});

  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickActions = [
    "Analyze my weight trend",
    "Analyze my nutrition",
    "Analyze my fasting consistency",
    "How close am I to my goal?",
    "Suggest a high-protein meal",
    "What should I improve this week?"
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(aiCoachControllerProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachControllerProvider);

    // Auto-scroll when new messages arrive
    ref.listen(aiCoachControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || next.isTyping) {
        _scrollToBottom();
      }
    });

  bool _shouldShowWelcome(AICoachState state) {
    // Show welcome when there are no user messages (only the auto-greeting or empty)
    return state.messages.where((m) => m.messageType == ChatMessageType.user).isEmpty;
  }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New Chat',
            onPressed: () {
              ref.read(aiCoachControllerProvider.notifier).clearChatHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              color: AppColors.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          
          Expanded(
            child: _shouldShowWelcome(state)
                ? _buildWelcomeSection()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return _buildAssistantMessage(state.partialResponse, isTyping: true);
                      }
                      final msg = state.messages[index];
                      if (msg.messageType == ChatMessageType.user) {
                        return _buildUserMessage(msg.text);
                      } else {
                        return _buildAssistantMessage(msg.text);
                      }
                    },
                  ),
          ),
          
          if (!_shouldShowWelcome(state) && state.messages.length <= 3)
            _buildQuickActions(),

          _buildInputArea(state.isTyping),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final suggestions = [
      _SuggestionItem(
        icon: Icons.trending_down_rounded,
        title: 'Analyze my progress',
        subtitle: 'Get insights on your weight trend',
        prompt: 'Analyze my weight trend and tell me how I\'m doing',
      ),
      _SuggestionItem(
        icon: Icons.restaurant_menu_rounded,
        title: 'Meal suggestions',
        subtitle: 'Get personalized meal ideas',
        prompt: 'Suggest a high-protein, low-calorie meal plan for today',
      ),
      _SuggestionItem(
        icon: Icons.timer_rounded,
        title: 'Fasting tips',
        subtitle: 'Optimize your fasting routine',
        prompt: 'Analyze my fasting consistency and suggest improvements',
      ),
      _SuggestionItem(
        icon: Icons.emoji_events_rounded,
        title: 'Weekly review',
        subtitle: 'See what to improve this week',
        prompt: 'What should I improve this week based on my data?',
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // AI Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(height: 20),

          // Greeting
          Text(
            'Hi! I\'m your AI Health Coach',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'I can analyze your health data, suggest meals,\nand help you reach your goals faster.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // "Try asking" label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          const SizedBox(height: 12),

          // Suggestion cards
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: isDark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _sendMessage(s.prompt),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s.icon, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.subtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd, vertical: AppDimensions.spacingSm),
      child: Row(
        children: _quickActions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(action),
              onPressed: () => _sendMessage(action),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd, left: 40),
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg).copyWith(
            bottomRight: const Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(String text, {bool isTyping = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd, right: 40),
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg).copyWith(
            bottomLeft: const Radius.circular(0),
          ),
        ),
        child: isTyping && text.isEmpty
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : MarkdownBody(data: text),
      ),
    );
  }

  Widget _buildInputArea(bool isTyping) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !isTyping,
                decoration: InputDecoration(
                  hintText: 'Ask your AI Coach...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingLg,
                    vertical: AppDimensions.spacingMd,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: isTyping ? null : () => _sendMessage(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String prompt;

  const _SuggestionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });
}
