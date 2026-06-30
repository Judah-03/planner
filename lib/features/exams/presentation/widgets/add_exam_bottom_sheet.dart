import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/domain/entities/exam.dart';
import 'package:planner/features/exams/presentation/providers/exams_provider.dart';
import 'package:planner/features/rooms/presentation/providers/rooms_provider.dart';
import 'package:uuid/uuid.dart';

class AddExamBottomSheet extends ConsumerStatefulWidget {
  final Exam? examToEdit;
  final DateTime? initialDate;

  const AddExamBottomSheet({super.key, this.examToEdit, this.initialDate});

  @override
  ConsumerState<AddExamBottomSheet> createState() => _AddExamBottomSheetState();
}

class _AddExamBottomSheetState extends ConsumerState<AddExamBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _teacherController;
  String? _selectedRoomName;
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedDuration;
  late String _selectedLevel;

  final List<String> _durations = ['1 heure', '2 heures', '3 heures', '4 heures', '5 heures'];
  final List<String> _levels = ['L1', 'L2', 'L3', 'M1', 'M2'];

  @override
  void initState() {
    super.initState();
    final edit = widget.examToEdit;
    
    _subjectController = TextEditingController(text: edit?.subject ?? '');
    _teacherController = TextEditingController(text: edit?.teacher ?? '');
    _selectedRoomName = edit?.room;
    
    _selectedDate = edit?.date ?? widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedDuration = edit?.duration ?? '2 heures';
    _selectedLevel = edit?.level ?? 'L3';
    
    // Parse time string if editing
    if (edit != null) {
      try {
        final timeParts = edit.time.split(' ');
        final hm = timeParts[0].split(':');
        var hour = int.parse(hm[0]);
        final min = int.parse(hm[1]);
        if (timeParts[1] == 'PM' && hour < 12) hour += 12;
        if (timeParts[1] == 'AM' && hour == 12) hour = 0;
        _selectedTime = TimeOfDay(hour: hour, minute: min);
      } catch (e) {
        _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      }
    } else {
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  void _saveExam() async {
    if (_formKey.currentState!.validate()) {
      final selectedRoom = _selectedRoomName ?? '';
      
      // Conflict checking
      if (selectedRoom.isNotEmpty) {
        final rooms = ref.read(roomsProvider);
        final isRoomGloballyOccupied = rooms.any((r) => r.name == selectedRoom && r.isOccupied);

        if (isRoomGloballyOccupied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Erreur : Cette salle est actuellement marquée comme occupée !',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return; // Stop saving
        }

        final existingExams = ref.read(examsProvider);
        
        DateTime getStartTime(DateTime date, String timeStr) {
           final cleanTime = timeStr.replaceAll(RegExp(r'[a-zA-Z\s]'), '');
           final tParts = cleanTime.split(':');
           int h = int.parse(tParts[0]);
           final m = int.parse(tParts[1]);
           if (timeStr.toLowerCase().contains('pm') && h < 12) h += 12;
           if (timeStr.toLowerCase().contains('am') && h == 12) h = 0;
           return DateTime(date.year, date.month, date.day, h, m);
        }

        DateTime getEndTime(DateTime date, String timeStr, String durationStr) {
           final start = getStartTime(date, timeStr);
           int durHours = 0;
           if (durationStr.contains('heure')) {
             final match = RegExp(r'\d+').firstMatch(durationStr);
             if (match != null) {
               durHours = int.parse(match.group(0)!);
             }
           }
           return start.add(Duration(hours: durHours));
        }

        final newStart = getStartTime(_selectedDate, _selectedTime.format(context));
        final newEnd = getEndTime(_selectedDate, _selectedTime.format(context), _selectedDuration);

        final hasConflict = existingExams.any((e) {
          if (e.room != selectedRoom) return false;
          if (widget.examToEdit != null && e.id == widget.examToEdit!.id) return false;
          
          final eStart = getStartTime(e.date, e.time);
          final eEnd = getEndTime(e.date, e.time, e.duration);
          
          return newStart.isBefore(eEnd) && eStart.isBefore(newEnd);
        });

        if (hasConflict) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Erreur : Un examen parallèle est déjà prévu dans cette salle à cette heure !',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return; // Stop saving
        }
      }

      final exam = Exam(
        id: widget.examToEdit?.id ?? const Uuid().v4(),
        subject: _subjectController.text.trim(),
        date: _selectedDate,
        time: _selectedTime.format(context),
        room: selectedRoom,
        teacher: _teacherController.text.trim(),
        duration: _selectedDuration,
        level: _selectedLevel,
      );

      try {
        if (widget.examToEdit != null) {
          await ref.read(examsProvider.notifier).updateExam(exam);
        } else {
          await ref.read(examsProvider.notifier).addExam(exam);
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.examToEdit != null ? 'Examen mis à jour !' : 'Examen ajouté avec succès !',
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Échec: ${e.toString().replaceAll('Exception:', '').trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickDate() async {
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
              primary: AppColors.primary,
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
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
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
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset > 0 ? bottomInset + 20 : 40),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                widget.examToEdit != null ? 'Modifier l\'examen' : 'Planifier un examen',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _subjectController,
                label: 'Matière',
                icon: Icons.menu_book_rounded,
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une matière' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Niveau',
                      value: _selectedLevel,
                      items: _levels,
                      icon: Icons.school_rounded,
                      onChanged: (value) => setState(() => _selectedLevel = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Durée',
                      value: _selectedDuration,
                      items: _durations,
                      icon: Icons.timer_rounded,
                      onChanged: (value) => setState(() => _selectedDuration = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Date',
                      value: DateFormat('dd MMM yyyy', 'fr_FR').format(_selectedDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Heure',
                      value: _selectedTime.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final rooms = ref.watch(roomsProvider);
                        final roomNames = rooms.map((r) => r.name).toList();
                        
                        final initialValue = (_selectedRoomName != null && roomNames.contains(_selectedRoomName)) 
                            ? _selectedRoomName 
                            : (roomNames.isNotEmpty ? roomNames.first : null);
                            
                        // Ensure we update state if initialValue changes and _selectedRoomName is null or not in list
                        if (_selectedRoomName != initialValue) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _selectedRoomName = initialValue);
                          });
                        }
                        
                        return DropdownButtonFormField<String>(
                          value: initialValue,
                          items: roomNames.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (value) => setState(() => _selectedRoomName = value),
                          decoration: InputDecoration(
                            labelText: 'Salle',
                            prefixIcon: const Icon(Icons.meeting_room_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: Colors.grey.withValues(alpha: 0.08),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _teacherController,
                      label: 'Enseignant',
                      icon: Icons.person_rounded,
                      validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveExam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  widget.examToEdit != null ? 'Mettre à jour' : 'Enregistrer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
