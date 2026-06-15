import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/presentation/providers/theme_provider.dart';
import 'package:planner/features/auth/presentation/providers/user_provider.dart';
import 'package:planner/features/exams/presentation/providers/exams_provider.dart';
import 'package:planner/features/rooms/presentation/providers/rooms_provider.dart';
import 'package:planner/domain/entities/exam.dart';
import 'package:planner/features/exams/presentation/screens/exam_detail_screen.dart';
import 'package:planner/core/network/api_service.dart';
import 'package:planner/presentation/providers/navigation_provider.dart';
import 'package:planner/features/results/presentation/screens/results_screen.dart';
import 'package:planner/features/focus/presentation/screens/focus_timer_screen.dart';
import 'package:planner/features/focus/presentation/providers/focus_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    final allExams = ref.watch(examsProvider);
    final rooms = ref.watch(roomsProvider);

    // Calculs statistiques
    final now = DateTime.now();
    final upcomingExams = allExams.where((e) => e.date.isAfter(now.subtract(const Duration(hours: 12)))).toList();
    final availableRooms = rooms.where((r) => !r.isOccupied).length;
    
    // Sort upcoming exams to find the next one
    upcomingExams.sort((a, b) => a.date.compareTo(b.date));
    final nextExams = upcomingExams.take(3).toList();

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
                        _AnimatedEntry(delay: 0, child: _buildTopBar(context, ref, user)),
                        const SizedBox(height: 32),
                        _AnimatedEntry(delay: 100, child: _buildWelcomeSection(context, user)),
                        const SizedBox(height: 32),
                        _AnimatedEntry(
                          delay: 300, 
                          child: _buildStatsSection(
                            context, 
                            upcomingExams.length.toString(), 
                            availableRooms.toString(),
                            ref.watch(focusProvider)?.todayMinutes.toString() ?? '0',
                          )
                        ),
                        const SizedBox(height: 32),
                        _AnimatedEntry(delay: 400, child: _buildSectionHeader(context, "Prochains Examens", true, ref: ref, targetIndex: 1)),
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
                        _AnimatedEntry(delay: 500, child: _buildSectionHeader(context, "Actions Rapides", false, ref: ref)),
                        const SizedBox(height: 16),
                        _AnimatedEntry(delay: 600, child: _buildQuickActionsRow(context, ref)),
                        const SizedBox(height: 32),
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
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, UserData? user) {
    final initials = user != null ? user.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase() : '??';
    final imageUrl = user?.profileImage != null ? '${ApiService.serverBaseUrl}${user!.profileImage}' : null;

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
                gradient: imageUrl == null ? AppColors.primaryGradient : null,
                image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: imageUrl == null 
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
        Container(
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
          child: IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppColors.primary, size: 22),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context, UserData? user) {
    final firstName = user != null ? user.fullName.split(' ')[0] : 'Student';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: Text('BONJOUR, $firstName! 👋', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
        ),
        const SizedBox(height: 8),
        Text(
          'Prêt pour votre\nprochaine session ?',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 32, height: 1.1, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, String examsCount, String roomsCount, String focusMinutes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildEnhancedStatCard(context, examsCount, "Examens", Icons.assignment_rounded, AppColors.primary),
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
              child: Text(exam.time, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
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

  Widget _buildQuickActionsRow(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickAction(context, "Examens", Icons.assignment_rounded, AppColors.primary, onTap: () => ref.read(navigationProvider.notifier).state = 1),
        _buildQuickAction(context, "Salles", Icons.meeting_room_rounded, AppColors.secondary, onTap: () => ref.read(navigationProvider.notifier).state = 2),
        _buildQuickAction(context, "Calendrier", Icons.calendar_today_rounded, AppColors.accent, onTap: () => ref.read(navigationProvider.notifier).state = 3),
        _buildQuickAction(context, "Résultats", Icons.grading_rounded, Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen()))),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(22), border: Border.all(color: color.withValues(alpha: 0.1), width: 2)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
        ],
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
