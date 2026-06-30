import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserData {
  final String id;
  final String fullName;
  final String email;
  final String studentId;
  final String level;
  final String? profileImage;

  UserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.level,
    this.profileImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      studentId: (json['student_id'] as String?) ?? '',
      level: (json['level'] as String?) ?? '',
      profileImage: json['profile_image'] as String?,
    );
  }
}

final userProvider = StateProvider<UserData?>((ref) => null);
