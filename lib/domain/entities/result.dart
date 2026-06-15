class ExamResult {
  final String id;
  final String subject;
  final double grade;
  final int? credits;
  final String? semester;

  ExamResult({
    required this.id,
    required this.subject,
    required this.grade,
    this.credits,
    this.semester,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      id: json['id'],
      subject: json['subject'],
      grade: double.tryParse(json['grade'].toString()) ?? 0.0,
      credits: json['credits'],
      semester: json['semester'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'grade': grade,
      'credits': credits,
      'semester': semester,
    };
  }
}
