import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/file_storage_service.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({
    Key? key,
    this.initialCourseId,
    this.initialAssignmentId,
    this.openAssignmentOnLoad = false,
  }) : super(key: key);

  final String? initialCourseId;
  final String? initialAssignmentId;
  final bool openAssignmentOnLoad;

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  final _authService = AuthService();
  final _courseService = CourseService();
  final _assignmentService = AssignmentService();

  late Future<List<_AssignmentVm>> _future;
  String _query = '';
  int _tab = 0; // 0 all, 1 pending, 2 submitted
  bool _didAutoOpen = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_AssignmentVm>> _load() async {
    final user = _authService.currentUser;
    if (user == null) {
      return [];
    }

    final courses = await _courseService.getEnrolledCourses(user.uid);
    final all = <_AssignmentVm>[];

    for (final c in courses) {
      final assignments = await _assignmentService.getAssignmentsByCourse(c.id);
      for (final a in assignments) {
        if (a.isDraft) {
          continue;
        }
        final submission = await _assignmentService.getStudentSubmission(a.id, user.uid);
        all.add(_AssignmentVm(course: c, assignment: a, submission: submission));
      }
    }

    all.sort((x, y) => x.assignment.dueDate.compareTo(y.assignment.dueDate));
    return all;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: FutureBuilder<List<_AssignmentVm>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];

          if (widget.openAssignmentOnLoad && !_didAutoOpen && all.isNotEmpty) {
            _didAutoOpen = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) {
                return;
              }

              _AssignmentVm? target;
              final targetAssignmentId = widget.initialAssignmentId;
              final targetCourseId = widget.initialCourseId;

              for (final item in all) {
                final byAssignment = targetAssignmentId != null && item.assignment.id == targetAssignmentId;
                final byCourse = targetCourseId != null && item.course.id == targetCourseId;
                if (byAssignment || byCourse) {
                  target = item;
                  break;
                }
              }

              if (target != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _StudentAssignmentDetailScreen(item: target!)),
                );
                if (mounted) {
                  _refresh();
                }
              }
            });
          }

          final filteredByTab = all.where((item) {
            if (_tab == 1) {
              return item.status == AssignmentStatus.pending;
            }
            if (_tab == 2) {
              return item.status == AssignmentStatus.submitted || item.status == AssignmentStatus.graded;
            }
            return true;
          }).toList();

          final filtered = filteredByTab
              .where((item) => item.assignment.title.toLowerCase().contains(_query.toLowerCase()) || item.course.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search assignments',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _tabBtn('All', 0),
                    const SizedBox(width: 10),
                    _tabBtn('Pending', 1),
                    const SizedBox(width: 10),
                    _tabBtn('Submitted', 2),
                  ],
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const _EmptyBox(text: 'No assignment found')
                else
                  ...filtered.map((item) => _card(context, item)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF29449B) : const Color(0xFF6C7A98),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 36,
            height: 3,
            color: active ? const Color(0xFF29449B) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, _AssignmentVm item) {
    final status = item.status;
    final statusMeta = switch (status) {
      AssignmentStatus.pending => ('PENDING', const Color(0xFFE8A320), const Color(0xFFFFF2D9)),
      AssignmentStatus.submitted => ('SUBMITTED', const Color(0xFF0BAA60), const Color(0xFFE8F7F0)),
      AssignmentStatus.graded => ('GRADED', const Color(0xFF29449B), const Color(0xFFE8EEFF)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.course.name.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF29449B), fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusMeta.$3, borderRadius: BorderRadius.circular(12)),
                child: Text(statusMeta.$1, style: TextStyle(color: statusMeta.$2, fontSize: 11, fontWeight: FontWeight.w800)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(item.assignment.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF182033))),
          const SizedBox(height: 6),
          Text('Due: ${_formatDate(item.assignment.dueDate)}', style: const TextStyle(color: Color(0xFF6C7A98))),
          if (item.status == AssignmentStatus.graded && item.submission?.marks != null) ...[
            const SizedBox(height: 8),
            Text('Score: ${item.submission!.marks}/${item.assignment.totalPoints}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _StudentAssignmentDetailScreen(item: item)),
                );
                if (context.mounted) {
                  _refresh();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29449B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(status == AssignmentStatus.graded ? 'View Grade' : 'View Details'),
            ),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_month(date.month)} ${date.day}, ${date.year}';
  }

  String _month(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m - 1];
  }
}

class _StudentAssignmentDetailScreen extends StatefulWidget {
  const _StudentAssignmentDetailScreen({Key? key, required this.item}) : super(key: key);

  final _AssignmentVm item;

  @override
  State<_StudentAssignmentDetailScreen> createState() => _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState extends State<_StudentAssignmentDetailScreen> {
  final _authService = AuthService();
  final _assignmentService = AssignmentService();
  final _fileStorageService = FileStorageService();

  PlatformFile? _pickedFile;
  Uint8List? _pickedBytes;
  bool _submitting = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'zip', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() {
      _pickedFile = result.files.first;
      _pickedBytes = _pickedFile!.bytes;
    });
  }

  Future<void> _submit() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null || _pickedFile == null || _pickedBytes == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final safeName = _pickedFile!.name.replaceAll(' ', '_');
      final ext = (_pickedFile!.extension ?? '').toLowerCase();
      final contentType = switch (ext) {
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'zip' => 'application/zip',
        _ => 'application/octet-stream',
      };

      final fileUrl = await _fileStorageService.uploadBinary(
        bytes: _pickedBytes!,
        path: 'student_submissions/$uid/${widget.item.assignment.id}/$safeName',
        contentType: contentType,
      );

      final submission = AssignmentSubmission(
        id: '',
        assignmentId: widget.item.assignment.id,
        studentId: uid,
        fileUrl: fileUrl,
        submittedAt: DateTime.now(),
      );

      final id = await _assignmentService.submitAssignment(submission);
      if (!mounted) {
        return;
      }

      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission failed')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission uploaded')));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload submission. Check Supabase configuration.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.item.assignment;
    final status = widget.item.status;
    final canResubmit =
        status == AssignmentStatus.submitted && DateTime.now().isBefore(assignment.dueDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        title: const Text('Assignment Details', style: TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE8EEFF), borderRadius: BorderRadius.circular(10)),
                  child: Text(widget.item.course.name, style: const TextStyle(color: Color(0xFF29449B), fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _meta('DEADLINE', '${assignment.dueDate.month}/${assignment.dueDate.day}/${assignment.dueDate.year}')),
                    const SizedBox(width: 10),
                    Expanded(child: _meta('TOTAL POINTS', '${assignment.totalPoints} Points')),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD2DCEE)),
                  ),
                  child: Text(
                    status == AssignmentStatus.pending
                        ? 'Pending Submission'
                        : status == AssignmentStatus.submitted
                            ? 'Submitted'
                            : 'Graded: ${widget.item.submission?.marks ?? '-'} / ${assignment.totalPoints}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Instructions', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF29449B))),
                const SizedBox(height: 8),
                Text(assignment.description, style: const TextStyle(color: Color(0xFF263754), height: 1.5, fontSize: 16)),
                if (assignment.attachmentUrl != null && assignment.attachmentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(assignment.attachmentUrl!),
                    icon: const Icon(Icons.download_outlined),
                    label: Text('Download ${assignment.attachmentName ?? 'Attachment'}'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (status == AssignmentStatus.pending || canResubmit) ...[
            const Text('Upload Submission', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF182033))),
            const SizedBox(height: 10),
            if (status == AssignmentStatus.submitted)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'You can resubmit before deadline. Latest submission will be counted.',
                  style: TextStyle(color: Color(0xFF6C7A98)),
                ),
              ),
            InkWell(
              onTap: _pick,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD2DCEE)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file_outlined, size: 36, color: Color(0xFF29449B)),
                    const SizedBox(height: 8),
                    Text(_pickedFile == null ? 'Click or drag to upload' : _pickedFile!.name),
                    const SizedBox(height: 4),
                    const Text('PDF, ZIP, or DOCX (Max 50MB)', style: TextStyle(color: Color(0xFF6C7A98))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_pickedFile == null || _submitting) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29449B),
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(status == AssignmentStatus.pending ? 'Submit Assignment' : 'Resubmit Assignment'),
              ),
            )
          ] else ...[
            const _EmptyBox(text: 'Submission locked (graded or deadline passed).'),
          ],
          if (widget.item.submission?.fileUrl.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openUrl(widget.item.submission!.fileUrl),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open My Submitted File'),
            ),
          ]
        ],
      ),
    );
  }

  Widget _meta(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF7A88A6), fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF182033))),
        ],
      ),
    );
  }
}

enum AssignmentStatus { pending, submitted, graded }

class _AssignmentVm {
  final Course course;
  final Assignment assignment;
  final AssignmentSubmission? submission;

  const _AssignmentVm({
    required this.course,
    required this.assignment,
    required this.submission,
  });

  AssignmentStatus get status {
    if (submission == null) {
      return AssignmentStatus.pending;
    }
    if (submission!.isEvaluated) {
      return AssignmentStatus.graded;
    }
    return AssignmentStatus.submitted;
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Color(0xFF6C7A98))),
    );
  }
}
