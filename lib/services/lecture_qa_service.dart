import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lecture_qa_model.dart';

// Lecture Service - লেকচার ও উপকরণ ব্যবস্থাপনা
class LectureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create lecture - শিক্ষক নতুন লেকচার তৈরি করে
  Future<String?> createLecture(Lecture lecture) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('lectures').add(lecture.toMap());

      await _firestore.collection('courses').doc(lecture.courseId).set({
        'totalLectures': FieldValue.increment(1),
      }, SetOptions(merge: true));

      return docRef.id;
    } catch (e) {
      print('Create Lecture Error: $e');
      return null;
    }
  }

  // Get lectures for a course
  Future<List<Lecture>> getLecturesByCourse(String courseId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('lectures')
          .where('courseId', isEqualTo: courseId)
          .orderBy('lectureOrder', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => Lecture.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      try {
        QuerySnapshot<Map<String, dynamic>> fallback = await _firestore
            .collection('lectures')
            .where('courseId', isEqualTo: courseId)
            .get();

        final items = fallback.docs
          .map((doc) => Lecture.fromMap(doc.data(), doc.id))
            .toList();
        items.sort((a, b) => a.lectureOrder.compareTo(b.lectureOrder));
        return items;
      } catch (e2) {
        print('Get Lectures By Course Error: $e2');
        return [];
      }
    }
  }

  // Get single lecture
  Future<Lecture?> getLectureById(String lectureId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('lectures').doc(lectureId).get();

      if (doc.exists) {
        return Lecture.fromMap(doc.data() as Map<String, dynamic>, lectureId);
      }
      return null;
    } catch (e) {
      print('Get Lecture By ID Error: $e');
      return null;
    }
  }

  // Update lecture
  Future<bool> updateLecture(String lectureId, Lecture lecture) async {
    try {
      await _firestore
          .collection('lectures')
          .doc(lectureId)
          .update(lecture.toMap());
      return true;
    } catch (e) {
      print('Update Lecture Error: $e');
      return false;
    }
  }

  // Delete lecture
  Future<bool> deleteLecture(String lectureId) async {
    try {
      final doc = await _firestore.collection('lectures').doc(lectureId).get();
      String? courseId;
      if (doc.exists && doc.data() != null) {
        courseId = doc.data()?['courseId'] as String?;
      }

      await _firestore.collection('lectures').doc(lectureId).delete();

      if (courseId != null && courseId.isNotEmpty) {
        await _firestore.collection('courses').doc(courseId).set({
          'totalLectures': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      print('Delete Lecture Error: $e');
      return false;
    }
  }
}

// Q&A Forum Service - প্রশ্নোত্তর ফোরাম ব্যবস্থাপনা
class QAService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Question>> streamQuestionsByCourse(String courseId) {
    return _firestore
        .collection('questions')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => Question.fromMap(doc.data(), doc.id))
              .toList();
          items.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
          return items;
        });
  }

  Stream<List<Answer>> streamAnswersByQuestion(String questionId) {
    return _firestore
        .collection('answers')
        .where('questionId', isEqualTo: questionId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => Answer.fromMap(doc.data(), doc.id))
              .toList();
          items.sort((a, b) {
            if (a.isAccepted != b.isAccepted) {
              return a.isAccepted ? -1 : 1;
            }
            return a.createdAt.compareTo(b.createdAt);
          });
          return items;
        });
  }

  // Post a question - প্রশ্ন জিজ্ঞাসা করা
  Future<String?> postQuestion(Question question) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('questions').add(question.toMap());
      return docRef.id;
    } catch (e) {
      print('Post Question Error: $e');
      return null;
    }
  }

  // Get questions for a course
  Future<List<Question>> getQuestionsByCourse(String courseId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('questions')
          .where('courseId', isEqualTo: courseId)
          .get();

      final items = querySnapshot.docs
          .map((doc) =>
              Question.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      print('Get Questions By Course Error: $e');
      return [];
    }
  }

  // Get single question
  Future<Question?> getQuestionById(String questionId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('questions').doc(questionId).get();

      if (doc.exists) {
        return Question.fromMap(doc.data() as Map<String, dynamic>, questionId);
      }
      return null;
    } catch (e) {
      print('Get Question By ID Error: $e');
      return null;
    }
  }

  // Post an answer
  Future<String?> postAnswer(Answer answer) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('answers').add(answer.toMap());

      // Update answer count in question
      await _firestore.collection('questions').doc(answer.questionId).update({
        'answerCount': FieldValue.increment(1),
        'lastActivityAt': DateTime.now(),
      });

      return docRef.id;
    } catch (e) {
      print('Post Answer Error: $e');
      return null;
    }
  }

  // Get answers for a question
  Future<List<Answer>> getAnswersByQuestion(String questionId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('answers')
          .where('questionId', isEqualTo: questionId)
          .get();

      final items = querySnapshot.docs
          .map((doc) =>
              Answer.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) {
        if (a.isAccepted != b.isAccepted) {
          return a.isAccepted ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return items;
    } catch (e) {
      print('Get Answers By Question Error: $e');
      return [];
    }
  }

  // Mark answer as accepted
  Future<bool> markAnswerAsAccepted(String answerId) async {
    try {
      final answerDoc = await _firestore.collection('answers').doc(answerId).get();
      if (!answerDoc.exists || answerDoc.data() == null) {
        return false;
      }

      final answerData = answerDoc.data() as Map<String, dynamic>;
      final questionId = (answerData['questionId'] as String?) ?? '';

      await _firestore.collection('answers').doc(answerId).update({'isAccepted': true});
      if (questionId.isNotEmpty) {
        await _firestore.collection('questions').doc(questionId).update({
          'isResolved': true,
          'lastActivityAt': DateTime.now(),
        });
      }
      return true;
    } catch (e) {
      print('Mark Answer As Accepted Error: $e');
      return false;
    }
  }

  Future<bool> markQuestionResolved(String questionId, {required bool resolved}) async {
    try {
      await _firestore.collection('questions').doc(questionId).update({
        'isResolved': resolved,
        'lastActivityAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('Mark Question Resolved Error: $e');
      return false;
    }
  }

  // Delete question
  Future<bool> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
      return true;
    } catch (e) {
      print('Delete Question Error: $e');
      return false;
    }
  }

  // Delete answer
  Future<bool> deleteAnswer(String answerId, String questionId) async {
    try {
      await _firestore.collection('answers').doc(answerId).delete();

      // Decrease answer count
      await _firestore.runTransaction((transaction) async {
        final questionRef = _firestore.collection('questions').doc(questionId);
        final questionDoc = await transaction.get(questionRef);

        if (!questionDoc.exists || questionDoc.data() == null) {
          return;
        }

        final data = questionDoc.data() as Map<String, dynamic>;
        final currentCount = (data['answerCount'] as int?) ?? 0;
        final nextCount = currentCount > 0 ? currentCount - 1 : 0;

        transaction.update(questionRef, {
          'answerCount': nextCount,
          'isResolved': nextCount == 0 ? false : (data['isResolved'] ?? false),
          'lastActivityAt': DateTime.now(),
        });
      });

      return true;
    } catch (e) {
      print('Delete Answer Error: $e');
      return false;
    }
  }
}
