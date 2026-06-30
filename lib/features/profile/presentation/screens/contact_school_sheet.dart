import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/features/profile/presentation/providers/language_provider.dart';
import 'package:planner/core/localization/app_localizations.dart';
import 'package:planner/core/network/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSchoolSheet extends ConsumerStatefulWidget {
  const ContactSchoolSheet({super.key});

  @override
  ConsumerState<ContactSchoolSheet> createState() => _ContactSchoolSheetState();
}

class _ContactSchoolSheetState extends ConsumerState<ContactSchoolSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedSubject;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (_formKey.currentState!.validate() && _selectedSubject != null) {
      setState(() => _isLoading = true);
      try {
        final email = _emailController.text.trim();
        final subject = Uri.encodeComponent(_selectedSubject!);
        final body = Uri.encodeComponent(_messageController.text);
        
        final Uri emailUri = Uri.parse('mailto:$email?subject=$subject&body=$body');
        
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ouverture de votre application mail...'), backgroundColor: AppColors.success),
            );
          }
        } else {
          // Fallback if no mail client is available
          await ApiService.sendEmail(
            to: email,
            subject: _selectedSubject!,
            message: _messageController.text,
          );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email envoyé via le serveur !'), backgroundColor: AppColors.success),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: impossible d\'envoyer l\'email'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(languageProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final subjects = [
      AppLocalizations.get('reason_absence', langCode),
      AppLocalizations.get('reason_delay', langCode),
      AppLocalizations.get('reason_other', langCode),
    ];

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.email_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppLocalizations.get('contact_school', langCode),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedSubject = v),
                    validator: (v) => v == null ? 'Requis' : null,
                    dropdownColor: Theme.of(context).cardColor,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.get('subject', langCode),
                      prefixIcon: const Icon(Icons.topic_rounded, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Email de destination',
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.get('message', langCode),
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 80),
                        child: Icon(Icons.edit_note_rounded, color: Colors.grey),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    icon: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      _isLoading ? 'Envoi en cours...' : AppLocalizations.get('send', langCode),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
}
