import 'package:flutter/material.dart';

import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';

class StudentPerformanceScreen extends StatefulWidget {
  const StudentPerformanceScreen({Key? key}) : super(key: key);

  @override
  State<StudentPerformanceScreen> createState() => _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();
  final AssignmentService _assignmentService = AssignmentService();

  late Future<_PerformanceData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PerformanceData> _load() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return const _PerformanceData();
    }

    final courses = await _courseService.getEnrolledCourses(uid);
    final submissions = await _assignmentService.getStudentSubmissions(uid);

    final allAssignments = <Assignment>[];
    for (final course in courses) {
      final assignments = await _assignmentService.getAssignmentsByCourse(course.id);
      allAssignments.addAll(assignments);
    }

    final assignmentById = <String, Assignment>{};
    for (final assignment in allAssignments) {
      assignmentById[assignment.id] = assignment;
    }

    final gradedSubmissions = submissions.where((s) => s.isEvaluated && (s.marks ?? '').trim().isNotEmpty).toList();

    double sumPercent = 0;
    int countPercent = 0;
    double best = 0;
    double lowest = 0;

    final courseStats = <_CoursePerformance>[];

    for (final course in courses) {
      final courseAssignmentIds = allAssignments.where((a) => a.courseId == course.id).map((a) => a.id).toSet();
      final courseGraded = gradedSubmissions.where((s) => courseAssignmentIds.contains(s.assignmentId)).toList();

      final percentages = <double>[];
      for (final submission in courseGraded) {
        final assignment = assignmentById[submission.assignmentId];
        if (assignment == null) {
          continue;
        }
        final obtained = double.tryParse(submission.marks!.trim());
        if (obtained == null || assignment.totalPoints <= 0) {
          continue;
        }
        final p = (obtained / assignment.totalPoints) * 100;
        percentages.add(p);
        sumPercent += p;
        countPercent += 1;
        if (countPercent == 1) {
          best = p;
          lowest = p;
        } else {
          if (p > best) {
            best = p;
          }
          if (p < lowest) {
            lowest = p;
          }
        }
      }

      final avg = percentages.isEmpty ? 0.0 : percentages.reduce((a, b) => a + b) / percentages.length;
      courseStats.add(_CoursePerformance(course: course, averagePercent: avg, gradedCount: percentages.length));
    }

    final average = countPercent == 0 ? 0.0 : sumPercent / countPercent;

    courseStats.sort((a, b) => b.averagePercent.compareTo(a.averagePercent));

    return _PerformanceData(
      totalCourses: courses.length,
      totalSubmissions: submissions.length,
      gradedSubmissions: gradedSubmissions.length,
      averagePercent: average,
      bestPercent: best,
      lowestPercent: lowest,
      courseStats: courseStats,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: FutureBuilder<_PerformanceData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const _PerformanceData();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _metricTile('Courses', '${data.totalCourses}')),
                    const SizedBox(width: 10),
                    Expanded(child: _metricTile('Submissions', '${data.totalSubmissions}')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _metricTile('Average', '${data.averagePercent.toStringAsFixed(1)}%')),
                    const SizedBox(width: 10),
                    Expanded(child: _metricTile('Graded', '${data.gradedSubmissions}')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _metricTile('Best', '${data.bestPercent.toStringAsFixed(1)}%')),
                    const SizedBox(width: 10),
                    Expanded(child: _metricTile('Lowest', '${data.lowestPercent.toStringAsFixed(1)}%')),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Course-wise Performance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 10),
                if (data.courseStats.isEmpty)
                  const Text('No graded data available yet')
                else
                  ...data.courseStats.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(item.course.name),
                        subtitle: Text('${item.gradedCount} graded submission(s)'),
                        trailing: Text('${item.averagePercent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE2EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6C7A98), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PerformanceData {
  final int totalCourses;
  final int totalSubmissions;
  final int gradedSubmissions;
  final double averagePercent;
  final double bestPercent;
  final double lowestPercent;
  final List<_CoursePerformance> courseStats;

  const _PerformanceData({
    this.totalCourses = 0,
    this.totalSubmissions = 0,
    this.gradedSubmissions = 0,
    this.averagePercent = 0,
    this.bestPercent = 0,
    this.lowestPercent = 0,
    this.courseStats = const [],
  });
}

class _CoursePerformance {
  final Course course;
  final double averagePercent;
  final int gradedCount;

  const _CoursePerformance({
    required this.course,
    required this.averagePercent,
    required this.gradedCount,
  });
}
