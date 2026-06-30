import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/features/exams/presentation/providers/exams_provider.dart';
import 'package:planner/domain/entities/exam.dart';
import 'package:planner/domain/entities/revision.dart';
import 'package:planner/features/exams/presentation/screens/exam_detail_screen.dart';
import 'package:planner/features/exams/presentation/widgets/add_exam_bottom_sheet.dart';
import 'package:planner/features/calendar/presentation/widgets/add_revision_bottom_sheet.dart';
import 'package:planner/features/calendar/presentation/widgets/revision_card.dart';
import 'package:planner/features/calendar/presentation/providers/revisions_provider.dart';
import 'package:planner/core/localization/app_localizations.dart';
import 'package:planner/features/profile/presentation/providers/language_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> with AutomaticKeepAliveClientMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<dynamic> _getEventsForDay(DateTime day, List<Exam> exams, List<Revision> revisions) {
    final dayExams = exams.where((exam) => isSameDay(exam.date, day)).toList();
    final dayRevisions = revisions.where((rev) => isSameDay(rev.date, day)).toList();
    return [...dayExams, ...dayRevisions];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final allExams = ref.watch(examsProvider);
    final allRevisions = ref.watch(revisionsProvider);
    final selectedDayEvents = _getEventsForDay(_selectedDay ?? _focusedDay, allExams, allRevisions);
    
    // Sort events by date and time
    selectedDayEvents.sort((a, b) {
      DateTime dateTimeA;
      DateTime dateTimeB;
      
      if (a is Exam) {
        dateTimeA = _combineDateAndTime(a.date, a.time);
      } else {
        dateTimeA = _combineDateAndTime((a as Revision).date, a.time);
      }
      
      if (b is Exam) {
        dateTimeB = _combineDateAndTime(b.date, b.time);
      } else {
        dateTimeB = _combineDateAndTime((b as Revision).date, b.time);
      }
      
      return dateTimeA.compareTo(dateTimeB);
    });

    final theme = Theme.of(context);
    final langCode = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, langCode),
            _buildCalendar(allExams, allRevisions),
            const SizedBox(height: 12),
            Expanded(
              child: _buildEventsForDayList(selectedDayEvents, langCode),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_exam',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddExamBottomSheet(
                  initialDate: _selectedDay ?? _focusedDay,
                ),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.school_rounded, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add_revision',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddRevisionBottomSheet(
                  initialDate: _selectedDay ?? _focusedDay,
                ),
              );
            },
            backgroundColor: AppColors.secondary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(AppLocalizations.get('add_revision', langCode), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String langCode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.get('calendar', langCode),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  letterSpacing: -1,
                ),
              ),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => setState(() => _selectedDay = DateTime.now()),
            icon: const Icon(Icons.today_rounded, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<Exam> exams, List<Revision> revisions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.utc(2024, 01, 01),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => _getEventsForDay(day, exams, revisions),
        startingDayOfWeek: StartingDayOfWeek.monday,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: AppColors.error.withValues(alpha: 0.8)),
          defaultTextStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          weekendStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildEventsForDayList(List<dynamic> events, String langCode) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 60, color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('no_results', langCode),
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        if (event is Exam) {
          return _buildMiniExamCard(event);
        } else if (event is Revision) {
          return RevisionCard(revision: event);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildMiniExamCard(Exam exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          exam.subject,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        subtitle: Text(
          '${exam.time} • ${exam.room}',
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        trailing: const Icon(Icons.school_rounded, color: AppColors.primary),
        onTap: () {
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExamDetailScreen(exam: exam, isUpcoming: true),
            ),
          );
        },
      ),
    );
  }

  DateTime _combineDateAndTime(DateTime date, String timeStr) {
    try {
      final cleanTime = timeStr.replaceAll(RegExp(r'[a-zA-Z\s]'), '');
      final parts = cleanTime.split(':');
      int hour = int.parse(parts[0].trim());
      int minute = int.parse(parts[1].trim());
      
      if (timeStr.toLowerCase().contains('pm') && hour < 12) {
        hour += 12;
      } else if (timeStr.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }
      
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return date; // fallback to just date
    }
  }
}
