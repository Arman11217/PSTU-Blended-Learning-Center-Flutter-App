class McqQuestion {
  final String id;
  final String courseId;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String difficulty; // easy, medium, hard
  final List<String> tags;
  final String createdBy;
  final DateTime createdAt;
  final int usedInExamCount;
  final bool isArchived;

  McqQuestion({
    required this.id,
    required this.courseId,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    this.tags = const [],
    required this.createdBy,
    required this.createdAt,
    this.usedInExamCount = 0,
    this.isArchived = false,
  });

  factory McqQuestion.fromMap(Map<String, dynamic> data, String id) {
    return McqQuestion(
      id: id,
      courseId: data['courseId'] ?? '',
      questionText: data['questionText'] ?? '',
      options: (data['options'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      correctIndex: data['correctIndex'] ?? 0,
      difficulty: data['difficulty'] ?? 'medium',
      tags: (data['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      usedInExamCount: data['usedInExamCount'] ?? 0,
      isArchived: data['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'questionText': questionText,
      'options': options,
      'correctIndex': correctIndex,
      'difficulty': difficulty,
      'tags': tags,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'usedInExamCount': usedInExamCount,
      'isArchived': isArchived,
    };
  }
}

class McqExam {
  final String id;
  final String courseId;
  final String title;
  final List<String> questionIds;
  final int durationMinutes;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  McqExam({
    required this.id,
    required this.courseId,
    required this.title,
    required this.questionIds,
    required this.durationMinutes,
    required this.startAt,
    required this.endAt,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
  });

  factory McqExam.fromMap(Map<String, dynamic> data, String id) {
    return McqExam(
      id: id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      questionIds: (data['questionIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      durationMinutes: data['durationMinutes'] ?? 60,
      startAt: data['startAt']?.toDate() ?? DateTime.now(),
      endAt: data['endAt']?.toDate() ?? DateTime.now().add(const Duration(hours: 2)),
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'questionIds': questionIds,
      'durationMinutes': durationMinutes,
      'startAt': startAt,
      'endAt': endAt,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}

class McqExamAttempt {
  final String id;
  final String examId;
  final String courseId;
  final String studentId;
  final Map<String, int> answers;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final DateTime startedAt;
  final DateTime submittedAt;

  McqExamAttempt({
    required this.id,
    required this.examId,
    required this.courseId,
    required this.studentId,
    required this.answers,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.startedAt,
    required this.submittedAt,
  });

  factory McqExamAttempt.fromMap(Map<String, dynamic> data, String id) {
    return McqExamAttempt(
      id: id,
      examId: data['examId'] ?? '',
      courseId: data['courseId'] ?? '',
      studentId: data['studentId'] ?? '',
      answers: (data['answers'] as Map<String, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key, (value as num).toInt())),
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      scorePercent: (data['scorePercent'] as num?)?.toDouble() ?? 0,
      startedAt: data['startedAt']?.toDate() ?? DateTime.now(),
      submittedAt: data['submittedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'courseId': courseId,
      'studentId': studentId,
      'answers': answers,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'scorePercent': scorePercent,
      'startedAt': startedAt,
      'submittedAt': submittedAt,
    };
  }
}
