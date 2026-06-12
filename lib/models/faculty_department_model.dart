class FacultyItem {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  FacultyItem({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
  });

  factory FacultyItem.fromMap(Map<String, dynamic> data, String id) {
    return FacultyItem(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

class DepartmentItem {
  final String id;
  final String facultyId;
  final String facultyName;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  DepartmentItem({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.name,
    this.isActive = true,
    required this.createdAt,
  });

  factory DepartmentItem.fromMap(Map<String, dynamic> data, String id) {
    return DepartmentItem(
      id: id,
      facultyId: data['facultyId'] ?? '',
      facultyName: data['facultyName'] ?? '',
      name: data['name'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facultyId': facultyId,
      'facultyName': facultyName,
      'name': name,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
