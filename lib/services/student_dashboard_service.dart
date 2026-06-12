import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardActivity {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;

  const DashboardActivity({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });
}

class StudentDashboardData {
  final String studentName;
  final String facultyName;
  final int enrolledCourses;
  final int newlyEnrolledCourses;
  final int upcomingExams;
  final String upcomingExamHint;
  final int pendingAssignments;
  final int overdueAssignments;
  final List<DashboardActivity> activities;

  const StudentDashboardData({
    required this.studentName,
    required this.facultyName,
    required this.enrolledCourses,
    required this.newlyEnrolledCourses,
    required this.upcomingExams,
    required this.upcomingExamHint,
    required this.pendingAssignments,
    required this.overdueAssignments,
    required this.activities,
  });
}

class StudentDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StudentDashboardData> fetchDashboardData(String studentId) async {
    final now = DateTime.now();

    final userDoc = await _firestore.collection('users').doc(studentId).get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    final enrollmentSnapshot = await _firestore
        .collection('courseEnrollments')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'active')
        .get();

    final enrollmentDocs = enrollmentSnapshot.docs;
    final courseIds = enrollmentDocs
        .map((doc) => (doc.data()['courseId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final recentThreshold = now.subtract(const Duration(days: 14));
    final newlyEnrolledCount = enrollmentDocs.where((doc) {
      final enrolledAt = _toDateTime(doc.data()['enrolledAt']);
      return enrolledAt != null && enrolledAt.isAfter(recentThreshold);
    }).length;

    final courseNameById = await _fetchCourseNames(courseIds);

    final assignmentDocs = await _fetchAssignmentsForCourses(courseIds);
    final submissionSnapshot = await _firestore
        .collection('assignmentSubmissions')
        .where('studentId', isEqualTo: studentId)
        .get();

    final submittedAssignmentIds = submissionSnapshot.docs
        .map((doc) => (doc.data()['assignmentId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final pendingAssignments = assignmentDocs.where((doc) {
      final dueDate = _toDateTime(doc.data()['dueDate']);
      if (dueDate == null) {
        return false;
      }
      final isSubmitted = submittedAssignmentIds.contains(doc.id);
      return !isSubmitted && dueDate.isAfter(now);
    }).toList();

    final overdueAssignments = assignmentDocs.where((doc) {
      final dueDate = _toDateTime(doc.data()['dueDate']);
      if (dueDate == null) {
        return false;
      }
      final isSubmitted = submittedAssignmentIds.contains(doc.id);
      return !isSubmitted && dueDate.isBefore(now);
    }).toList();

    final examDates = await _fetchUpcomingExamDates(courseIds, now);

    int upcomingExams;
    String upcomingExamHint;
    if (examDates.isNotEmpty) {
      examDates.sort();
      upcomingExams = examDates.length;
      final days = examDates.first.difference(now).inDays;
      upcomingExamHint = days <= 0 ? 'Today' : 'Next in $days day${days == 1 ? '' : 's'}';
    } else {
      final pendingDueDates = pendingAssignments
          .map((doc) => _toDateTime(doc.data()['dueDate']))
          .whereType<DateTime>()
          .toList()
        ..sort();

      upcomingExams = pendingDueDates.length;
      if (pendingDueDates.isNotEmpty) {
        final days = pendingDueDates.first.difference(now).inDays;
        upcomingExamHint = days <= 0 ? 'Today' : 'Next in $days day${days == 1 ? '' : 's'}';
      } else {
        upcomingExamHint = 'No upcoming exam';
      }
    }

    final activities = await _buildActivities(
      studentId: studentId,
      now: now,
      enrollments: enrollmentDocs,
      submissions: submissionSnapshot.docs,
      assignments: assignmentDocs,
      courseNameById: courseNameById,
    );

    return StudentDashboardData(
      studentName: (userData['fullName'] as String?)?.trim().isNotEmpty == true
          ? (userData['fullName'] as String)
          : 'Student',
      facultyName: (userData['facultyId'] as String?)?.trim().isNotEmpty == true
          ? (userData['facultyId'] as String)
          : 'Faculty not set',
      enrolledCourses: enrollmentDocs.length,
      newlyEnrolledCourses: newlyEnrolledCount,
      upcomingExams: upcomingExams,
      upcomingExamHint: upcomingExamHint,
      pendingAssignments: pendingAssignments.length,
      overdueAssignments: overdueAssignments.length,
      activities: activities,
    );
  }

  Future<Map<String, String>> _fetchCourseNames(List<String> courseIds) async {
    final map = <String, String>{};
    if (courseIds.isEmpty) {
      return map;
    }

    for (final chunk in _chunked(courseIds, 10)) {
      final snapshot = await _firestore
          .collection('courses')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        map[doc.id] = (doc.data()['name'] as String?) ?? 'Untitled course';
      }
    }

    return map;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchAssignmentsForCourses(
    List<String> courseIds,
  ) async {
    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    if (courseIds.isEmpty) {
      return allDocs;
    }

    for (final chunk in _chunked(courseIds, 10)) {
      final snapshot = await _firestore
          .collection('assignments')
          .where('courseId', whereIn: chunk)
          .get();
      allDocs.addAll(snapshot.docs);
    }

    return allDocs;
  }

  Future<List<DateTime>> _fetchUpcomingExamDates(List<String> courseIds, DateTime now) async {
    final dates = <DateTime>[];
    if (courseIds.isEmpty) {
      return dates;
    }

    try {
      for (final chunk in _chunked(courseIds, 10)) {
        final snapshot = await _firestore
            .collection('exams')
            .where('courseId', whereIn: chunk)
            .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .orderBy('scheduledAt')
            .limit(20)
            .get();

        for (final doc in snapshot.docs) {
          final date = _toDateTime(doc.data()['scheduledAt']);
          if (date != null) {
            dates.add(date);
          }
        }
      }
    } catch (_) {
      return [];
    }

    return dates;
  }

  Future<List<DashboardActivity>> _buildActivities({
    required String studentId,
    required DateTime now,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> enrollments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> submissions,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> assignments,
    required Map<String, String> courseNameById,
  }) async {
    final activities = <DashboardActivity>[];

    final assignmentTitleById = <String, String>{
      for (final doc in assignments)
        doc.id: ((doc.data()['title'] as String?) ?? 'Assignment')
    };

    for (final doc in enrollments) {
      final data = doc.data();
      final ts = _toDateTime(data['enrolledAt']);
      if (ts == null) {
        continue;
      }
      final courseId = (data['courseId'] as String?) ?? '';
      final name = courseNameById[courseId] ?? 'course';
      activities.add(DashboardActivity(
        type: 'enroll',
        title: 'Enrolled in course',
        description: name,
        timestamp: ts,
      ));
    }

    for (final doc in submissions) {
      final data = doc.data();
      final ts = _toDateTime(data['submittedAt']);
      if (ts == null) {
        continue;
      }
      final assignmentId = (data['assignmentId'] as String?) ?? '';
      final title = assignmentTitleById[assignmentId] ?? 'Assignment submission';
      activities.add(DashboardActivity(
        type: 'submission',
        title: 'Assignment Submitted',
        description: title,
        timestamp: ts,
      ));
    }

    final weekAgo = now.subtract(const Duration(days: 7));
    for (final doc in assignments) {
      final data = doc.data();
      final createdAt = _toDateTime(data['createdAt']);
      if (createdAt == null || createdAt.isBefore(weekAgo)) {
        continue;
      }
      final title = (data['title'] as String?) ?? 'New assignment';
      activities.add(DashboardActivity(
        type: 'resource',
        title: 'New Assignment Posted',
        description: title,
        timestamp: createdAt,
      ));
    }

    try {
      final questionSnapshot = await _firestore
          .collection('questions')
          .where('userId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .limit(6)
          .get();

      for (final doc in questionSnapshot.docs) {
        final data = doc.data();
        final ts = _toDateTime(data['createdAt']);
        if (ts == null) {
          continue;
        }
        final title = (data['title'] as String?) ?? 'Forum activity';
        activities.add(DashboardActivity(
          type: 'forum',
          title: 'Forum Question Posted',
          description: title,
          timestamp: ts,
        ));
      }
    } catch (_) {
      // Ignore optional feed errors for now.
    }

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (activities.length > 8) {
      return activities.sublist(0, 8);
    }
    return activities;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  List<List<T>> _chunked<T>(List<T> input, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < input.length; i += size) {
      final end = (i + size < input.length) ? i + size : input.length;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }
}
