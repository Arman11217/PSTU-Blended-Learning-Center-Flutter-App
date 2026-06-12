import 'package:flutter/material.dart';

import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import '../../services/assignment_service.dart';
import 'teacher_create_assignment_screen.dart';

class TeacherManageAssignmentsScreen extends StatefulWidget {
  const TeacherManageAssignmentsScreen({Key? key, required this.course}) : super(key: key);

  final Course course;

  @override
  State<TeacherManageAssignmentsScreen> createState() => _TeacherManageAssignmentsScreenState();
}

class _TeacherManageAssignmentsScreenState extends State<TeacherManageAssignmentsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  late Future<List<Assignment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Assignment>> _load() {
    return _assignmentService.getAssignmentsByCourse(widget.course.id);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _editAssignment(Assignment assignment) async {
    final titleController = TextEditingController(text: assignment.title);
    final descController = TextEditingController(text: assignment.description);
    final pointsController = TextEditingController(text: assignment.totalPoints.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Points'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (saved != true) {
      return;
    }

    final updated = Assignment(
      id: assignment.id,
      courseId: assignment.courseId,
      title: titleController.text.trim(),
      category: assignment.category,
      totalPoints: int.tryParse(pointsController.text.trim()) ?? assignment.totalPoints,
      description: descController.text.trim(),
      attachmentUrl: assignment.attachmentUrl,
      attachmentName: assignment.attachmentName,
      isDraft: assignment.isDraft,
      dueDate: assignment.dueDate,
      createdAt: assignment.createdAt,
      createdBy: assignment.createdBy,
    );

    final ok = await _assignmentService.updateAssignment(assignment.id, updated);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Assignment updated' : 'Update failed')),
    );

    if (ok) {
      _refresh();
    }
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete assignment?'),
        content: Text('This will remove "${assignment.title}" permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final ok = await _assignmentService.deleteAssignment(assignment.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Assignment deleted' : 'Delete failed')),
    );

    if (ok) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        title: Text(
          '${widget.course.code.isEmpty ? widget.course.name : widget.course.code}: Assignments',
          style: const TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherCreateAssignmentScreen()));
          if (mounted) {
            _refresh();
          }
        },
        backgroundColor: const Color(0xFF29449B),
        foregroundColor: Colors.white,
        label: const Text('Create Assignment', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<Assignment>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No assignments in this course yet'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final a = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${a.category} • Due ${a.dueDate.month}/${a.dueDate.day}/${a.dueDate.year} • ${a.totalPoints} pts'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editAssignment(a);
                        }
                        if (value == 'delete') {
                          _deleteAssignment(a);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
