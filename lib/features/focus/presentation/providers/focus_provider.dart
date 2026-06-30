import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/network/api_service.dart';

class FocusStats {
  final int todayMinutes;
  final int totalMinutes;
  final int currentStreak;

  FocusStats({required this.todayMinutes, required this.totalMinutes, this.currentStreak = 0});

  factory FocusStats.fromJson(Map<String, dynamic> json) {
    return FocusStats(
      todayMinutes: json['today_minutes'] ?? 0,
      totalMinutes: json['total_minutes'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
    );
  }
}

final focusProvider = StateNotifierProvider<FocusNotifier, FocusStats?>((ref) {
  return FocusNotifier();
});

class FocusNotifier extends StateNotifier<FocusStats?> {
  FocusNotifier() : super(null) {
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final data = await ApiService.getFocusStats();
      state = FocusStats.fromJson(data);
    } catch (e) {
      // Manage error
    }
  }

  Future<void> addSession(int minutes, String type) async {
    try {
      await ApiService.createFocusSession(minutes, type);
      await loadStats();
    } catch (e) {
      // Manage error
    }
  }
}
