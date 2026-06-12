import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/course_model.dart';
import '../../models/lecture_qa_model.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/file_storage_service.dart';
import '../../services/lecture_qa_service.dart';

class TeacherUploadLectureScreen extends StatefulWidget {
  const TeacherUploadLectureScreen({Key? key}) : super(key: key);

  @override
  State<TeacherUploadLectureScreen> createState() => _TeacherUploadLectureScreenState();
}

class _TeacherUploadLectureScreenState extends State<TeacherUploadLectureScreen> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();
  final LectureService _lectureService = LectureService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoController = TextEditingController();
  final _orderController = TextEditingController(text: '1');
  final _fileStorageService = FileStorageService();

  List<Course> _courses = const [];
  String? _selectedCourseId;
  bool _loadingCourses = true;
  bool _saving = false;
  PlatformFile? _pickedPdfFile;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() => _pickedPdfFile = result.files.first);
  }

  Future<void> _loadCourses() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingCourses = false);
      return;
    }

    final courses = await _courseService.getTeacherCourses(uid);
    if (!mounted) {
      return;
    }

    setState(() {
      _courses = courses;
      _selectedCourseId = courses.isNotEmpty ? courses.first.id : null;
      _loadingCourses = false;
    });
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final courseId = _selectedCourseId;

    if (courseId == null || title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    final order = int.tryParse(_orderController.text.trim()) ?? 1;

    setState(() => _saving = true);

    String? pdfUrl;
    if (_pickedPdfFile != null) {
      final file = _pickedPdfFile!;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to read selected PDF file')),
          );
        }
        return;
      }

      final safeName = file.name.replaceAll(' ', '_');
      try {
        pdfUrl = await _fileStorageService.uploadBinary(
          bytes: bytes,
          path: 'lecture_materials/$courseId/${DateTime.now().millisecondsSinceEpoch}_$safeName',
          contentType: 'application/pdf',
        );
      } catch (_) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload PDF to storage')),
          );
        }
        return;
      }
    }

    final lecture = Lecture(
      id: '',
      courseId: courseId,
      title: title,
      description: description,
      pdfUrl: pdfUrl,
      videoUrl: _videoController.text.trim().isEmpty ? null : _videoController.text.trim(),
      lectureOrder: order,
      createdAt: DateTime.now(),
    );

    final id = await _lectureService.createLecture(lecture);
    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload lecture')),
      );
      return;
    }

    _titleController.clear();
    _descriptionController.clear();
    _videoController.clear();
    _orderController.text = '1';
    setState(() => _pickedPdfFile = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lecture uploaded successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCourses) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_courses.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Create a course first to upload lectures.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Lecture')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCourseId,
            decoration: const InputDecoration(labelText: 'Course'),
            items: _courses
                .map((c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.code.isNotEmpty ? '${c.code} - ${c.name}' : c.name),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedCourseId = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Lecture title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 10),
          const Text('PDF File (optional)'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickPdf,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(_pickedPdfFile == null ? 'Choose PDF' : _pickedPdfFile!.name),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _videoController,
            decoration: const InputDecoration(labelText: 'Video URL (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _orderController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Lecture order'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Upload Lecture'),
          ),
        ],
      ),
    );
  }
}
