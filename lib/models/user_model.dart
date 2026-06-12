// User Model - সকল ইউজারের জন্য (Super Admin, Admin, Teacher, Student)
class User {
  final String uid;
  final String email;
  final String fullName;
  final String username;
  final String role; // 'super_admin', 'admin', 'teacher', 'student'
  final String? facultyId;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.username,
    required this.role,
    this.facultyId,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  // Check if user is super admin (cannot be deleted)
  bool get isSuperAdmin => role == 'super_admin';

  // Check if user is any type of admin
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  // Firestore ডাটা থেকে User অবজেক্ট তৈরি করা
  factory User.fromMap(Map<String, dynamic> data, String uid) {
    return User(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      username: data['username'] ?? '',
      role: data['role'] ?? 'student',
      facultyId: data['facultyId'],
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  // User অবজেক্টকে Map-এ রূপান্তরিত করা (Firestore সেভের জন্য)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'username': username,
      'role': role,
      'facultyId': facultyId,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
