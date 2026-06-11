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

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
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
            child: ListView.builder(
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
          
          if (state.messages.length <= 1)
            _buildQuickActions(),

          _buildInputArea(state.isTyping),
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
