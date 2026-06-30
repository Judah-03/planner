import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/domain/entities/revision.dart';
import 'package:planner/features/calendar/presentation/providers/revisions_provider.dart';
import 'package:planner/core/services/notification_service.dart';

class AddRevisionBottomSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final Revision? revisionToEdit;

  const AddRevisionBottomSheet({
    super.key,
    this.initialDate,
    this.revisionToEdit,
  });

  @override
  ConsumerState<AddRevisionBottomSheet> createState() => _AddRevisionBottomSheetState();
}

class _AddRevisionBottomSheetState extends ConsumerState<AddRevisionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedDuration = '1h 00min';

  final List<String> _durations = ['30min', '1h 00min', '1h 30min', '2h 00min', '3h 00min'];

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final cleanTime = timeStr.replaceAll(RegExp(r'[a-zA-Z\s]'), '');
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());
      
      int finalHour = hour;
      if (timeStr.toLowerCase().contains('pm') && hour < 12) {
        finalHour += 12;
      } else if (timeStr.toLowerCase().contains('am') && hour == 12) {
        finalHour = 0;
      }
      return TimeOfDay(hour: finalHour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  @override
  void initState() {
    super.initState();
    final edit = widget.revisionToEdit;
    
    if (edit != null) {
      _subjectController.text = edit.subject;
      _notesController.text = edit.notes;
      _selectedDate = edit.date;
      _selectedTime = _parseTimeOfDay(edit.time);
      _selectedDuration = edit.duration;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveRevision() async {
    if (_formKey.currentState!.validate()) {
      final revision = Revision(
        id: widget.revisionToEdit?.id ?? const Uuid().v4(),
        subject: _subjectController.text.trim(),
        date: _selectedDate,
        time: _selectedTime.format(context),
        duration: _selectedDuration,
        notes: _notesController.text.trim(),
      );

      try {
        if (widget.revisionToEdit != null) {
          await ref.read(revisionsProvider.notifier).updateRevision(revision);
        } else {
          await ref.read(revisionsProvider.notifier).addRevision(revision);
        }

        // Schedule notification for the revision
        await NotificationService.scheduleRevisionNotification(revision);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session de révision enregistrée !')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              surface: isDark ? Colors.grey.shade900 : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              surface: isDark ? Colors.grey.shade900 : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.revisionToEdit != null ? 'Modifier la révision' : 'Planifier une révision',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _subjectController,
                    label: 'Matière à réviser',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.secondary,
                    validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une matière' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(
                          label: 'Date',
                          value: DateFormat('dd MMM yyyy', 'fr_FR').format(_selectedDate),
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.secondary,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateTimePicker(
                          label: 'Heure',
                          value: _selectedTime.format(context),
                          icon: Icons.access_time_rounded,
                          color: AppColors.secondary,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Durée prévue',
                    value: _selectedDuration,
                    items: _durations,
                    icon: Icons.timer_rounded,
                    color: AppColors.secondary,
                    onChanged: (value) => setState(() => _selectedDuration = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes (chapitres, objectifs...)',
                    icon: Icons.notes_rounded,
                    color: AppColors.secondary,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveRevision,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppColors.secondary.withValues(alpha: 0.5),
                    ),
                    child: const Text(
                      'Enregistrer la session',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Color color,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
