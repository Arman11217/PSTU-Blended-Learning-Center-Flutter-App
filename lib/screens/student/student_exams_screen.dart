import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../models/exam_system_model.dart';
import '../../services/auth_service.dart';
import '../../services/exam_system_service.dart';

class StudentExamsScreen extends StatefulWidget {
  const StudentExamsScreen({Key? key}) : super(key: key);

  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen> {
  final _authService = AuthService();
  final _examService = ExamSystemService();

  late Future<List<_ExamCardVm>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ExamCardVm>> _load() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return [];
    }

    final exams = await _examService.getStudentUpcomingExams(uid);
    final courseMap = await _examService.getCourseMapByIds(exams.map((e) => e.courseId).toList());

    return exams
        .map((e) => _ExamCardVm(exam: e, course: courseMap[e.courseId]))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ExamCardVm>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No upcoming exams found'));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((item) => _examCard(item)).toList(),
          ),
        );
      },
    );
  }

  Widget _examCard(_ExamCardVm item) {
    final now = DateTime.now();
    final canEnter = _examService.canEnterExam(item.exam, now);
    final startsSoon = item.exam.startAt.isAfter(now) && item.exam.startAt.difference(now).inMinutes <= 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF29449B),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: item.course?.bannerImageUrl != null && item.course!.bannerImageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(item.course!.bannerImageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: startsSoon ? const Color(0xFF0BAA60) : const Color(0xFFE9EDF6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  startsSoon ? 'STARTING SOON' : 'SCHEDULED',
                  style: TextStyle(
                    color: startsSoon ? Colors.white : const Color(0xFF5D6D8B),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.course?.name ?? 'Course', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28, color: Color(0xFF182033))),
                const SizedBox(height: 4),
                Text(item.exam.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF29449B))),
                const SizedBox(height: 8),
                Text('Date: ${_date(item.exam.startAt)} • ${_time(item.exam.startAt)} - ${_time(item.exam.endAt)}'),
                const SizedBox(height: 4),
                Text('${item.exam.questionIds.length} MCQ • ${item.exam.durationMinutes} mins', style: const TextStyle(color: Color(0xFF6C7A98))),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canEnter
                        ? () async {
                            final uid = _authService.currentUser?.uid;
                            if (uid == null) {
                              return;
                            }
                            final existing = await _examService.getStudentAttempt(item.exam.id, uid);
                            if (!mounted) {
                              return;
                            }
                            if (existing != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentExamResultScreen(exam: item.exam, attempt: existing, course: item.course),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => StudentTakeExamScreen(exam: item.exam, course: item.course)),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF29449B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.login),
                    label: Text(canEnter ? 'Enter Exam' : 'Locked'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) => '${_month(d.month)} ${d.day}, ${d.year}';

  String _time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ap';
  }

  String _month(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m - 1];
  }
}

class StudentTakeExamScreen extends StatefulWidget {
  const StudentTakeExamScreen({Key? key, required this.exam, required this.course}) : super(key: key);

  final McqExam exam;
  final Course? course;

  @override
  State<StudentTakeExamScreen> createState() => _StudentTakeExamScreenState();
}

class _StudentTakeExamScreenState extends State<StudentTakeExamScreen> {
  final _authService = AuthService();
  final _examService = ExamSystemService();

  List<McqQuestion> _questions = [];
  final Map<String, int> _answers = {};
  int _index = 0;
  bool _loading = true;
  bool _submitting = false;
  DateTime _startedAt = DateTime.now();

  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final questions = await _examService.getExamQuestions(widget.exam);

    if (!mounted) {
      return;
    }

    setState(() {
      _questions = questions;
      _loading = false;
    });

    _startTimer();
  }

  void _startTimer() {
    final now = DateTime.now();
    final byDuration = _startedAt.add(Duration(minutes: widget.exam.durationMinutes));
    final deadline = byDuration.isBefore(widget.exam.endAt) ? byDuration : widget.exam.endAt;

    _remaining = deadline.difference(now);
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final nowTick = DateTime.now();
      final diff = deadline.difference(nowTick);
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });

      if (diff.isNegative || diff.inSeconds == 0) {
        timer.cancel();
        _submit(autoSubmit: true);
      }
    });
  }

  Future<void> _submit({bool autoSubmit = false}) async {
    if (_submitting) {
      return;
    }

    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return;
    }

    if (!autoSubmit && _answers.length < _questions.length) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Submit exam?'),
          content: const Text('Some questions are unanswered. Submit anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        ),
      );

      if (ok != true) {
        return;
      }
    }

    setState(() => _submitting = true);
    _timer?.cancel();

    final attempt = await _examService.submitExam(
      exam: widget.exam,
      studentId: uid,
      answers: Map<String, int>.from(_answers),
      startedAt: _startedAt,
    );

    if (!mounted) {
      return;
    }

    if (attempt == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission failed')));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentExamResultScreen(
          exam: widget.exam,
          attempt: attempt,
          course: widget.course,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('No questions in this exam')));
    }

    final q = _questions[_index];
    final selected = _answers[q.id];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(widget.exam.title, style: const TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800)),
            ),
            TextButton(onPressed: _submitting ? null : () => _submit(), child: const Text('Submit')),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _timeCard(_remaining.inHours.toString().padLeft(2, '0'), 'HRS'),
                const SizedBox(width: 8),
                _timeCard((_remaining.inMinutes % 60).toString().padLeft(2, '0'), 'MIN'),
                const SizedBox(width: 8),
                _timeCard((_remaining.inSeconds % 60).toString().padLeft(2, '0'), 'SEC'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PROGRESS', style: TextStyle(letterSpacing: 1.2, color: Color(0xFF6C7A98), fontWeight: FontWeight.w800)),
                    Text('Question ${_index + 1} of ${_questions.length}', style: const TextStyle(color: Color(0xFF29449B), fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_index + 1) / _questions.length,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFDCE3F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF29449B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(q.questionText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF182033), height: 1.4)),
                const SizedBox(height: 16),
                for (var i = 0; i < q.options.length; i++) ...[
                  GestureDetector(
                    onTap: () => setState(() => _answers[q.id] = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected == i ? const Color(0xFF29449B) : const Color(0xFFD8E0EE),
                          width: selected == i ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(selected == i ? Icons.radio_button_checked : Icons.radio_button_off, color: selected == i ? const Color(0xFF29449B) : const Color(0xFFA6B3CB)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(q.options[i], style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222E47)))),
                        ],
                      ),
                    ),
                  )
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'You can change your answer anytime before submitting the exam.',
                    style: TextStyle(color: Color(0xFF6C7A98)),
                  ),
                )
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _index > 0 ? () => setState(() => _index--) : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _index < _questions.length - 1 ? () => setState(() => _index++) : (_submitting ? null : () => _submit()),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29449B), foregroundColor: Colors.white),
                    icon: Icon(_index < _questions.length - 1 ? Icons.arrow_forward : Icons.check),
                    label: Text(_index < _questions.length - 1 ? 'Next' : 'Finish'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _timeCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: Color(0xFF29449B))),
            Text(label, style: const TextStyle(color: Color(0xFF6C7A98), fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class StudentExamResultScreen extends StatelessWidget {
  const StudentExamResultScreen({Key? key, required this.exam, required this.attempt, required this.course}) : super(key: key);

  final McqExam exam;
  final McqExamAttempt attempt;
  final Course? course;

  @override
  Widget build(BuildContext context) {
    final score = attempt.correctAnswers;
    final total = attempt.totalQuestions;
    final percent = attempt.scorePercent;

    String grade;
    if (percent >= 80) {
      grade = 'A';
    } else if (percent >= 70) {
      grade = 'B';
    } else if (percent >= 60) {
      grade = 'C';
    } else if (percent >= 50) {
      grade = 'D';
    } else {
      grade = 'F';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        title: const Text('Exam Result', style: TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${course?.code.isEmpty == false ? course!.code : 'COURSE'} • ${course?.department ?? ''}',
                  style: const TextStyle(color: Color(0xFF6C7A98), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(exam.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF182033))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFF29449B), borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('$score/$total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 30)),
                            const SizedBox(height: 4),
                            Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFFDCE5FF))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFE9EDF6), borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Final Grade', style: TextStyle(color: Color(0xFF6C7A98), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(grade, style: const TextStyle(color: Color(0xFF29449B), fontWeight: FontWeight.w800, fontSize: 34)),
                            const SizedBox(height: 4),
                            const Text('MCQ Exam', style: TextStyle(color: Color(0xFF6C7A98))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF9E9), borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'Instructor feedback: Keep practicing MCQ time management and review weak topics before the final exam.',
                    style: TextStyle(color: Color(0xFF5E4E25), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == null),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29449B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Back To Exams', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ExamCardVm {
  final McqExam exam;
  final Course? course;

  const _ExamCardVm({required this.exam, required this.course});
}
