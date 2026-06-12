// Lecture Model
class Lecture {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String? pdfUrl;
  final String? videoUrl;
  final int lectureOrder;
  final DateTime createdAt;

  Lecture({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    this.pdfUrl,
    this.videoUrl,
    this.lectureOrder = 0,
    required this.createdAt,
  });

  factory Lecture.fromMap(Map<String, dynamic> data, String id) {
    return Lecture(
      id: id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pdfUrl: data['pdfUrl'],
      videoUrl: data['videoUrl'],
      lectureOrder: data['lectureOrder'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'pdfUrl': pdfUrl,
      'videoUrl': videoUrl,
      'lectureOrder': lectureOrder,
      'createdAt': createdAt,
    };
  }
}

// Question Model - প্রশ্নোত্তর ফোরামের জন্য
class Question {
  final String id;
  final String courseId;
  final String courseName;
  final String userId;
  final String userName;
  final String userRole;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final int answerCount;
  final bool isResolved;
  final bool isUrgent;
  final bool isAnonymous;
  final List<String> tags;

  Question({
    required this.id,
    required this.courseId,
    this.courseName = '',
    required this.userId,
    required this.userName,
    this.userRole = 'student',
    required this.title,
    required this.description,
    required this.createdAt,
    DateTime? lastActivityAt,
    this.answerCount = 0,
    this.isResolved = false,
    this.isUrgent = false,
    this.isAnonymous = false,
    this.tags = const [],
  }) : lastActivityAt = lastActivityAt ?? createdAt;

  factory Question.fromMap(Map<String, dynamic> data, String id) {
    return Question(
      id: id,
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: data['userRole'] ?? 'student',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastActivityAt: data['lastActivityAt']?.toDate(),
      answerCount: data['answerCount'] ?? 0,
      isResolved: data['isResolved'] ?? false,
      isUrgent: data['isUrgent'] ?? false,
      isAnonymous: data['isAnonymous'] ?? false,
      tags: (data['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'title': title,
      'description': description,
      'createdAt': createdAt,
      'lastActivityAt': lastActivityAt,
      'answerCount': answerCount,
      'isResolved': isResolved,
      'isUrgent': isUrgent,
      'isAnonymous': isAnonymous,
      'tags': tags,
    };
  }
}

// Answer Model
class Answer {
  final String id;
  final String questionId;
  final String userId;
  final String userName;
  final String userRole;
  final String content;
  final DateTime createdAt;
  final bool isAccepted;

  Answer({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.userName,
    this.userRole = 'student',
    required this.content,
    required this.createdAt,
    this.isAccepted = false,
  });

  factory Answer.fromMap(Map<String, dynamic> data, String id) {
    return Answer(
      id: id,
      questionId: data['questionId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: data['userRole'] ?? 'student',
      content: data['content'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      isAccepted: data['isAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'content': content,
      'createdAt': createdAt,
      'isAccepted': isAccepted,
    };
  }
}
