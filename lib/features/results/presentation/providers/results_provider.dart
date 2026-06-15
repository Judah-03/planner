import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/domain/entities/result.dart';
import 'package:planner/core/network/api_service.dart';

final resultsProvider = StateNotifierProvider<ResultsNotifier, List<ExamResult>>((ref) {
  return ResultsNotifier();
});

class ResultsNotifier extends StateNotifier<List<ExamResult>> {
  ResultsNotifier() : super([]) {
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final List<dynamic> data = await ApiService.getResults();
      final results = data.map((item) => ExamResult.fromJson(item)).toList();
      state = results;
    } catch (e) {
      state = [];
    }
  }

  Future<void> refresh() async {
    await _loadResults();
  }

  Future<void> addResult(ExamResult result) async {
    try {
      await ApiService.createResult(result.toJson());
      await _loadResults();
    } catch (e) {
      // Manage error
    }
  }

  Future<void> removeResult(String id) async {
    try {
      await ApiService.deleteResult(id);
      state = state.where((r) => r.id != id).toList();
    } catch (e) {
      // Manage error
    }
  }
}
