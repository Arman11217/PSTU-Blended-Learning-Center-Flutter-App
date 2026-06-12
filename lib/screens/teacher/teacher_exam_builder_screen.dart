import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../models/exam_system_model.dart';
import '../../services/auth_service.dart';
import '../../services/exam_system_service.dart';

class TeacherExamBuilderScreen extends StatefulWidget {
  const TeacherExamBuilderScreen({Key? key, required this.course}) : super(key: key);

  final Course course;

  @override
  State<TeacherExamBuilderScreen> createState() => _TeacherExamBuilderScreenState();
}

class _TeacherExamBuilderScreenState extends State<TeacherExamBuilderScreen> {
  final _titleController = TextEditingController();
  final _questionCountController = TextEditingController(text: '20');
  final _durationController = TextEditingController(text: '60');
  final _tagFilterController = TextEditingController();

  final _examService = ExamSystemService();
  final _authService = AuthService();

  bool _saving = false;
  bool _loadingBank = true;
  List<McqQuestion> _bankQuestions = const [];
  bool _manualSelection = false;
  final Set<String> _selectedQuestionIds = {};
  DateTime? _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime? _endDate;
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(days: 1));
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day);
    _titleController.text = '${widget.course.name} Midterm Exam';
    _loadQuestionBank();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionCountController.dispose();
    _durationController.dispose();
    _tagFilterController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _loadQuestionBank() async {
    setState(() => _loadingBank = true);
    final items = await _examService.getQuestionsByCourse(widget.course.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _bankQuestions = items;
      _loadingBank = false;
    });
  }

  int _matchingQuestionCount() {
    final tagFilter = _tagFilterController.text.trim().toLowerCase();
    if (tagFilter.isEmpty) {
      return _bankQuestions.length;
    }

    return _bankQuestions
        .where((q) => q.tags.any((t) => t.toLowerCase().contains(tagFilter)))
        .length;
  }

  Future<void> _createExam() async {
    final creator = _authService.currentUser?.uid;
    if (creator == null || _startDate == null || _endDate == null) {
      return;
    }

    final startAt = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endAt = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime.hour,
      _endTime.minute,
    );

    final questionCount = int.tryParse(_questionCountController.text.trim()) ?? 20;
    final duration = int.tryParse(_durationController.text.trim()) ?? 60;
    final available = _matchingQuestionCount();

    if (_titleController.text.trim().isEmpty || questionCount <= 0 || duration <= 0 || endAt.isBefore(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide valid exam data')));
      return;
    }

    if (!_manualSelection && questionCount > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You requested $questionCount questions, but only $available match this course/filter.')),
      );
      return;
    }

    if (_manualSelection && _selectedQuestionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one question for manual exam.')),
      );
      return;
    }

    setState(() => _saving = true);

    final id = _manualSelection
        ? await _examService.createExamFromSelectedQuestions(
            courseId: widget.course.id,
            title: _titleController.text.trim(),
            questionIds: _selectedQuestionIds.toList(),
            durationMinutes: duration,
            startAt: startAt,
            endAt: endAt,
            createdBy: creator,
          )
        : await _examService.createExamFromQuestionBank(
            courseId: widget.course.id,
            title: _titleController.text.trim(),
            questionCount: questionCount,
            durationMinutes: duration,
            startAt: startAt,
            endAt: endAt,
            createdBy: creator,
            tagFilter: _tagFilterController.text.trim().isEmpty ? null : _tagFilterController.text.trim(),
          );

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (id == null) {
      final reason = _examService.lastError ?? 'Exam creation failed. Check question bank size/filter.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam created successfully')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        title: const Text('Create MCQ Exam', style: TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.course.name, style: const TextStyle(color: Color(0xFF29449B), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8E0EE)),
            ),
            child: _loadingBank
                ? const Text('Checking question bank...', style: TextStyle(color: Color(0xFF6C7A98)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total questions in bank: ${_bankQuestions.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Tag filter match: ${_matchingQuestionCount()}', style: const TextStyle(color: Color(0xFF4A5876))),
                      const SizedBox(height: 6),
                      const Text(
                        'Exam questions are selected randomly from question bank based on count and tag filter.',
                        style: TextStyle(color: Color(0xFF6C7A98), fontSize: 12),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _modeChip('Random', !_manualSelection, () => setState(() => _manualSelection = false)),
              const SizedBox(width: 8),
              _modeChip('Manual Select', _manualSelection, () => setState(() => _manualSelection = true)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _titleController, decoration: _input('Exam title')),
          const SizedBox(height: 10),
          if (!_manualSelection) ...[
            TextField(
              controller: _questionCountController,
              keyboardType: TextInputType.number,
              decoration: _input('Question count'),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8E0EE)),
              ),
              child: Text(
                'Selected questions: ${_selectedQuestionIds.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: _input('Duration in minutes'),
          ),
          if (!_manualSelection) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _tagFilterController,
              onChanged: (_) => setState(() {}),
              decoration: _input('Tag filter (optional, e.g. SQL)'),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _selectedQuestionIds.clear();
                    for (final q in _bankQuestions) {
                      _selectedQuestionIds.add(q.id);
                    }
                  }),
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedQuestionIds.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            ..._bankQuestions.map(
              (q) => CheckboxListTile(
                value: _selectedQuestionIds.contains(q.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedQuestionIds.add(q.id);
                    } else {
                      _selectedQuestionIds.remove(q.id);
                    }
                  });
                },
                title: Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('Difficulty: ${q.difficulty} • Tags: ${q.tags.join(', ')}'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _pickDate(isStart: true),
            child: InputDecorator(
              decoration: _input('Start date'),
              child: Text('${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickTime(isStart: true),
            child: InputDecorator(
              decoration: _input('Start time'),
              child: Text(_startTime.format(context)),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _pickDate(isStart: false),
            child: InputDecorator(
              decoration: _input('End date'),
              child: Text('${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickTime(isStart: false),
            child: InputDecorator(
              decoration: _input('End time'),
              child: Text(_endTime.format(context)),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _saving ? null : _createExam,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29449B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.quiz_outlined),
            label: const Text('Create MCQ Exam', style: TextStyle(fontWeight: FontWeight.w700)),
          )
        ],
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
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

  Widget _modeChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF29449B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF2D3D5C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
