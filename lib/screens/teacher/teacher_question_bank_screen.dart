import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../models/exam_system_model.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/exam_system_service.dart';
import 'teacher_exam_builder_screen.dart';

class TeacherQuestionBankScreen extends StatefulWidget {
  const TeacherQuestionBankScreen({Key? key}) : super(key: key);

  @override
  State<TeacherQuestionBankScreen> createState() => _TeacherQuestionBankScreenState();
}

class _TeacherQuestionBankScreenState extends State<TeacherQuestionBankScreen> {
  final _authService = AuthService();
  final _courseService = CourseService();
  final _examService = ExamSystemService();

  List<Course> _courses = [];
  Course? _selectedCourse;
  List<McqQuestion> _questions = [];
  String _search = '';

  final List<String> _difficultyTabs = const ['All', 'easy', 'medium', 'hard'];
  String _selectedDifficulty = 'All';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final courses = await _courseService.getTeacherCourses(uid);
    if (!mounted) {
      return;
    }

    setState(() {
      _courses = courses;
      if (courses.isNotEmpty) {
        _selectedCourse = courses.first;
      }
    });

    await _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (_selectedCourse == null) {
      setState(() => _questions = []);
      return;
    }
    final list = await _examService.getQuestionsByCourse(_selectedCourse!.id);
    if (!mounted) {
      return;
    }
    setState(() => _questions = list);
  }

  List<McqQuestion> _filtered() {
    return _questions.where((q) {
      final matchesDifficulty = _selectedDifficulty == 'All' || q.difficulty == _selectedDifficulty;
      final search = _search.toLowerCase();
      final matchesSearch = q.questionText.toLowerCase().contains(search) ||
          q.tags.any((t) => t.toLowerCase().contains(search));
      return matchesDifficulty && matchesSearch;
    }).toList();
  }

  Future<void> _openCreateQuestion() async {
    if (_selectedCourse == null) {
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => _QuestionEditorDialog(
        courseId: _selectedCourse!.id,
        onSave: (question) async {
          final id = await _examService.createQuestion(question);
          return id != null;
        },
      ),
    );

    _loadQuestions();
  }

  Future<void> _openEditQuestion(McqQuestion question) async {
    await showDialog(
      context: context,
      builder: (_) => _QuestionEditorDialog(
        courseId: question.courseId,
        initial: question,
        onSave: (updated) => _examService.updateQuestion(question.id, updated),
      ),
    );

    _loadQuestions();
  }

  Future<void> _duplicateQuestion(McqQuestion question) async {
    await _examService.duplicateQuestion(question);
    _loadQuestions();
  }

  Future<void> _deleteQuestion(McqQuestion question) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete question?'),
        content: const Text('This question will be archived from question bank.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok == true) {
      await _examService.archiveQuestion(question.id);
      _loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF29449B),
        onPressed: _openCreateQuestion,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_courses.isNotEmpty)
            DropdownButtonFormField<Course>(
              initialValue: _selectedCourse,
              items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (value) {
                setState(() => _selectedCourse = value);
                _loadQuestions();
              },
              decoration: _inputDecoration('Select course'),
            ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: _inputDecoration('Search questions by keywords, tags or IDs...').copyWith(prefixIcon: const Icon(Icons.search)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final label = _difficultyTabs[i];
                final active = _selectedDifficulty == label;
                return InkWell(
                  onTap: () => setState(() => _selectedDifficulty = label),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF29449B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF2D3D5C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _difficultyTabs.length,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _selectedCourse == null
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherExamBuilderScreen(course: _selectedCourse!),
                      ),
                    );
                  },
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Create MCQ Exam From This Question Bank'),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _EmptyBox(text: 'No questions found')
          else
            ...items.map((q) => _questionCard(q)),
        ],
      ),
    );
  }

  Widget _questionCard(McqQuestion q) {
    final diffColor = q.difficulty == 'easy'
        ? const Color(0xFF0BAA60)
        : q.difficulty == 'hard'
            ? const Color(0xFFE74C3C)
            : const Color(0xFFE8A320);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip('MCQ', const Color(0xFF6C8BFF), const Color(0xFFE9EEFF)),
              const SizedBox(width: 6),
              _chip(q.difficulty.toUpperCase(), diffColor, diffColor.withValues(alpha: 0.13)),
              const Spacer(),
              IconButton(onPressed: () => _openEditQuestion(q), icon: const Icon(Icons.edit_outlined, size: 19)),
              IconButton(onPressed: () => _duplicateQuestion(q), icon: const Icon(Icons.copy_outlined, size: 19)),
              IconButton(onPressed: () => _deleteQuestion(q), icon: const Icon(Icons.delete_outline, size: 19)),
            ],
          ),
          Text(
            q.questionText,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF182033), height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: q.tags.map((t) => _chip(t, const Color(0xFF59739F), const Color(0xFFEFF3FA))).toList(),
          ),
          const SizedBox(height: 8),
          Text('Used in ${q.usedInExamCount} exams', style: const TextStyle(color: Color(0xFF6C7A98), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF29449B), width: 1.2),
      ),
    );
  }
}

class _QuestionEditorDialog extends StatefulWidget {
  const _QuestionEditorDialog({
    required this.courseId,
    required this.onSave,
    this.initial,
  });

  final String courseId;
  final McqQuestion? initial;
  final Future<bool> Function(McqQuestion question) onSave;

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  final _questionController = TextEditingController();
  final _tagController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());

  String _difficulty = 'medium';
  int _correctIndex = 0;
  final List<String> _tags = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.initial;
    if (q != null) {
      _questionController.text = q.questionText;
      _difficulty = q.difficulty;
      _correctIndex = q.correctIndex;
      _tags.addAll(q.tags);
      for (var i = 0; i < 4 && i < q.options.length; i++) {
        _optionControllers[i].text = q.options[i];
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _tagController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final options = _optionControllers.map((c) => c.text.trim()).toList();
    if (_questionController.text.trim().isEmpty || options.any((o) => o.isEmpty)) {
      return;
    }

    setState(() => _saving = true);

    final q = McqQuestion(
      id: widget.initial?.id ?? '',
      courseId: widget.courseId,
      questionText: _questionController.text.trim(),
      options: options,
      correctIndex: _correctIndex,
      difficulty: _difficulty,
      tags: List<String>.from(_tags),
      createdBy: widget.initial?.createdBy ?? 'teacher',
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
      usedInExamCount: widget.initial?.usedInExamCount ?? 0,
      isArchived: false,
    );

    final ok = await widget.onSave(q);
    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Create Question' : 'Edit Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < 4; i++) ...[
              TextField(
                controller: _optionControllers[i],
                decoration: InputDecoration(labelText: 'Option ${i + 1}'),
              ),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<int>(
              initialValue: _correctIndex,
              decoration: const InputDecoration(labelText: 'Correct Option'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Option 1')),
                DropdownMenuItem(value: 1, child: Text('Option 2')),
                DropdownMenuItem(value: 2, child: Text('Option 3')),
                DropdownMenuItem(value: 3, child: Text('Option 4')),
              ],
              onChanged: (v) => setState(() => _correctIndex = v ?? 0),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _difficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Easy')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'hard', child: Text('Hard')),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(labelText: 'Add tag and press enter'),
              onSubmitted: (v) {
                final t = v.trim();
                if (t.isEmpty) {
                  return;
                }
                setState(() {
                  _tags.add(t);
                  _tagController.clear();
                });
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags
                  .asMap()
                  .entries
                  .map((e) => Chip(
                        label: Text(e.value),
                        onDeleted: () => setState(() => _tags.removeAt(e.key)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: const TextStyle(color: Color(0xFF6C7A98))),
    );
  }
}
