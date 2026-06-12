import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course_model.dart';
import '../models/exam_system_model.dart';
import 'course_service.dart';

class ExamSystemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CourseService _courseService = CourseService();
  String? _lastError;

  String? get lastError => _lastError;

  Future<List<McqQuestion>> getQuestionsByCourse(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('mcqQuestions')
          .where('courseId', isEqualTo: courseId)
          .get();

      final items = snapshot.docs
          .map((doc) => McqQuestion.fromMap(doc.data(), doc.id))
          .where((q) => !q.isArchived)
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<String?> createQuestion(McqQuestion question) async {
    try {
      final ref = await _firestore.collection('mcqQuestions').add(question.toMap());
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateQuestion(String questionId, McqQuestion question) async {
    try {
      await _firestore.collection('mcqQuestions').doc(questionId).update(question.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> archiveQuestion(String questionId) async {
    try {
      await _firestore.collection('mcqQuestions').doc(questionId).update({'isArchived': true});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> duplicateQuestion(McqQuestion question) async {
    final clone = McqQuestion(
      id: '',
      courseId: question.courseId,
      questionText: question.questionText,
      options: List<String>.from(question.options),
      correctIndex: question.correctIndex,
      difficulty: question.difficulty,
      tags: List<String>.from(question.tags),
      createdBy: question.createdBy,
      createdAt: DateTime.now(),
    );

    return createQuestion(clone);
  }

  Future<String?> createExamFromQuestionBank({
    required String courseId,
    required String title,
    required int questionCount,
    required int durationMinutes,
    required DateTime startAt,
    required DateTime endAt,
    required String createdBy,
    String? tagFilter,
  }) async {
    _lastError = null;
    try {
      var questions = await getQuestionsByCourse(courseId);

      if (tagFilter != null && tagFilter.trim().isNotEmpty) {
        final tag = tagFilter.toLowerCase();
        questions = questions
            .where((q) => q.tags.any((t) => t.toLowerCase().contains(tag)))
            .toList();
      }

      if (questions.length < questionCount || questionCount <= 0) {
        _lastError = 'Not enough questions in question bank for the selected count/filter.';
        return null;
      }

      questions.shuffle(Random());
      final selected = questions.take(questionCount).toList();
      final questionIds = selected.map((q) => q.id).toList();

      final exam = McqExam(
        id: '',
        courseId: courseId,
        title: title,
        questionIds: questionIds,
        durationMinutes: durationMinutes,
        startAt: startAt,
        endAt: endAt,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final ref = await _firestore.collection('mcqExams').add(exam.toMap());

      final batch = _firestore.batch();
      for (final q in selected) {
        final qRef = _firestore.collection('mcqQuestions').doc(q.id);
        batch.update(qRef, {'usedInExamCount': FieldValue.increment(1)});
      }
      await batch.commit();

      return ref.id;
    } catch (e) {
      _lastError = 'Exam creation failed: $e';
      return null;
    }
  }

  Future<String?> createExamFromSelectedQuestions({
    required String courseId,
    required String title,
    required List<String> questionIds,
    required int durationMinutes,
    required DateTime startAt,
    required DateTime endAt,
    required String createdBy,
  }) async {
    _lastError = null;
    try {
      if (questionIds.isEmpty) {
        _lastError = 'Please select at least one question.';
        return null;
      }

      final exam = McqExam(
        id: '',
        courseId: courseId,
        title: title,
        questionIds: questionIds,
        durationMinutes: durationMinutes,
        startAt: startAt,
        endAt: endAt,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final ref = await _firestore.collection('mcqExams').add(exam.toMap());

      final batch = _firestore.batch();
      for (final id in questionIds) {
        final qRef = _firestore.collection('mcqQuestions').doc(id);
        batch.update(qRef, {'usedInExamCount': FieldValue.increment(1)});
      }
      await batch.commit();

      return ref.id;
    } catch (e) {
      _lastError = 'Exam creation failed: $e';
      return null;
    }
  }

  Future<List<McqExam>> getTeacherExams(String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection('mcqExams')
          .where('createdBy', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .orderBy('startAt', descending: false)
          .get();

      return snapshot.docs.map((d) => McqExam.fromMap(d.data(), d.id)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<McqExam>> getStudentUpcomingExams(String studentId) async {
    try {
      final enrolledCourses = await _courseService.getEnrolledCourses(studentId);
      final courseIds = enrolledCourses.map((c) => c.id).toList();
      if (courseIds.isEmpty) {
        return [];
      }

      final exams = <McqExam>[];
      for (final chunk in _chunk(courseIds, 10)) {
        final snapshot = await _firestore
            .collection('mcqExams')
            .where('courseId', whereIn: chunk)
            .where('isActive', isEqualTo: true)
            .get();

        exams.addAll(snapshot.docs.map((d) => McqExam.fromMap(d.data(), d.id)));
      }

      exams.sort((a, b) => a.startAt.compareTo(b.startAt));
      return exams;
    } catch (_) {
      return [];
    }
  }

  Future<List<McqExam>> getStudentExamsByCourse(String studentId, String courseId) async {
    try {
      final isEnrolled = await _courseService.isStudentEnrolled(courseId, studentId);
      if (!isEnrolled) {
        return [];
      }

      final snapshot = await _firestore
          .collection('mcqExams')
          .where('courseId', isEqualTo: courseId)
          .where('isActive', isEqualTo: true)
          .get();

      final exams = snapshot.docs.map((d) => McqExam.fromMap(d.data(), d.id)).toList();
      exams.sort((a, b) => a.startAt.compareTo(b.startAt));
      return exams;
    } catch (_) {
      return [];
    }
  }

  bool canEnterExam(McqExam exam, DateTime now) {
    return now.isAfter(exam.startAt) && now.isBefore(exam.endAt);
  }

  Future<List<McqQuestion>> getExamQuestions(McqExam exam) async {
    if (exam.questionIds.isEmpty) {
      return [];
    }

    final result = <McqQuestion>[];
    for (final chunk in _chunk(exam.questionIds, 10)) {
      final snapshot = await _firestore
          .collection('mcqQuestions')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      result.addAll(snapshot.docs.map((d) => McqQuestion.fromMap(d.data(), d.id)));
    }

    result.sort((a, b) => exam.questionIds.indexOf(a.id).compareTo(exam.questionIds.indexOf(b.id)));
    return result;
  }

  Future<McqExamAttempt?> getStudentAttempt(String examId, String studentId) async {
    try {
      final doc = await _firestore.collection('mcqExamAttempts').doc('${examId}_$studentId').get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return McqExamAttempt.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<McqExamAttempt?> submitExam({
    required McqExam exam,
    required String studentId,
    required Map<String, int> answers,
    required DateTime startedAt,
  }) async {
    try {
      final questions = await getExamQuestions(exam);
      var correct = 0;
      for (final q in questions) {
        if (answers[q.id] == q.correctIndex) {
          correct++;
        }
      }

      final total = questions.length;
      final percent = total == 0 ? 0.0 : (correct / total) * 100;

      final attempt = McqExamAttempt(
        id: '${exam.id}_$studentId',
        examId: exam.id,
        courseId: exam.courseId,
        studentId: studentId,
        answers: answers,
        totalQuestions: total,
        correctAnswers: correct,
        scorePercent: percent,
        startedAt: startedAt,
        submittedAt: DateTime.now(),
      );

      await _firestore
          .collection('mcqExamAttempts')
          .doc(attempt.id)
          .set(attempt.toMap(), SetOptions(merge: true));

      return attempt;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Course>> getCourseMapByIds(List<String> courseIds) async {
    final map = <String, Course>{};
    for (final chunk in _chunk(courseIds.toSet().toList(), 10)) {
      final snapshot = await _firestore
          .collection('courses')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snapshot.docs) {
        map[d.id] = Course.fromMap(d.data(), d.id);
      }
    }
    return map;
  }

  List<List<T>> _chunk<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size < items.length) ? i + size : items.length;
      chunks.add(items.sublist(i, end));
    }
    return chunks;
  }
}
