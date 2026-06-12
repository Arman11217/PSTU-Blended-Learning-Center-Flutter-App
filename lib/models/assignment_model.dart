// Assignment Model
class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String category;
  final int totalPoints;
  final String description;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool isDraft;
  final DateTime dueDate;
  final DateTime createdAt;
  final String createdBy; // Teacher ID

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    this.category = 'General',
    this.totalPoints = 100,
    required this.description,
    this.attachmentUrl,
    this.attachmentName,
    this.isDraft = false,
    required this.dueDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory Assignment.fromMap(Map<String, dynamic> data, String id) {
    return Assignment(
      id: id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? 'General',
      totalPoints: data['totalPoints'] ?? 100,
      description: data['description'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      attachmentName: data['attachmentName'],
      isDraft: data['isDraft'] ?? false,
      dueDate: data['dueDate']?.toDate() ?? DateTime.now(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'category': category,
      'totalPoints': totalPoints,
      'description': description,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'isDraft': isDraft,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}

// Assignment Submission Model - শিক্ষার্থী যখন অ্যাসাইনমেন্ট জমা দেয়
class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String fileUrl;
  final DateTime submittedAt;
  final String? marks;
  final String? feedback;
  final bool isEvaluated;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.fileUrl,
    required this.submittedAt,
    this.marks,
    this.feedback,
    this.isEvaluated = false,
  });

  factory AssignmentSubmission.fromMap(Map<String, dynamic> data, String id) {
    return AssignmentSubmission(
      id: id,
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      submittedAt: data['submittedAt']?.toDate() ?? DateTime.now(),
      marks: data['marks'],
      feedback: data['feedback'],
      isEvaluated: data['isEvaluated'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'fileUrl': fileUrl,
      'submittedAt': submittedAt,
      'marks': marks,
      'feedback': feedback,
      'isEvaluated': isEvaluated,
    };
  }
}
