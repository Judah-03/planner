import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/features/exams/presentation/providers/exams_provider.dart';
import 'package:planner/features/focus/presentation/providers/focus_provider.dart';

class ReadinessWidget extends ConsumerWidget {
  const ReadinessWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(examsProvider);
    final focusState = ref.watch(focusProvider);
    
    final upcomingExams = exams.where((e) => e.date.isAfter(DateTime.now())).toList();
    
    // Simulate Readiness calculation
    // Base readiness: 50% if there are exams. Increases by 10% per focus session completed, up to 100%
    int readinessScore = 100;
    
    if (upcomingExams.isNotEmpty) {
      final base = 40;
      final sessionBonus = ((focusState?.todayMinutes ?? 0) / 25).floor() * 15;
      readinessScore = (base + sessionBonus).clamp(0, 100).toInt();
    }
    
    // Determine color based on score
    Color scoreColor = AppColors.success;
    if (readinessScore < 50) { scoreColor = AppColors.error; }
    else if (readinessScore < 80) { scoreColor = AppColors.warning; }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: readinessScore / 100,
                  strokeWidth: 8,
                  backgroundColor: scoreColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
                Center(
                  child: Text(
                    '$readinessScore%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score de Préparation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  upcomingExams.isEmpty 
                      ? "Aucun examen prévu. Vous êtes à jour !" 
                      : readinessScore >= 80 
                          ? "Excellent rythme ! Vous êtes bien préparé pour vos prochains examens."
                          : "Attention ! Augmentez vos sessions Pomodoro pour être prêt le jour J.",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
