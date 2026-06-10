import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/models/chat_message_model.dart';

class ChatRepository {
  static const String _boxName = 'chat_history_box';
  static const int _maxMessages = 100;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  /// Gets the chat history for a user.
  List<ChatMessageModel> getHistory(String userId) {
    final box = Hive.box<String>(_boxName);
    final jsonStr = box.get(userId);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Adds a message to the history.
  Future<void> addMessage(String userId, ChatMessageModel message) async {
    final history = getHistory(userId);
    history.add(message);
    
    // Retain only the last 100 messages
    if (history.length > _maxMessages) {
      history.removeRange(0, history.length - _maxMessages);
    }

    final box = Hive.box<String>(_boxName);
    final jsonStr = jsonEncode(history.map((e) => e.toJson()).toList());
    await box.put(userId, jsonStr);
  }

  /// Clears chat history.
  Future<void> clearHistory(String userId) async {
    final box = Hive.box<String>(_boxName);
    await box.delete(userId);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});
