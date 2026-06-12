import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';

// Assignment Service - অ্যাসাইনমেন্ট সম্পর্কিত সব অপারেশন
class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create assignment - শিক্ষক নতুন অ্যাসাইনমেন্ট তৈরি করে
  Future<String?> createAssignment(Assignment assignment) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('assignments').add(assignment.toMap());

      // Keep cached course counters in sync for dashboard cards.
      await _firestore.collection('courses').doc(assignment.courseId).set({
        'totalAssignments': FieldValue.increment(1),
      }, SetOptions(merge: true));

      return docRef.id;
    } catch (e) {
      print('Create Assignment Error: $e');
      return null;
    }
  }

  Future<int> getAssignmentsCountByCourse(String courseId) async {
    try {
      final aggregate = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .count()
          .get();
      return aggregate.count ?? 0;
    } catch (e) {
      print('Get Assignments Count By Course Error: $e');
      return 0;
    }
  }

  // Get assignments for a course
  Future<List<Assignment>> getAssignmentsByCourse(String courseId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      final items = querySnapshot.docs
          .map((doc) =>
              Assignment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return items;
    } catch (e) {
      print('Get Assignments By Course Error: $e');
      return [];
    }
  }

  // Get single assignment details
  Future<Assignment?> getAssignmentById(String assignmentId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('assignments').doc(assignmentId).get();

      if (doc.exists) {
        return Assignment.fromMap(doc.data() as Map<String, dynamic>, assignmentId);
      }
      return null;
    } catch (e) {
      print('Get Assignment By ID Error: $e');
      return null;
    }
  }

  // Update assignment
  Future<bool> updateAssignment(String assignmentId, Assignment assignment) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update(assignment.toMap());
      return true;
    } catch (e) {
      print('Update Assignment Error: $e');
      return false;
    }
  }

  // Delete assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      final doc = await _firestore.collection('assignments').doc(assignmentId).get();
      String? courseId;
      if (doc.exists && doc.data() != null) {
        courseId = (doc.data() as Map<String, dynamic>)['courseId'] as String?;
      }

      await _firestore.collection('assignments').doc(assignmentId).delete();

      if (courseId != null && courseId.isNotEmpty) {
        await _firestore.collection('courses').doc(courseId).set({
          'totalAssignments': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      print('Delete Assignment Error: $e');
      return false;
    }
  }

  // Submit assignment - শিক্ষার্থী অ্যাসাইনমেন্ট জমা দেয়
  Future<String?> submitAssignment(
      AssignmentSubmission submission) async {
    try {
      final docId = '${submission.assignmentId}_${submission.studentId}';
      await _firestore
          .collection('assignmentSubmissions')
          .doc(docId)
          .set({
        ...submission.toMap(),
        'marks': null,
        'feedback': null,
        'isEvaluated': false,
      }, SetOptions(merge: true));
      return docId;
    } catch (e) {
      print('Submit Assignment Error: $e');
      return null;
    }
  }

  // Get submissions for an assignment
  Future<List<AssignmentSubmission>> getSubmissionsByAssignment(
      String assignmentId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final items = querySnapshot.docs
          .map((doc) => AssignmentSubmission.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return items;
    } catch (e) {
      print('Get Submissions By Assignment Error: $e');
      return [];
    }
  }

  // Get submission by student
  Future<AssignmentSubmission?> getStudentSubmission(
      String assignmentId, String studentId) async {
    try {
      final directDocId = '${assignmentId}_$studentId';
      final directDoc = await _firestore
          .collection('assignmentSubmissions')
          .doc(directDocId)
          .get();

      if (directDoc.exists && directDoc.data() != null) {
        return AssignmentSubmission.fromMap(
          directDoc.data() as Map<String, dynamic>,
          directDoc.id,
        );
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final items = querySnapshot.docs
            .map((doc) => AssignmentSubmission.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
        items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        return items.first;
      }
      return null;
    } catch (e) {
      print('Get Student Submission Error: $e');
      return null;
    }
  }

  // Evaluate submission - শিক্ষক মার্ক দেয়
  Future<bool> evaluateSubmission(String submissionId, String marks,
      String feedback) async {
    try {
      await _firestore
          .collection('assignmentSubmissions')
          .doc(submissionId)
          .update({
        'marks': marks,
        'feedback': feedback,
        'isEvaluated': true,
      });
      return true;
    } catch (e) {
      print('Evaluate Submission Error: $e');
      return false;
    }
  }

  // Get submissions for a student
  Future<List<AssignmentSubmission>> getStudentSubmissions(
      String studentId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('studentId', isEqualTo: studentId)
          .get();

      final items = querySnapshot.docs
          .map((doc) => AssignmentSubmission.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return items;
    } catch (e) {
      print('Get Student Submissions Error: $e');
      return [];
    }
  }
}
