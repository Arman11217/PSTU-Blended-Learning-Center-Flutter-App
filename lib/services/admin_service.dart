import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/faculty_department_model.dart';
import '../models/user_model.dart';

// Admin Service - সব users manage করার জন্য (শুধুমাত্র admin-দের জন্য)
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FacultyItem>> getFaculties({bool onlyActive = true}) async {
    try {
      final snapshot = await _firestore.collection('faculties').get();
      final all = snapshot.docs
          .map((doc) => FacultyItem.fromMap(doc.data(), doc.id))
          .toList();

      final filtered = onlyActive ? all.where((f) => f.isActive).toList() : all;
      final uniqueByName = <String, FacultyItem>{};
      for (final item in filtered) {
        final key = item.name.trim().toLowerCase();
        if (key.isEmpty) {
          continue;
        }
        uniqueByName.putIfAbsent(key, () => item);
      }

      final result = uniqueByName.values.toList();
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return result;
    } catch (e) {
      print('Get Faculties Error: $e');
      return [];
    }
  }

  Future<String?> createFaculty({required String name, String description = ''}) async {
    try {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        return null;
      }

      final dup = await _firestore
          .collection('faculties')
          .where('name', isEqualTo: trimmedName)
          .limit(1)
          .get();
      if (dup.docs.isNotEmpty) {
        return null;
      }

      final ref = await _firestore.collection('faculties').add({
        'name': trimmedName,
        'description': description.trim(),
        'isActive': true,
        'createdAt': DateTime.now(),
      });
      return ref.id;
    } catch (e) {
      print('Create Faculty Error: $e');
      return null;
    }
  }

  Future<bool> updateFaculty(FacultyItem faculty) async {
    try {
      await _firestore.collection('faculties').doc(faculty.id).update({
        'name': faculty.name,
        'description': faculty.description,
        'isActive': faculty.isActive,
      });
      return true;
    } catch (e) {
      print('Update Faculty Error: $e');
      return false;
    }
  }

  Future<String?> deleteFacultyWithRules(FacultyItem faculty) async {
    try {
      final departments = await _firestore
          .collection('departments')
          .where('facultyId', isEqualTo: faculty.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (departments.docs.isNotEmpty) {
        return 'Cannot delete faculty with active departments.';
      }

      final courses = await _firestore
          .collection('courses')
          .where('faculty', isEqualTo: faculty.name)
          .limit(1)
          .get();

      if (courses.docs.isNotEmpty) {
        return 'Cannot delete faculty with existing courses.';
      }

      await _firestore.collection('faculties').doc(faculty.id).delete();
      return null;
    } catch (e) {
      print('Delete Faculty Error: $e');
      return 'Failed to delete faculty.';
    }
  }

  Future<List<DepartmentItem>> getDepartments({String? facultyId, bool onlyActive = true}) async {
    try {
      final snapshot = await _firestore.collection('departments').get();
      var items = snapshot.docs
          .map((doc) => DepartmentItem.fromMap(doc.data(), doc.id))
          .toList();

      if (facultyId != null && facultyId.isNotEmpty) {
        items = items.where((d) => d.facultyId == facultyId).toList();
      }
      if (onlyActive) {
        items = items.where((d) => d.isActive).toList();
      }

      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    } catch (e) {
      print('Get Departments Error: $e');
      return [];
    }
  }

  Future<String?> createDepartment({
    required String facultyId,
    required String facultyName,
    required String name,
  }) async {
    try {
      final trimmedName = name.trim();
      if (facultyId.trim().isEmpty || trimmedName.isEmpty) {
        return null;
      }

      final dup = await _firestore
          .collection('departments')
          .where('facultyId', isEqualTo: facultyId)
          .where('name', isEqualTo: trimmedName)
          .limit(1)
          .get();

      if (dup.docs.isNotEmpty) {
        return null;
      }

      final ref = await _firestore.collection('departments').add({
        'facultyId': facultyId,
        'facultyName': facultyName,
        'name': trimmedName,
        'isActive': true,
        'createdAt': DateTime.now(),
      });
      return ref.id;
    } catch (e) {
      print('Create Department Error: $e');
      return null;
    }
  }

  Future<bool> updateDepartment(DepartmentItem department) async {
    try {
      await _firestore.collection('departments').doc(department.id).update({
        'name': department.name,
        'facultyId': department.facultyId,
        'facultyName': department.facultyName,
        'isActive': department.isActive,
      });
      return true;
    } catch (e) {
      print('Update Department Error: $e');
      return false;
    }
  }

  Future<String?> deleteDepartmentWithRules(DepartmentItem department) async {
    try {
      final courses = await _firestore
          .collection('courses')
          .where('department', isEqualTo: department.name)
          .limit(1)
          .get();

      if (courses.docs.isNotEmpty) {
        return 'Cannot delete department with existing courses.';
      }

      await _firestore.collection('departments').doc(department.id).delete();
      return null;
    } catch (e) {
      print('Delete Department Error: $e');
      return 'Failed to delete department.';
    }
  }

  Future<Map<String, int>> getSystemStatistics() async {
    try {
      final usersFuture = _firestore.collection('users').count().get();
      final coursesFuture = _firestore.collection('courses').count().get();
      final activeCoursesFuture = _firestore
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      final assignmentsFuture = _firestore.collection('assignments').count().get();
      final submissionsFuture = _firestore.collection('assignmentSubmissions').count().get();
      final questionsFuture = _firestore.collection('questions').count().get();

      final results = await Future.wait([
        usersFuture,
        coursesFuture,
        activeCoursesFuture,
        assignmentsFuture,
        submissionsFuture,
        questionsFuture,
      ]);

      return {
        'totalUsers': results[0].count ?? 0,
        'totalCourses': results[1].count ?? 0,
        'activeCourses': results[2].count ?? 0,
        'assignments': results[3].count ?? 0,
        'submissions': results[4].count ?? 0,
        'questions': results[5].count ?? 0,
      };
    } catch (e) {
      print('Get System Statistics Error: $e');
      return {
        'totalUsers': 0,
        'totalCourses': 0,
        'activeCourses': 0,
        'assignments': 0,
        'submissions': 0,
        'questions': 0,
      };
    }
  }

  Future<List<Course>> getAllCoursesForAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Get All Courses For Admin Error: $e');
      return [];
    }
  }

  Future<bool> toggleCourseStatus(String courseId, bool makeActive) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'isActive': makeActive,
      });
      return true;
    } catch (e) {
      print('Toggle Course Status Error: $e');
      return false;
    }
  }

  Future<String?> deleteCourseWithRules(String courseId) async {
    try {
      final enrolled = await _firestore
          .collection('courseEnrollments')
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (enrolled.docs.isNotEmpty) {
        return 'Cannot delete course with enrolled students.';
      }

      final assignments = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (assignments.docs.isNotEmpty) {
        return 'Cannot delete course with assignments.';
      }

      await _firestore.collection('courses').doc(courseId).delete();
      return null;
    } catch (e) {
      print('Delete Course With Rules Error: $e');
      return 'Failed to delete course.';
    }
  }

  // Get all users list
  Future<List<User>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Get All Users Error: $e');
      return [];
    }
  }

  // Get users by role (teacher, student, or admin)
  Future<List<User>> getUsersByRole(String role) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Get Users By Role Error: $e');
      return [];
    }
  }

  // Deactivate user (soft delete - শুধু isActive false করা)
  Future<bool> deactivateUser(String userId, String requesterId) async {
    try {
      // প্রথমে check করো user deactivate হতে পারবে কিনা
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        User user = User.fromMap(userDoc.data() as Map<String, dynamic>, userId);
        
        // Super admin delete করা যাবে না
        if (user.isSuperAdmin) {
          print('Cannot deactivate super_admin');
          return false;
        }

        // Update user status
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'isActive': false});
        
        return true;
      }
      return false;
    } catch (e) {
      print('Deactivate User Error: $e');
      return false;
    }
  }

  // Reactivate user
  Future<bool> reactivateUser(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isActive': true});
      return true;
    } catch (e) {
      print('Reactivate User Error: $e');
      return false;
    }
  }

  Future<bool> toggleUserStatus(String userId, {required bool makeActive}) async {
    if (makeActive) {
      return reactivateUser(userId);
    }
    return deactivateUser(userId, '');
  }

  // Update user role (শুধু admin-রা করতে পারে এবং super_admin-কে নয়)
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      // Check if user is super_admin
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        User user = User.fromMap(userDoc.data() as Map<String, dynamic>, userId);
        
        if (user.isSuperAdmin) {
          print('Cannot change role of super_admin');
          return false;
        }

        await _firestore.collection('users').doc(userId).update({
          'role': newRole,
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Update User Role Error: $e');
      return false;
    }
  }

  Future<String?> deleteUserWithRules(User user) async {
    try {
      if (user.isSuperAdmin) {
        return 'Cannot delete super admin.';
      }

      if (user.role == 'teacher') {
        final teacherAssignments = await _firestore
            .collection('assignments')
            .where('createdBy', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (teacherAssignments.docs.isNotEmpty) {
          return 'Cannot delete teacher with existing assignments.';
        }

        final teacherCourses = await _firestore
            .collection('courses')
            .where('teacherId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (teacherCourses.docs.isNotEmpty) {
          return 'Cannot delete teacher with existing courses.';
        }
      }

      if (user.role == 'student') {
        final studentSubmissions = await _firestore
            .collection('assignmentSubmissions')
            .where('studentId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (studentSubmissions.docs.isNotEmpty) {
          return 'Cannot delete student with assignment submissions.';
        }

        final enrollments = await _firestore
            .collection('courseEnrollments')
            .where('studentId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();
        if (enrollments.docs.isNotEmpty) {
          return 'Cannot delete student with active enrollments.';
        }
      }

      await _firestore.collection('users').doc(user.uid).delete();
      return null;
    } catch (e) {
      print('Delete User With Rules Error: $e');
      return 'Failed to delete user.';
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      List<User> allUsers = await getAllUsers();
      
      int totalUsers = allUsers.length;
      int adminCount = allUsers.where((u) => u.isAdmin).length;
      int teacherCount = allUsers.where((u) => u.role == 'teacher').length;
      int studentCount = allUsers.where((u) => u.role == 'student').length;
      int activeUsers = allUsers.where((u) => u.isActive).length;

      return {
        'total': totalUsers,
        'admins': adminCount,
        'teachers': teacherCount,
        'students': studentCount,
        'active': activeUsers,
      };
    } catch (e) {
      print('Get User Statistics Error: $e');
      return {};
    }
  }

  // Search users by email or name
  Future<List<User>> searchUsers(String query) async {
    try {
      List<User> allUsers = await getAllUsers();
      
      return allUsers
          .where((user) =>
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              user.fullName.toLowerCase().contains(query.toLowerCase()) ||
              user.username.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Search Users Error: $e');
      return [];
    }
  }
}
