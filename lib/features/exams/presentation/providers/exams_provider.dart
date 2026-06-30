import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/domain/entities/exam.dart';
import 'package:planner/core/network/api_service.dart';
import 'package:planner/core/services/notification_service.dart';

final examsProvider = StateNotifierProvider<ExamsNotifier, List<Exam>>((ref) {
  return ExamsNotifier();
});

class ExamsNotifier extends StateNotifier<List<Exam>> {
  ExamsNotifier() : super([]) {
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final List<dynamic> data = await ApiService.getExams();
      final exams = data.map((item) => Exam.fromJson(item)).toList();
      state = exams;
    } catch (e) {
      state = [];
    }
  }

  Future<void> refresh() async {
    await _loadExams();
  }

  Future<void> addExam(Exam exam) async {
    try {
      await ApiService.createExam(exam.toJson());
      await _loadExams(); // Mettre à jour l'état quoiqu'il arrive
      
      try {
        await NotificationService.showInstantNotification(
          'Examen enregistré',
          'L\'examen de ${exam.subject} a été ajouté avec succès.',
        );
        await NotificationService.scheduleExamNotification(exam);
      } catch (e) {
        print('Erreur notifications: $e');
      }
    } catch (e) {
      print('Erreur API addExam: $e');
      rethrow;
    }
  }

  Future<void> removeExam(String id) async {
    try {
      await ApiService.deleteExam(id);
      state = state.where((exam) => exam.id != id).toList();
    } catch (e) {
      // Gérer l'erreur
    }
  }

  Future<void> updateExam(Exam updatedExam) async {
    try {
      await ApiService.updateExam(updatedExam.id, updatedExam.toJson());
      state = [
        for (final exam in state)
          if (exam.id == updatedExam.id) updatedExam else exam
      ];
    } catch (e) {
      rethrow;
    }
  }
}
