import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/file_storage_service.dart';

class TeacherCreateAssignmentScreen extends StatefulWidget {
  const TeacherCreateAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<TeacherCreateAssignmentScreen> createState() => _TeacherCreateAssignmentScreenState();
}

class _TeacherCreateAssignmentScreenState extends State<TeacherCreateAssignmentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '100');

  final _authService = AuthService();
  final _courseService = CourseService();
  final _assignmentService = AssignmentService();
  final _fileStorageService = FileStorageService();

  List<Course> _teacherCourses = [];
  Course? _selectedCourse;
  String _selectedCategory = 'Project';
  DateTime? _dueDate;
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);
  bool _saving = false;

  PlatformFile? _pickedFile;
  Uint8List? _pickedFileBytes;

  final List<String> _categories = const [
    'Project',
    'Quiz',
    'Lab',
    'Homework',
    'Exam Prep',
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final courses = await _courseService.getTeacherCourses(uid);
    if (!mounted) {
      return;
    }

    setState(() {
      _teacherCourses = courses;
      if (courses.isNotEmpty) {
        _selectedCourse = courses.first;
      }
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );

    if (selected != null) {
      setState(() => _dueTime = selected);
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'zip'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final selected = result.files.first;
    const maxBytes = 20 * 1024 * 1024;
    if (selected.size > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is too large. Maximum 20MB allowed.')),
        );
      }
      return;
    }

    setState(() {
      _pickedFile = selected;
      _pickedFileBytes = _pickedFile?.bytes;
    });
  }

  Future<String?> _uploadAttachment(String assignmentIdHint) async {
    if (_pickedFile == null) {
      return null;
    }

    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    final safeName = _pickedFile!.name.replaceAll(' ', '_');

    final ext = (_pickedFile!.extension ?? '').toLowerCase();
    String contentType;
    switch (ext) {
      case 'pdf':
        contentType = 'application/pdf';
        break;
      case 'doc':
        contentType = 'application/msword';
        break;
      case 'docx':
        contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        break;
      case 'zip':
        contentType = 'application/zip';
        break;
      default:
        contentType = 'application/octet-stream';
    }

    Uint8List? bytes = _pickedFileBytes;
    if (bytes == null && _pickedFile!.path != null && _pickedFile!.path!.isNotEmpty) {
      final file = File(_pickedFile!.path!);
      bytes = await file.readAsBytes();
    }

    if (bytes == null) {
      throw StateError('Unable to read selected file data.');
    }

    return _fileStorageService
        .uploadBinary(
          bytes: bytes,
          path: 'assignment_attachments/$uid/$assignmentIdHint/$safeName',
          contentType: contentType,
        )
        .timeout(const Duration(seconds: 90));
  }

  Future<void> _save({required bool asDraft}) async {
    final teacherId = _authService.currentUser?.uid;
    if (teacherId == null) {
      return;
    }

    if (_selectedCourse == null || _titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    final points = int.tryParse(_pointsController.text.trim()) ?? 100;
    final dueDateTime = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    setState(() => _saving = true);

    try {
      String? attachmentUrl;
      String? uploadWarning;
      if (_pickedFile != null) {
        try {
          attachmentUrl = await _uploadAttachment('${_selectedCourse!.id}_${DateTime.now().millisecondsSinceEpoch}');
        } catch (e) {
          uploadWarning = 'Attachment upload failed, assignment created without file.';
        }
      }

      final assignment = Assignment(
        id: '',
        courseId: _selectedCourse!.id,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        totalPoints: points,
        description: _descriptionController.text.trim(),
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentUrl == null ? null : _pickedFile?.name,
        isDraft: asDraft,
        dueDate: dueDateTime,
        createdAt: DateTime.now(),
        createdBy: teacherId,
      );

      final id = await _assignmentService
          .createAssignment(assignment)
          .timeout(const Duration(seconds: 25));
      if (!mounted) {
        return;
      }

      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create assignment')));
        setState(() => _saving = false);
        return;
      }

      _titleController.clear();
      _descriptionController.clear();
      _pointsController.text = '100';
      setState(() {
        _dueDate = null;
        _dueTime = const TimeOfDay(hour: 23, minute: 59);
        _pickedFile = null;
        _pickedFileBytes = null;
        _saving = false;
      });

      final successMessage = uploadWarning ?? (asDraft ? 'Saved as draft' : 'Assignment created');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } on TimeoutException {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request timeout. Check internet or Firebase rules and try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create assignment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        title: const Text(
          'Create New Assignment',
          style: TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  if (_teacherCourses.isNotEmpty)
                    Text(
                      _selectedCourse?.name ?? '',
                      style: const TextStyle(color: Color(0xFF29449B), fontWeight: FontWeight.w700),
                    ),
                  const SizedBox(height: 12),
                  if (_teacherCourses.isEmpty)
                    const _EmptyBox(text: 'No course found. Please create a course first.')
                  else ...[
                    DropdownButtonFormField<Course>(
                      initialValue: _selectedCourse,
                      decoration: _inputDecoration('Select course'),
                      items: _teacherCourses.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _selectedCourse = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: _inputDecoration('Assignment Title'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: _inputDecoration('Category'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v ?? 'Project'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Total Points'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: _inputDecoration('Due Date'),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF7B8BAA)),
                            const SizedBox(width: 8),
                            Text(_dueDate == null
                                ? 'mm/dd/yyyy'
                                : '${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.year}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: _inputDecoration('Due Time'),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF7B8BAA)),
                            const SizedBox(width: 8),
                            Text(_dueTime.format(context)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      minLines: 5,
                      maxLines: 8,
                      decoration: _inputDecoration('Assignment Instructions'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickAttachment,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD6E8), style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.upload_file_outlined, size: 34, color: Color(0xFF29449B)),
                            const SizedBox(height: 8),
                            Text(
                              _pickedFile == null ? 'Click to upload or drag and drop' : _pickedFile!.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF263754)),
                            ),
                            const SizedBox(height: 4),
                            const Text('PDF, DOCX, or ZIP (max 20MB)', style: TextStyle(color: Color(0xFF7283A4))),
                          ],
                        ),
                      ),
                    ),
                    if (_pickedFile != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_pickedFile!.name)),
                            IconButton(
                              onPressed: () => setState(() {
                                _pickedFile = null;
                                _pickedFileBytes = null;
                              }),
                              icon: const Icon(Icons.delete_outline),
                            )
                          ],
                        ),
                      )
                    ]
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _save(asDraft: true),
                      child: const Text('Save as Draft'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _save(asDraft: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29449B),
                        foregroundColor: Colors.white,
                      ),
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.assignment_add),
                      label: const Text('Create Assignment', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F8FD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF29449B), width: 1.2),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}
