// Course Model - কোর্স সম্পর্কে তথ্য
class Course {
  final String id;
  final String name;
  final String code;
  final String description;
  final String teacherId;
  final String faculty;
  final String department;
  final bool isPublic;
  final String? syllabusUrl;
  final String? bannerImageUrl;
  final List<String> learningObjectives;
  final int totalLectures;
  final int totalAssignments;
  final DateTime createdAt;
  final bool isActive;

  Course({
    required this.id,
    required this.name,
    this.code = '',
    required this.description,
    required this.teacherId,
    this.faculty = '',
    required this.department,
    this.isPublic = true,
    this.syllabusUrl,
    this.bannerImageUrl,
    this.learningObjectives = const [],
    this.totalLectures = 0,
    this.totalAssignments = 0,
    required this.createdAt,
    this.isActive = true,
  });

  factory Course.fromMap(Map<String, dynamic> data, String id) {
    return Course(
      id: id,
      name: data['name'] ?? '',
        code: data['code'] ?? '',
      description: data['description'] ?? '',
      teacherId: data['teacherId'] ?? '',
        faculty: data['faculty'] ?? '',
      department: data['department'] ?? '',
        isPublic: data['isPublic'] ?? true,
        syllabusUrl: data['syllabusUrl'],
        bannerImageUrl: data['bannerImageUrl'],
        learningObjectives:
          (data['learningObjectives'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      totalLectures: data['totalLectures'] ?? 0,
      totalAssignments: data['totalAssignments'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'teacherId': teacherId,
      'faculty': faculty,
      'department': department,
      'isPublic': isPublic,
      'syllabusUrl': syllabusUrl,
      'bannerImageUrl': bannerImageUrl,
      'learningObjectives': learningObjectives,
      'totalLectures': totalLectures,
      'totalAssignments': totalAssignments,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
