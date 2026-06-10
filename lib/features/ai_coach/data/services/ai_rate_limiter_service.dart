import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AIRateLimiterService {
  static const String _boxName = 'ai_rate_limiter_box';
  static const int _maxRequestsPerHour = 20;
  static const int _maxRequestsPerDay = 100;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  /// Returns true if the user is allowed to make a request, false otherwise.
  Future<bool> canMakeRequest(String userId) async {
    final box = Hive.box<String>(_boxName);
    final jsonStr = box.get(userId);
    List<DateTime> timestamps = [];

    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        timestamps = decoded.map((e) => DateTime.parse(e as String)).toList();
      } catch (_) {}
    }

    final now = DateTime.now();

    // Clean up old timestamps (older than 24 hours)
    timestamps.removeWhere((t) => now.difference(t).inHours >= 24);

    // Check daily limit
    if (timestamps.length >= _maxRequestsPerDay) {
      return false;
    }

    // Check hourly limit
    final lastHourRequests = timestamps.where((t) => now.difference(t).inHours < 1).length;
    if (lastHourRequests >= _maxRequestsPerHour) {
      return false;
    }

    return true;
  }

  /// Records a successful request timestamp.
  Future<void> recordRequest(String userId) async {
    final box = Hive.box<String>(_boxName);
    final jsonStr = box.get(userId);
    List<DateTime> timestamps = [];

    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        timestamps = decoded.map((e) => DateTime.parse(e as String)).toList();
      } catch (_) {}
    }

    final now = DateTime.now();
    timestamps.removeWhere((t) => now.difference(t).inHours >= 24);
    timestamps.add(now);

    await box.put(userId, jsonEncode(timestamps.map((e) => e.toIso8601String()).toList()));
  }
}

final aiRateLimiterServiceProvider = Provider<AIRateLimiterService>((ref) {
  return AIRateLimiterService();
});
