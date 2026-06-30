import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:planner/presentation/providers/theme_provider.dart';
import 'package:planner/features/auth/presentation/providers/user_provider.dart';
import 'package:planner/features/exams/presentation/providers/exams_provider.dart';
import 'package:planner/features/rooms/presentation/providers/rooms_provider.dart';
import 'package:planner/domain/entities/exam.dart';
import 'package:planner/features/exams/presentation/screens/exam_detail_screen.dart';
import 'package:planner/presentation/providers/navigation_provider.dart';
import 'package:planner/features/dashboard/presentation/widgets/readiness_widget.dart';
import 'package:planner/features/focus/presentation/screens/focus_timer_screen.dart';
import 'package:planner/features/focus/presentation/providers/focus_provider.dart';
import 'package:planner/features/dashboard/presentation/screens/ai_assistant_screen.dart';
import 'package:planner/core/localization/app_localizations.dart';
import 'package:planner/features/profile/presentation/providers/language_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late ConfettiController _confettiController;
  int _lastStreak = -1;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkStreakMilestone(int streak) {
    if (_lastStreak != -1 && streak > _lastStreak && (streak == 3 || streak == 7 || streak % 30 == 0)) {
      _confettiController.play();
    }
    _lastStreak = streak;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    final allExams = ref.watch(examsProvider);
    final rooms = ref.watch(roomsProvider);
    final langCode = ref.watch(languageProvider);

    // Calculs statistiques
    final now = DateTime.now();
    final upcomingExams = allExams.where((e) => e.date.isAfter(now.subtract(const Duration(hours: 12)))).toList();
    final availableRooms = rooms.where((r) => !r.isOccupied).length;
    
    // Sort upcoming exams to find the next one
    upcomingExams.sort((a, b) => a.date.compareTo(b.date));
    final nextExams = upcomingExams.take(3).toList();

    // Check milestone if loaded
    final stats = ref.watch(focusProvider);
    if (stats != null) {
      // Use microtask to avoid setState during build
      Future.microtask(() => _checkStreakMilestone(stats.currentStreak));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.1)),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AnimatedEntry(delay: 0, child: _buildTopBar(context, ref, user, langCode)),
                        const SizedBox(height: 32),
                        _AnimatedEntry(delay: 100, child: _buildWelcomeSection(context, user, langCode)),
                        const SizedBox(height: 32),
                        _AnimatedEntry(
                          delay: 300, 
                          child: _buildStatsSection(
                            context, 
                            upcomingExams.length.toString(), 
                            availableRooms.toString(),
                            ref.watch(focusProvider)?.todayMinutes.toString() ?? '0',
                            langCode
                          )
                        ),
                        const SizedBox(height: 32),
                        _AnimatedEntry(delay: 350, child: const ReadinessWidget()),
                        const SizedBox(height: 32),
                        _AnimatedEntry(delay: 400, child: _buildSectionHeader(context, AppLocalizations.get('upcoming_exams', langCode), true, ref: ref, targetIndex: 1)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildUpcomingExamsSliver(context, nextExams),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AnimatedEntry(delay: 700, child: _buildSectionHeader(context, "Conseils d'Étude", false, ref: ref)),
                        const SizedBox(height: 16),
                        _AnimatedEntry(
                          delay: 800,
                          child: _buildTipItem(context, "Rappel Actif", "Testez-vous quotidiennement pour mieux retenir.", Icons.psychology_rounded, AppColors.secondary),
                        ),
                        _AnimatedEntry(
                          delay: 900,
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusTimerScreen())),
                            child: _buildTipItem(context, "Technique Pomodoro", "Étudiez 25 min, faites 5 min de pause.", Icons.timer_rounded, AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(AppLocalizations.get('ai_assistant', langCode), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, UserData? user, String langCode) {
    final initials = user != null ? user.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase() : '??';
    // Support both local file paths and network URLs
    ImageProvider? profileImageProvider;
    if (user?.profileImage != null && user!.profileImage!.isNotEmpty) {
      final path = user.profileImage!;
      if (path.startsWith('http')) {
        profileImageProvider = NetworkImage(path);
      } else if (File(path).existsSync()) {
        profileImageProvider = FileImage(File(path));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: profileImageProvider == null ? AppColors.primaryGradient : null,
                image: profileImageProvider != null ? DecorationImage(image: profileImageProvider, fit: BoxFit.cover) : null,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: profileImageProvider == null 
                ? Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))
                : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? 'Utilisateur', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                Text(user?.level ?? 'IT Student', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            if (ref.watch(focusProvider)?.currentStreak != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ref.watch(focusProvider)!.currentStreak > 0 ? Colors.orange.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ref.watch(focusProvider)!.currentStreak > 0 ? Colors.orange.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: ref.watch(focusProvider)!.currentStreak > 0 ? Colors.orange : Colors.grey, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${ref.watch(focusProvider)!.currentStreak}',
                      style: TextStyle(color: ref.watch(focusProvider)!.currentStreak > 0 ? Colors.orange : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
              child: IconButton(
                icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppColors.primary, size: 22),
                onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context, UserData? user, String langCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: Text('${AppLocalizations.get('welcome', langCode).toUpperCase()} EXAMPLANNERJ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
        ),
        const SizedBox(height: 8),
        Text(
          'Prêt pour votre\nprochaine session ?',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 32, height: 1.1, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, String examsCount, String roomsCount, String focusMinutes, String langCode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildEnhancedStatCard(context, examsCount, AppLocalizations.get('exams', langCode), Icons.assignment_rounded, AppColors.primary),
          const SizedBox(width: 16),
          _buildEnhancedStatCard(context, roomsCount, "Salles", Icons.meeting_room_rounded, AppColors.secondary),
          const SizedBox(width: 16),
          _buildEnhancedStatCard(context, "$focusMinutes m", "Étude (Aujourd'hui)", Icons.timer_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(BuildContext context, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool hasAction, {WidgetRef? ref, int? targetIndex}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        if (hasAction)
          TextButton(
            onPressed: () {
              if (ref != null && targetIndex != null) {
                ref.read(navigationProvider.notifier).state = targetIndex;
              }
            }, 
            child: const Text('Voir Tout', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900))
          ),
      ],
    );
  }

  Widget _buildUpcomingExamsSliver(BuildContext context, List<Exam> exams) {
    if (exams.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(30)),
          child: const Center(child: Text('Aucun examen à venir ! 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 220,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemCount: exams.length,
          separatorBuilder: (context, index) => const SizedBox(width: 20),
          itemBuilder: (context, index) {
            return _AnimatedEntry(
              delay: 450 + (index * 100),
              child: _buildExamCard(context, exams[index], index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Exam exam, int index) {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ExamDetailScreen(exam: exam, isUpcoming: true))),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
              child: Text('${DateFormat('dd MMM', 'fr_FR').format(exam.date)} • ${exam.time}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
            const Spacer(),
            Text(exam.subject, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(exam.room, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.grey.withValues(alpha: 0.1))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimatedEntry({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
