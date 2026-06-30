import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:planner/domain/entities/exam.dart';
import 'package:planner/domain/entities/revision.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const _historyKey = 'notifications_history';

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'Planner',
      appUserModelId: 'com.judah.planner',
      guid: '1a5db210-242e-4bc2-81d6-e784ec19d382',
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      windows: initializationSettingsWindows,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Logique quand on clique sur la notification
      },
    );

    // Demander les permissions sur Android 13+
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }
  
  static Future<void> _saveToHistory(String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];
      final notif = {
        'title': title,
        'body': body,
        'time': DateTime.now().toIso8601String(),
      };
      list.insert(0, jsonEncode(notif));
      if (list.length > 50) list.removeLast();
      await prefs.setStringList(_historyKey, list);
    } catch (e) {
      print('Erreur sauvegarde historique notification: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];
      return list.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'planner_channel_v4',
      'Planner Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
    
    await _saveToHistory(title, body);
  }

  static Future<void> scheduleExamNotification(Exam exam) async {
    try {
      final scheduleDate = exam.date.subtract(const Duration(hours: 24));
      
      // Si l'examen est déjà demain ou passé, on ne programme rien
      if (scheduleDate.isBefore(DateTime.now())) return;
      
      final title = 'Examen à venir : ${exam.subject}';
      final body = 'Votre examen commence dans 24 heures en ${exam.room}. Bonne chance !';

      await _notificationsPlugin.zonedSchedule(
        id: exam.id.hashCode,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduleDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'exam_reminders_v4',
            'Rappels d\'examens',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
          ),
          windows: WindowsNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      await _saveToHistory('Rappel programmé', 'Un rappel pour ${exam.subject} a été configuré.');
    } catch (e) {
      print('Erreur lors de la programmation de la notification: $e');
      // On ne lève pas l'exception pour ne pas bloquer l'application
    }
  }

  static Future<void> scheduleRevisionNotification(Revision revision) async {
    try {
      final timeParts = revision.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      var scheduleDate = DateTime(
        revision.date.year, 
        revision.date.month, 
        revision.date.day, 
        hour, 
        minute
      );
      
      // Si la révision est dans le passé, on ne programme rien
      if (scheduleDate.isBefore(DateTime.now())) return;
      
      final title = 'C\'est l\'heure de réviser : ${revision.subject}';
      final body = 'Votre session de révision de ${revision.duration} commence maintenant !';

      await _notificationsPlugin.zonedSchedule(
        id: revision.id.hashCode,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduleDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'revision_reminders_v2',
            'Rappels de révisions',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
          ),
          windows: WindowsNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      await _saveToHistory('Révision programmée', 'Un rappel pour ${revision.subject} a été configuré pour $hour:${minute.toString().padLeft(2, '0')}.');
    } catch (e) {
      print('Erreur lors de la programmation de la notification de révision: $e');
    }
  }

  static Future<void> cancelNotification(String id) async {
    await _notificationsPlugin.cancel(id: id.hashCode);
  }
}
