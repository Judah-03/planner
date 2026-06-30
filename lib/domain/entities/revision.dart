class Revision {
  final String id;
  final String subject;
  final DateTime date;
  final String time;
  final String duration;
  final String notes;
  final String status;

  const Revision({
    required this.id,
    required this.subject,
    required this.date,
    required this.time,
    required this.duration,
    required this.notes,
    this.status = 'A faire',
  });

  Revision copyWith({
    String? id,
    String? subject,
    DateTime? date,
    String? time,
    String? duration,
    String? notes,
    String? status,
  }) {
    return Revision(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'date': date.toIso8601String(),
      'time': time,
      'duration': duration,
      'notes': notes,
      'status': status,
    };
  }

  factory Revision.fromJson(Map<String, dynamic> map) {
    return Revision(
      id: map['id'] as String,
      subject: map['subject'] as String,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String,
      duration: map['duration'] as String,
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? 'A faire',
    );
  }
}
