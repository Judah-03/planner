import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/domain/entities/revision.dart';
import 'package:planner/features/calendar/presentation/providers/revisions_provider.dart';
import 'package:planner/features/calendar/presentation/widgets/add_revision_bottom_sheet.dart';
import 'package:planner/features/focus/presentation/providers/focus_provider.dart';

class RevisionCard extends ConsumerStatefulWidget {
  final Revision revision;

  const RevisionCard({super.key, required this.revision});

  @override
  ConsumerState<RevisionCard> createState() => _RevisionCardState();
}

class _RevisionCardState extends ConsumerState<RevisionCard> {
  Timer? _timer;
  int _secondsLeft = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    if (widget.revision.status == 'En cours') {
      _startLocalTimer();
    }
  }

  @override
  void didUpdateWidget(covariant RevisionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision.status == 'En cours' && !_isTimerRunning) {
      _startLocalTimer();
    } else if (widget.revision.status != 'En cours' && _isTimerRunning) {
      _timer?.cancel();
      _isTimerRunning = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _getDurationInMinutes(String durationStr) {
    // Expected format: '1h 30min' or '30min'
    int minutes = 0;
    if (durationStr.contains('h')) {
      final parts = durationStr.split('h');
      minutes += int.parse(parts[0].trim()) * 60;
      if (parts.length > 1 && parts[1].contains('min')) {
        minutes += int.parse(parts[1].replaceAll('min', '').trim());
      }
    } else if (durationStr.contains('min')) {
      minutes += int.parse(durationStr.replaceAll('min', '').trim());
    }
    return minutes;
  }

  void _startLocalTimer() {
    final totalMinutes = _getDurationInMinutes(widget.revision.duration);
    _secondsLeft = totalMinutes * 60;
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _finishRevision();
      }
    });
  }

  void _finishRevision() {
    _timer?.cancel();
    _isTimerRunning = false;
    final updated = widget.revision.copyWith(status: 'Terminé');
    ref.read(revisionsProvider.notifier).updateRevision(updated);
    
    // Add to focus stats (streak) using actual elapsed time
    final totalMinutes = _getDurationInMinutes(widget.revision.duration);
    final totalSeconds = totalMinutes * 60;
    final elapsedSeconds = totalSeconds - _secondsLeft;
    
    int minutesToAdd = (elapsedSeconds / 60).ceil();
    if (minutesToAdd < 1 && elapsedSeconds > 0) minutesToAdd = 1; // Minimum 1 minute if started
    
    if (minutesToAdd > 0) {
      ref.read(focusProvider.notifier).addSession(minutesToAdd, 'révision');
    }
  }

  String _formatTimer(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final rev = widget.revision;
    final isDone = rev.status == 'Terminé';
    final isRunning = rev.status == 'En cours';

    // It can start if the exact date and time is reached or past
    final now = DateTime.now();
    
    int revHour = 0;
    int revMin = 0;
    try {
      final cleanTime = rev.time.replaceAll(RegExp(r'[a-zA-Z\s]'), '');
      final parts = cleanTime.split(':');
      revHour = int.parse(parts[0].trim());
      revMin = int.parse(parts[1].trim());
      if (rev.time.toLowerCase().contains('pm') && revHour < 12) {
        revHour += 12;
      } else if (rev.time.toLowerCase().contains('am') && revHour == 12) {
        revHour = 0;
      }
    } catch (_) {}

    final revDateTime = DateTime(rev.date.year, rev.date.month, rev.date.day, revHour, revMin);
    final canStart = (now.isAfter(revDateTime) || now.isAtSameMomentAs(revDateTime)) && !isDone && !isRunning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? Colors.grey.withValues(alpha: 0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRunning ? AppColors.secondary : Colors.white.withValues(alpha: 0.05),
          width: isRunning ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                color: isDone ? Colors.grey : AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(
              rev.subject,
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 16,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : null,
              ),
            ),
            subtitle: Text(
              '${rev.time} • ${rev.duration} • ${rev.status}',
              style: TextStyle(
                color: isRunning ? AppColors.secondary : Colors.grey.shade500,
                fontWeight: isRunning ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.grey),
                  onPressed: isDone ? null : () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddRevisionBottomSheet(revisionToEdit: rev),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
                  onPressed: () {
                    ref.read(revisionsProvider.notifier).removeRevision(rev.id);
                  },
                ),
              ],
            ),
          ),
          
          if (isRunning)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimer(_secondsLeft),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.secondary),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _finishRevision,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Terminer'),
                  ),
                ],
              ),
            )
          else if (canStart)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final updated = rev.copyWith(status: 'En cours');
                    ref.read(revisionsProvider.notifier).updateRevision(updated);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Commencer la révision'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
