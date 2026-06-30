import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/domain/entities/exam.dart';
import 'package:planner/features/exams/presentation/providers/exams_provider.dart';

enum ExamStatusFilter { all, upcoming, history }

// État pour la recherche et les filtres
class ExamFilters {
  final String searchQuery;
  final String selectedLevel;
  final ExamStatusFilter status;

  const ExamFilters({
    this.searchQuery = '',
    this.selectedLevel = 'Tous',
    this.status = ExamStatusFilter.all,
  });

  ExamFilters copyWith({String? searchQuery, String? selectedLevel, ExamStatusFilter? status}) {
    return ExamFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      status: status ?? this.status,
    );
  }
}

// Provider pour l'état des filtres
final examFiltersProvider = StateProvider((ref) => const ExamFilters());

// Provider pour la liste d'examens filtrée
final filteredExamsProvider = Provider<List<Exam>>((ref) {
  final exams = ref.watch(examsProvider);
  final filters = ref.watch(examFiltersProvider);

  return exams.where((exam) {
    // 1. Filtre par texte (Sujet, Prof ou Salle)
    final matchesSearch = exam.subject.toLowerCase().contains(filters.searchQuery.toLowerCase()) ||
                         exam.teacher.toLowerCase().contains(filters.searchQuery.toLowerCase()) ||
                         exam.room.toLowerCase().contains(filters.searchQuery.toLowerCase()) ||
                         exam.level.toLowerCase().contains(filters.searchQuery.toLowerCase());
    
    // 2. Filtre par niveau (Ex: L3)
    final matchesLevel = filters.selectedLevel == 'Tous' || exam.level == filters.selectedLevel;

    // 3. Filtre par statut (Upcoming / History)
    bool matchesStatus = true;
    final now = DateTime.now();
    if (filters.status == ExamStatusFilter.upcoming) {
      matchesStatus = exam.date.isAfter(now) || (exam.date.day == now.day && exam.date.month == now.month && exam.date.year == now.year);
    } else if (filters.status == ExamStatusFilter.history) {
      matchesStatus = exam.date.isBefore(now) && !(exam.date.day == now.day && exam.date.month == now.month && exam.date.year == now.year);
    }

    return matchesSearch && matchesLevel && matchesStatus;
  }).toList();
});
