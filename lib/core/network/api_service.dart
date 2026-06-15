import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Utilisez '10.0.2.2' pour l'émulateur Android, ou votre IP locale pour un vrai appareil
  static const String serverBaseUrl = 'http://localhost:5000';
  static const String baseUrl = '$serverBaseUrl/api'; 
  
  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id_or_email': identifier,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur de connexion');
    }
  }

  static Future<void> sendCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Erreur lors de l\'envoi du code');
    }
  }

  static Future<void> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Code invalide');
    }
  }

  static Future<void> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Erreur lors de l\'inscription');
    }
  }

  static Future<List<dynamic>> getExams() async {
    final response = await http.get(
      Uri.parse('$baseUrl/exams'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des examens');
    }
  }

  static Future<void> createExam(Map<String, dynamic> examData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exams'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(examData),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de la création de l\'examen');
    }
  }

  static Future<void> updateExam(String id, Map<String, dynamic> examData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/exams/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(examData),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour de l\'examen');
    }
  }

  static Future<void> deleteExam(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/exams/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'examen');
    }
  }

  static Future<List<dynamic>> getRooms() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rooms'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des salles');
    }
  }

  static Future<void> updateRoomOccupancy(String id, bool isOccupied) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/rooms/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'is_occupied': isOccupied}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour de l\'occupation');
    }
  }

  static Future<List<dynamic>> getResults() async {
    final response = await http.get(
      Uri.parse('$baseUrl/results'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des résultats');
    }
  }

  static Future<void> createResult(Map<String, dynamic> resultData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/results'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(resultData),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de l\'ajout du résultat');
    }
  }

  static Future<void> deleteResult(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/results/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du résultat');
    }
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(userData),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['user'];
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la mise à jour');
    }
  }

  static Future<String> uploadProfileImage(String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/upload-image'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['imageUrl'];
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de l\'upload');
    }
  }

  // --- Focus Endpoints ---

  static Future<Map<String, dynamic>> getFocusStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/focus/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des statistiques');
    }
  }

  static Future<void> createFocusSession(int durationMinutes, String type) async {
    final response = await http.post(
      Uri.parse('$baseUrl/focus'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'duration_minutes': durationMinutes,
        'session_type': type,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de l\'enregistrement de la session');
    }
  }
}
