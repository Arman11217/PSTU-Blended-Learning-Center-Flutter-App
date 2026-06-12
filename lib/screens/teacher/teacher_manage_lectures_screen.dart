import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../models/lecture_qa_model.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/lecture_qa_service.dart';

class TeacherManageLecturesScreen extends StatefulWidget {
  const TeacherManageLecturesScreen({Key? key}) : super(key: key);

  @override
  State<TeacherManageLecturesScreen> createState() => _TeacherManageLecturesScreenState();
}

class _TeacherManageLecturesScreenState extends State<TeacherManageLecturesScreen> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();
  final LectureService _lectureService = LectureService();

  bool _loading = true;
  List<Course> _courses = const [];
  String? _selectedCourseId;
  late Future<List<Lecture>> _lecturesFuture;

  @override
  void initState() {
    super.initState();
    _lecturesFuture = Future.value(const []);
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      return;
    }

    final courses = await _courseService.getTeacherCourses(uid);
    if (!mounted) {
      return;
    }

    setState(() {
      _courses = courses;
      _selectedCourseId = courses.isNotEmpty ? courses.first.id : null;
      _lecturesFuture = _selectedCourseId == null
          ? Future.value(const [])
          : _lectureService.getLecturesByCourse(_selectedCourseId!);
      _loading = false;
    });
  }

  Future<void> _refreshLectures() async {
    final courseId = _selectedCourseId;
    if (courseId == null) {
      return;
    }
    setState(() {
      _lecturesFuture = _lectureService.getLecturesByCourse(courseId);
    });
    await _lecturesFuture;
  }

  Future<void> _deleteLecture(Lecture lecture) async {
    final ok = await _lectureService.deleteLecture(lecture.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Lecture deleted' : 'Failed to delete lecture')),
    );

    if (ok) {
      await _refreshLectures();
    }
  }

  Future<void> _editLecture(Lecture lecture) async {
    final titleController = TextEditingController(text: lecture.title);
    final descriptionController = TextEditingController(text: lecture.description);
    final pdfController = TextEditingController(text: lecture.pdfUrl ?? '');
    final videoController = TextEditingController(text: lecture.videoUrl ?? '');
    final orderController = TextEditingController(text: lecture.lectureOrder.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Lecture'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descriptionController, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: pdfController, decoration: const InputDecoration(labelText: 'PDF URL')),
                TextField(controller: videoController, decoration: const InputDecoration(labelText: 'Video URL')),
                TextField(controller: orderController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Order')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (saved != true) {
      return;
    }

    final updated = Lecture(
      id: lecture.id,
      courseId: lecture.courseId,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      pdfUrl: pdfController.text.trim().isEmpty ? null : pdfController.text.trim(),
      videoUrl: videoController.text.trim().isEmpty ? null : videoController.text.trim(),
      lectureOrder: int.tryParse(orderController.text.trim()) ?? lecture.lectureOrder,
      createdAt: lecture.createdAt,
    );

    final ok = await _lectureService.updateLecture(lecture.id, updated);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Lecture updated' : 'Failed to update lecture')),
    );

    if (ok) {
      await _refreshLectures();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_courses.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No courses found. Create a course first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Lectures')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              decoration: const InputDecoration(labelText: 'Course'),
              items: _courses
                  .map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.code.isNotEmpty ? '${c.code} - ${c.name}' : c.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourseId = value;
                  _lecturesFuture = value == null ? Future.value(const []) : _lectureService.getLecturesByCourse(value);
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Lecture>>(
              future: _lecturesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lectures = snapshot.data ?? const [];
                if (lectures.isEmpty) {
                  return const Center(child: Text('No lectures found for this course'));
                }

                return RefreshIndicator(
                  onRefresh: _refreshLectures,
                  child: ListView.builder(
                    itemCount: lectures.length,
                    itemBuilder: (context, index) {
                      final lecture = lectures[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text('${lecture.lectureOrder}. ${lecture.title}'),
                          subtitle: Text(lecture.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _editLecture(lecture);
                              } else if (value == 'delete') {
                                await _deleteLecture(lecture);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                              PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
