class Exam {
  final String id;
  final String subject;
  final DateTime date;
  final String time;
  final String room;
  final String teacher;
  final String duration;
  final String level;

  const Exam({
    required this.id,
    required this.subject,
    required this.date,
    required this.time,
    required this.room,
    required this.teacher,
    required this.duration,
    required this.level,
  });

  Exam copyWith({
    String? id,
    String? subject,
    DateTime? date,
    String? time,
    String? room,
    String? teacher,
    String? duration,
    String? level,
  }) {
    return Exam(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      time: time ?? this.time,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      duration: duration ?? this.duration,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'exam_date': date.toIso8601String(),
      'exam_time': time,
      'room': room,
      'teacher': teacher,
      'duration': duration,
      'level': level,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as String,
      subject: map['subject'] as String,
      date: DateTime.parse(map['exam_date'] as String),
      time: (map['exam_time'] as String?) ?? (map['time'] as String?) ?? '',
      room: (map['room'] as String?) ?? '',
      teacher: (map['teacher'] as String?) ?? '',
      duration: (map['duration'] as String?) ?? '',
      level: (map['level'] as String?) ?? '',
    );
  }
}
