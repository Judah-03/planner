import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/features/results/presentation/providers/results_provider.dart';
import 'package:planner/domain/entities/result.dart';
import 'package:uuid/uuid.dart';
import 'package:planner/features/results/presentation/widgets/results_chart.dart';
import 'package:planner/core/services/pdf_service.dart';
import 'package:planner/features/auth/presentation/providers/user_provider.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(resultsProvider);
    final theme = Theme.of(context);

    // Calculate Average with safety
    double average = 0.0;
    if (results.isNotEmpty) {
      final totalGrades = results.map((e) => e.grade).reduce((a, b) => a + b);
      average = totalGrades / results.length;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mes Résultats', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              final user = ref.read(userProvider);
              PdfService.exportResultsToPdf(results, user, average);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: 'Exporter en PDF',
          ),
          IconButton(
            onPressed: () => ref.read(resultsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Liste'),
            Tab(text: 'Statistiques'),
          ],
        ),
      ),
      body: SafeArea(
        child: results.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grading_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
                    const SizedBox(height: 24),
                    const Text('Aucun résultat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('Ajoutez vos notes pour voir votre progression.', style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 14)),
                  ],
                ),
              )
            : Column(
                children: [
                  _buildAverageCard(context, average),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        RefreshIndicator(
                          onRefresh: () => ref.read(resultsProvider.notifier).refresh(),
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final result = results[index];
                              return _buildResultCard(context, result);
                            },
                          ),
                        ),
                        ResultsChart(results: results),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddResultDialog(context, ref);
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter une note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildAverageCard(BuildContext context, double average) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Moyenne Générale', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '${average.toStringAsFixed(2)} / 20',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
          )
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ExamResult result) {
    final isPass = result.grade >= 10.0;
    
    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
      ),
      onDismissed: (direction) {
        ref.read(resultsProvider.notifier).removeResult(result.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.subject} supprimé')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (isPass ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  result.grade.toString(),
                  style: TextStyle(
                    color: isPass ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.subject, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Semestre: ${result.semester ?? "N/A"} • Crédits: ${result.credits ?? 0}', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddResultDialog(BuildContext context, WidgetRef ref) {
    final subjectController = TextEditingController();
    final gradeController = TextEditingController();
    final creditsController = TextEditingController();
    final semesterController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 32,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nouveau Résultat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              _buildDialogField(subjectController, 'Matière', Icons.book_outlined, (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogField(
                      gradeController, 
                      'Note / 20', 
                      Icons.grade_outlined, 
                      (v) {
                        if (v!.isEmpty) return 'Requis';
                        final val = double.tryParse(v);
                        if (val == null || val < 0 || val > 20) return '0-20';
                        return null;
                      },
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDialogField(
                      creditsController, 
                      'Crédits', 
                      Icons.star_outline, 
                      null, 
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDialogField(semesterController, 'Semestre (ex: S5)', Icons.calendar_today_outlined, null),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      ref.read(resultsProvider.notifier).addResult(
                        ExamResult(
                          id: const Uuid().v4(),
                          subject: subjectController.text.trim(),
                          grade: double.parse(gradeController.text.trim()),
                          credits: int.tryParse(creditsController.text.trim()),
                          semester: semesterController.text.trim(),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    String? Function(String?)? validator,
    {TextInputType keyboardType = TextInputType.text}
  ) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        filled: true,
        fillColor: Colors.orange.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
