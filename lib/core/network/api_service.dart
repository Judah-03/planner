import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
class ApiService {
  static const String serverBaseUrl = 'http://192.168.88.140:5000';
  static const String baseUrl = '$serverBaseUrl/api';
  
  static String? _token;
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString('auth_token');
    _seedInitialData();
  }

  // Seed initial data if SharedPreferences is empty so the app isn't blank
  static void _seedInitialData() {
    if (_prefs == null) return;
    
    // Seed rooms
    if (!_prefs!.containsKey('local_rooms')) {
      final defaultRooms = [
        {'id': '1', 'name': 'Room 101', 'building': 'Bâtiment A', 'is_occupied': true, 'capacity': 50},
        {'id': '2', 'name': 'Room 102', 'building': 'Bâtiment A', 'is_occupied': false, 'capacity': 60},
        {'id': '3', 'name': 'Amphi A', 'building': 'Bloc Principal', 'is_occupied': false, 'capacity': 150},
        {'id': '4', 'name': 'Amphi B', 'building': 'Bloc Principal', 'is_occupied': false, 'capacity': 120},
      ];
      _prefs!.setString('local_rooms', jsonEncode(defaultRooms));
    }

    // Seed exams
    if (!_prefs!.containsKey('local_exams')) {
      final now = DateTime.now();
      final defaultExams = [
        {
          'id': 'e1',
          'subject': 'Algorithmique',
          'exam_date': now.add(const Duration(days: 1)).toIso8601String(),
          'exam_time': '09:00',
          'room': 'Room 101',
          'teacher': 'Dr. Ramanantsoa',
          'duration': '2 heures',
          'level': 'L3',
        },
        {
          'id': 'e2',
          'subject': 'Bases de Données',
          'exam_date': now.add(const Duration(days: 3)).toIso8601String(),
          'exam_time': '14:00',
          'room': 'Amphi A',
          'teacher': 'Mme. Rabe',
          'duration': '3 heures',
          'level': 'L3',
        }
      ];
      _prefs!.setString('local_exams', jsonEncode(defaultExams));
    }
  }

  // --- Auth ---
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    _token = 'mock_token_pro_mode';
    await _prefs?.setString('auth_token', _token!);
    
    if (_prefs != null && !_prefs!.containsKey('local_user')) {
      final user = {
        'id': 'u1',
        'student_id': '12345',
        'email': identifier.contains('@') ? identifier : 'test@emit.mg',
        'full_name': 'Étudiant Pro',
        'branch': 'Informatique',
        'level': 'L3',
        'profile_image': '',
      };
      await _prefs!.setString('local_user', jsonEncode(user));
    }

    final userJson = _prefs?.getString('local_user');
    final userMap = userJson != null ? jsonDecode(userJson) : {};

    return {
      'token': _token,
      'user': userMap,
    };
  }

  static Future<void> sendCode(String email) async {
    return; // Success instantly
  }

  static Future<void> verifyCode(String email, String code) async {
    return; // Success instantly
  }

  static Future<void> register(Map<String, dynamic> userData) async {
    if (_prefs != null) {
      final user = {
        'id': const Uuid().v4(),
        'student_id': userData['student_id'] ?? '12345',
        'email': userData['email'] ?? 'test@emit.mg',
        'full_name': userData['full_name'] ?? 'Étudiant Pro',
        'branch': userData['branch'] ?? 'Informatique',
        'level': userData['level'] ?? 'L3',
        'profile_image': '',
      };
      await _prefs!.setString('local_user', jsonEncode(user));
    }
  }

  // --- Exams ---
  static Future<List<dynamic>> getExams() async {
    final jsonStr = _prefs?.getString('local_exams') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);
    return list;
  }

  static Future<void> createExam(Map<String, dynamic> examData) async {
    final jsonStr = _prefs?.getString('local_exams') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);
    
    final newExam = Map<String, dynamic>.from(examData);
    newExam['id'] = const Uuid().v4();
    list.add(newExam);
    
    await _prefs?.setString('local_exams', jsonEncode(list));
  }

  static Future<void> updateExam(String id, Map<String, dynamic> examData) async {
    final jsonStr = _prefs?.getString('local_exams') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);
    
    final index = list.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(examData);
      updated['id'] = id;
      list[index] = updated;
      await _prefs?.setString('local_exams', jsonEncode(list));
    }
  }

  static Future<void> deleteExam(String id) async {
    final jsonStr = _prefs?.getString('local_exams') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);
    
    list.removeWhere((e) => e['id'] == id);
    await _prefs?.setString('local_exams', jsonEncode(list));
  }

  // --- Rooms ---
  static Future<List<dynamic>> getRooms() async {
    final jsonStr = _prefs?.getString('local_rooms') ?? '[]';
    final List<dynamic> rooms = jsonDecode(jsonStr);
    final examsStr = _prefs?.getString('local_exams') ?? '[]';
    final List<dynamic> exams = jsonDecode(examsStr);

    // Calculate next_exam and next_time dynamically
    return rooms.map((r) {
      final roomMap = Map<String, dynamic>.from(r);
      final roomName = roomMap['name'];
      
      final roomExams = exams.where((e) {
        if (e['room'] != roomName) return false;
        final date = DateTime.tryParse(e['exam_date'] ?? '');
        if (date == null) return false;
        return date.isAfter(DateTime.now().subtract(const Duration(hours: 12)));
      }).toList();

      if (roomExams.isNotEmpty) {
        roomExams.sort((a, b) => (a['exam_date'] ?? '').compareTo(b['exam_date'] ?? ''));
        roomMap['next_exam'] = roomExams.first['subject'];
        roomMap['next_time'] = roomExams.first['exam_time'];
      } else {
        roomMap['next_exam'] = null;
        roomMap['next_time'] = null;
      }
      return roomMap;
    }).toList();
  }

  static Future<void> createRoom(Map<String, dynamic> roomData) async {
    final jsonStr = _prefs?.getString('local_rooms') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);

    final name = roomData['name'];
    if (list.any((r) => r['name'].toString().toLowerCase() == name.toString().toLowerCase())) {
      throw Exception('Une salle avec ce nom existe déjà.');
    }

    final newRoom = Map<String, dynamic>.from(roomData);
    newRoom['id'] = const Uuid().v4();
    list.add(newRoom);

    await _prefs?.setString('local_rooms', jsonEncode(list));
  }

  static Future<void> updateRoomOccupancy(String id, bool isOccupied) async {
    final jsonStr = _prefs?.getString('local_rooms') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);

    final index = list.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      final room = Map<String, dynamic>.from(list[index]);
      room['is_occupied'] = isOccupied;
      list[index] = room;
      await _prefs?.setString('local_rooms', jsonEncode(list));
    }
  }

  static Future<void> updateRoom(String id, Map<String, dynamic> roomData) async {
    final jsonStr = _prefs?.getString('local_rooms') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);
    
    final index = list.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(list[index]);
      updated['name'] = roomData['name'] ?? updated['name'];
      updated['building'] = roomData['building'] ?? updated['building'];
      updated['capacity'] = roomData['capacity'] ?? updated['capacity'];
      list[index] = updated;
      await _prefs?.setString('local_rooms', jsonEncode(list));
    }
  }

  static Future<void> deleteRoom(String id) async {
    final jsonStr = _prefs?.getString('local_rooms') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);
    
    list.removeWhere((r) => r['id'] == id);
    await _prefs?.setString('local_rooms', jsonEncode(list));
  }

  // --- Results ---
  static Future<List<dynamic>> getResults() async {
    final jsonStr = _prefs?.getString('local_results') ?? '[]';
    return jsonDecode(jsonStr);
  }

  static Future<void> createResult(Map<String, dynamic> resultData) async {
    final jsonStr = _prefs?.getString('local_results') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);

    final newResult = Map<String, dynamic>.from(resultData);
    newResult['id'] = const Uuid().v4();
    newResult['created_at'] = DateTime.now().toIso8601String();
    list.add(newResult);

    await _prefs?.setString('local_results', jsonEncode(list));
  }

  static Future<void> deleteResult(String id) async {
    final jsonStr = _prefs?.getString('local_results') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);

    list.removeWhere((r) => r['id'] == id);
    await _prefs?.setString('local_results', jsonEncode(list));
  }

  // --- Logout ---
  static Future<void> logout() async {
    _token = null;
    await _prefs?.remove('auth_token');
  }

  // --- Profile ---
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    if (_prefs != null) {
      final jsonStr = _prefs!.getString('local_user') ?? '{}';
      final user = Map<String, dynamic>.from(jsonDecode(jsonStr));
      
      user['full_name'] = userData['full_name'] ?? user['full_name'];
      user['branch'] = userData['branch'] ?? user['branch'];
      user['level'] = userData['level'] ?? user['level'];
      
      await _prefs!.setString('local_user', jsonEncode(user));
      return user;
    }
    return {};
  }

  static Future<String> uploadProfileImage(String filePath) async {
    if (_prefs != null) {
      final jsonStr = _prefs!.getString('local_user') ?? '{}';
      final user = Map<String, dynamic>.from(jsonDecode(jsonStr));
      user['profile_image'] = filePath;
      await _prefs!.setString('local_user', jsonEncode(user));
    }
    return filePath;
  }

  // --- Focus ---
  static Future<Map<String, dynamic>> getFocusStats() async {
    final jsonStr = _prefs?.getString('local_focus') ?? '[]';
    final List<dynamic> sessions = jsonDecode(jsonStr);

    int totalMinutes = 0;
    int sessionsCount = 0;
    
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    int todayMinutes = 0;
    
    // Pour calculer le streak
    Set<String> activeDays = {};

    for (final s in sessions) {
      final duration = s['duration_minutes'] as int;
      totalMinutes += duration;
      sessionsCount++;
      
      final createdAtStr = s['created_at'] as String;
      if (createdAtStr.startsWith(todayStr)) {
        todayMinutes += duration;
      }
      
      final dateOnly = createdAtStr.split('T')[0];
      activeDays.add(dateOnly);
    }

    // Calcul du streak
    int currentStreak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    
    // Si l'utilisateur n'a pas encore étudié aujourd'hui, vérifier s'il a étudié hier
    String checkStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
    if (!activeDays.contains(checkStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      checkStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
    }

    while (activeDays.contains(checkStr)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      checkStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
    }

    return {
      'total_minutes': totalMinutes,
      'sessions_count': sessionsCount,
      'today_minutes': todayMinutes,
      'current_streak': currentStreak,
    };
  }

  static Future<void> createFocusSession(int durationMinutes, String type) async {
    final jsonStr = _prefs?.getString('local_focus') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);

    final newSession = {
      'id': const Uuid().v4(),
      'duration_minutes': durationMinutes,
      'session_type': type,
      'created_at': DateTime.now().toIso8601String(),
    };
    list.add(newSession);

    await _prefs?.setString('local_focus', jsonEncode(list));
  }

  // --- Mail ---
  static Future<void> sendEmail({required String to, required String subject, required String message}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mail/send'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'message': message,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur serveur lors de l\'envoi du mail (Code ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Impossible de contacter le serveur pour l\'envoi du mail: $e');
    }
  }
}
