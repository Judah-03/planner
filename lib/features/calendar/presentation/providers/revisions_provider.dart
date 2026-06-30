import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planner/domain/entities/revision.dart';
import 'package:planner/core/services/notification_service.dart';

class RevisionsNotifier extends StateNotifier<List<Revision>> {
  static const String _storageKey = 'revisions_list';

  RevisionsNotifier() : super([]) {
    _loadRevisions();
  }

  Future<void> _loadRevisions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        state = jsonList.map((e) => Revision.fromJson(e)).toList();
      }
    } catch (e) {
      print('Erreur chargement révisions: $e');
    }
  }

  Future<void> _saveRevisions(List<Revision> revisions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(revisions.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Erreur sauvegarde révisions: $e');
    }
  }

  Future<void> addRevision(Revision revision) async {
    final newState = [...state, revision];
    state = newState;
    await _saveRevisions(newState);
    
    try {
      await NotificationService.scheduleRevisionNotification(revision);
    } catch (e) {
      print('Erreur programmation notification: $e');
    }
  }

  Future<void> updateRevision(Revision revision) async {
    final newState = state.map((r) => r.id == revision.id ? revision : r).toList();
    state = newState;
    await _saveRevisions(newState);
    
    try {
      await NotificationService.cancelNotification(revision.id);
      await NotificationService.scheduleRevisionNotification(revision);
    } catch (e) {
      print('Erreur mise à jour notification: $e');
    }
  }

  Future<void> removeRevision(String id) async {
    final newState = state.where((r) => r.id != id).toList();
    state = newState;
    await _saveRevisions(newState);
    
    try {
      await NotificationService.cancelNotification(id);
    } catch (e) {
      print('Erreur annulation notification: $e');
    }
  }
}

final revisionsProvider = StateNotifierProvider<RevisionsNotifier, List<Revision>>((ref) {
  return RevisionsNotifier();
});
