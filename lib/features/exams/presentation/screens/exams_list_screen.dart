import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/features/exams/presentation/providers/exams_provider.dart';
import 'package:planner/features/exams/presentation/providers/filtered_exams_provider.dart';
import 'package:planner/domain/entities/exam.dart';
import 'package:intl/intl.dart';
import 'package:planner/features/exams/presentation/widgets/add_exam_bottom_sheet.dart';
import 'package:planner/features/exams/presentation/screens/exam_detail_screen.dart';

class ExamsListScreen extends ConsumerStatefulWidget {
  const ExamsListScreen({super.key});

  @override
  ConsumerState<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends ConsumerState<ExamsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _levels = ['Tous', 'L1', 'L2', 'L3', 'M1', 'M2'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final status = _tabController.index == 0 
        ? ExamStatusFilter.all 
        : _tabController.index == 1 
            ? ExamStatusFilter.upcoming 
            : ExamStatusFilter.history;
    
    ref.read(examFiltersProvider.notifier).update((s) => s.copyWith(status: status));
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExams = ref.watch(filteredExamsProvider);
    final filters = ref.watch(examFiltersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _AnimatedEntry(delay: 0, child: _buildHeader(context)),
            _AnimatedEntry(delay: 100, child: _buildSearchBar(context)),
            _AnimatedEntry(delay: 150, child: _buildLevelFilter(context, filters)),
            _AnimatedEntry(delay: 200, child: _buildTabBar(context)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(examsProvider.notifier).refresh(),
                color: AppColors.primary,
                child: _buildExamsList(filteredExams),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AnimatedEntry(
        delay: 600,
        child: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddExamBottomSheet(),
            );
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _buildLevelFilter(BuildContext context, ExamFilters filters) {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final level = _levels[index];
          final isSelected = filters.selectedLevel == level;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(level),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(examFiltersProvider.notifier).update((s) => s.copyWith(selectedLevel: level));
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide.none,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Examens',
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
            onPressed: () => ref.read(examsProvider.notifier).refresh(),
            icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            ref.read(examFiltersProvider.notifier).update((s) => s.copyWith(searchQuery: value));
          },
          decoration: InputDecoration(
            hintText: 'Rechercher une matière, salle, prof...',
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.4), fontWeight: FontWeight.w600),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(examFiltersProvider.notifier).update((s) => s.copyWith(searchQuery: ''));
                  },
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Tous'),
          Tab(text: 'À venir'),
          Tab(text: 'Historique'),
        ],
      ),
    );
  }

  Widget _buildExamsList(List<Exam> exams) {
    if (exams.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: const Icon(Icons.search_off_rounded, size: 80, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Aucun résultat',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos filtres.',
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        return _AnimatedEntry(
          delay: index < 5 ? 300 + (index * 100) : 0, // No delay for deep items to avoid long wait
          child: _buildExamListItem(context, exams[index]),
        );
      },
    );
  }

  Widget _buildExamListItem(BuildContext context, Exam exam) {
    final bool isUpcoming = exam.date.isAfter(DateTime.now().subtract(const Duration(hours: 24))); // Simple threshold
    final theme = Theme.of(context);
    
    return Dismissible(
      key: Key(exam.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(examsProvider.notifier).removeExam(exam.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${exam.subject} supprimé'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(30)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    reverseTransitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (context, animation, secondaryAnimation) => 
                      ExamDetailScreen(exam: exam, isUpcoming: isUpcoming),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              child: Hero(
                tag: 'exam_card_${exam.id}',
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        decoration: BoxDecoration(
                          gradient: isUpcoming ? AppColors.primaryGradient : null,
                          color: isUpcoming ? null : Colors.grey.shade400,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (isUpcoming ? AppColors.primary : Colors.grey).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      exam.level,
                                      style: TextStyle(
                                        color: isUpcoming ? AppColors.primary : Colors.grey,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => AddExamBottomSheet(examToEdit: exam),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd MMM').format(exam.date),
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Material(
                                color: Colors.transparent,
                                child: Text(
                                  exam.subject,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  _buildDetailIcon(Icons.access_time_rounded, exam.time),
                                  const SizedBox(width: 20),
                                  _buildDetailIcon(Icons.location_on_rounded, exam.room),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
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
