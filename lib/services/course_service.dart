import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

// Course Service - কোর্স সম্পর্কিত সব অপারেশন
class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Course>> streamTeacherCourses(String teacherId) {
    return _firestore
        .collection('courses')
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) {
            final items = snapshot.docs
              .map((doc) => Course.fromMap(doc.data(), doc.id))
              .toList();
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return items;
          },
        );
  }

  // Get all courses
  Future<List<Course>> getAllCourses() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .get();

      final items = querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      print('Get All Courses Error: $e');
      return [];
    }
  }

  // Get courses by teacher ID
  Future<List<Course>> getTeacherCourses(String teacherId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('courses')
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .get();

      final items = querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      print('Get Teacher Courses Error: $e');
      return [];
    }
  }

  // Get single course details
  Future<Course?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('courses').doc(courseId).get();

      if (doc.exists) {
        return Course.fromMap(doc.data() as Map<String, dynamic>, courseId);
      }
      return null;
    } catch (e) {
      print('Get Course By ID Error: $e');
      return null;
    }
  }

  // Create new course - শিক্ষক নতুন কোর্স তৈরি করতে পারে
  Future<String?> createCourse(Course course) async {
    try {
      DocumentReference docRef = await _firestore.collection('courses').add(course.toMap());
      return docRef.id;
    } catch (e) {
      print('Create Course Error: $e');
      return null;
    }
  }

  // Update course
  Future<bool> updateCourse(String courseId, Course course) async {
    try {
      await _firestore.collection('courses').doc(courseId).update(course.toMap());
      return true;
    } catch (e) {
      print('Update Course Error: $e');
      return false;
    }
  }

  // Delete course (soft delete - শুধু isActive false করা)
  Future<bool> deleteCourse(String courseId) async {
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .update({'isActive': false});
      return true;
    } catch (e) {
      print('Delete Course Error: $e');
      return false;
    }
  }

  // Get courses by department
  Future<List<Course>> getCoursesByDepartment(String department) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('courses')
          .where('department', isEqualTo: department)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Get Courses By Department Error: $e');
      return [];
    }
  }

  // Enroll student in course - শিক্ষার্থী কোর্সে নিবন্ধন করা
  Future<bool> enrollStudentInCourse(String courseId, String studentId) async {
    try {
      await _firestore
          .collection('courseEnrollments')
          .doc('${courseId}_$studentId')
          .set({
        'courseId': courseId,
        'studentId': studentId,
        'enrolledAt': DateTime.now(),
        'status': 'active',
      });
      return true;
    } catch (e) {
      print('Enroll Student Error: $e');
      return false;
    }
  }

  // Check if student is enrolled in course
  Future<bool> isStudentEnrolled(String courseId, String studentId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('courseEnrollments')
          .doc('${courseId}_$studentId')
          .get();

      return doc.exists;
    } catch (e) {
      print('Check Enrollment Error: $e');
      return false;
    }
  }

  // Get enrolled courses for student
  Future<List<Course>> getEnrolledCourses(String studentId) async {
    try {
      QuerySnapshot enrollmentDocs = await _firestore
          .collection('courseEnrollments')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'active')
          .get();

      List<Course> enrolledCourses = [];

      for (var doc in enrollmentDocs.docs) {
        String courseId = doc['courseId'];
        Course? course = await getCourseById(courseId);
        if (course != null) {
          enrolledCourses.add(course);
        }
      }

      return enrolledCourses;
    } catch (e) {
      print('Get Enrolled Courses Error: $e');
      return [];
    }
  }
}
