import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/course_model.dart';
import '../../models/lecture_qa_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/lecture_qa_service.dart';

class CourseForumScreen extends StatefulWidget {
  const CourseForumScreen({Key? key}) : super(key: key);

  @override
  State<CourseForumScreen> createState() => _CourseForumScreenState();
}

enum _ForumFilter { all, unanswered, resolved }

class _CourseForumScreenState extends State<CourseForumScreen> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();
  final QAService _qaService = QAService();
  final TextEditingController _searchController = TextEditingController();

  User? _me;
  List<Course> _courses = const [];
  String? _selectedCourseId;
  _ForumFilter _filter = _ForumFilter.all;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      return;
    }

    final me = await _authService.getUserInfo(firebaseUser.uid);
    if (me == null) {
      return;
    }

    List<Course> courses;
    if (me.role == 'teacher') {
      courses = await _courseService.getTeacherCourses(me.uid);
    } else if (me.role == 'student') {
      courses = await _courseService.getEnrolledCourses(me.uid);
    } else {
      courses = await _courseService.getAllCourses();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _me = me;
      _courses = courses;
      _selectedCourseId = courses.isNotEmpty ? courses.first.id : null;
    });
  }

  Future<void> _openCreatePost() async {
    if (_selectedCourseId == null || _me == null) {
      return;
    }

    Course? selectedCourse;
    for (final course in _courses) {
      if (course.id == _selectedCourseId) {
        selectedCourse = course;
        break;
      }
    }
    if (selectedCourse == null) {
      return;
    }
    final courseForPost = selectedCourse;

    final result = await Get.to<String?>(
      () => _CreatePostScreen(course: courseForPost, currentUser: _me!),
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    final created = await _qaService.getQuestionById(result);
    if (!mounted) {
      return;
    }

    setState(() {
      _filter = _ForumFilter.all;
      _searchController.clear();
      _selectedCourseId = courseForPost.id;
    });

    if (created != null) {
      Get.to(() => CourseForumThreadScreen(currentUser: _me!, question: created));
    } else {
      Get.snackbar('Warning', 'Post was created, but list refresh is delayed. Please reopen Forum.');
    }
  }

  List<Question> _applyLocalFilters(List<Question> questions) {
    final query = _searchController.text.trim().toLowerCase();

    return questions.where((q) {
      final filterPass = switch (_filter) {
        _ForumFilter.all => true,
        _ForumFilter.unanswered => q.answerCount == 0,
        _ForumFilter.resolved => q.isResolved,
      };

      if (!filterPass) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final inTitle = q.title.toLowerCase().contains(query);
      final inDesc = q.description.toLowerCase().contains(query);
      final inTags = q.tags.any((tag) => tag.toLowerCase().contains(query));
      return inTitle || inDesc || inTags;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCourseId = _selectedCourseId;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      floatingActionButton: selectedCourseId == null
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFF2748A9),
              onPressed: _openCreatePost,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: _me == null
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No courses found for forum access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6E7891), fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedCourseId,
                            decoration: InputDecoration(
                              labelText: 'Course Forum',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFDCE1EE)),
                              ),
                            ),
                            items: _courses
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c.id,
                                    child: Text(c.code.isNotEmpty ? '${c.code}: ${c.name}' : c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() => _selectedCourseId = value),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search questions...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: const Color(0xFFE7EBF3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _FilterChip(
                                label: 'All',
                                selected: _filter == _ForumFilter.all,
                                onTap: () => setState(() => _filter = _ForumFilter.all),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Unanswered',
                                selected: _filter == _ForumFilter.unanswered,
                                onTap: () => setState(() => _filter = _ForumFilter.unanswered),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Resolved',
                                selected: _filter == _ForumFilter.resolved,
                                onTap: () => setState(() => _filter = _ForumFilter.resolved),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Question>>(
                        stream: _qaService.streamQuestionsByCourse(selectedCourseId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Failed to load forum posts. Please refresh and try again.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF6E7891), fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          }

                          final filtered = _applyLocalFilters(snapshot.data ?? const []);
                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                'No forum posts found for this filter.',
                                style: TextStyle(color: Color(0xFF6E7891), fontWeight: FontWeight.w600),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final question = filtered[index];
                              return _QuestionCard(
                                question: question,
                                onTap: () => Get.to(
                                  () => CourseForumThreadScreen(currentUser: _me!, question: question),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class CourseForumThreadScreen extends StatefulWidget {
  const CourseForumThreadScreen({Key? key, required this.currentUser, required this.question}) : super(key: key);

  final User currentUser;
  final Question question;

  @override
  State<CourseForumThreadScreen> createState() => _CourseForumThreadScreenState();
}

class _CourseForumThreadScreenState extends State<CourseForumThreadScreen> {
  final QAService _qaService = QAService();
  final TextEditingController _replyController = TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_sending) {
      return;
    }

    final content = _replyController.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() => _sending = true);

    final answer = Answer(
      id: '',
      questionId: widget.question.id,
      userId: widget.currentUser.uid,
      userName: widget.currentUser.fullName,
      userRole: widget.currentUser.role,
      content: content,
      createdAt: DateTime.now(),
    );

    final result = await _qaService.postAnswer(answer);
    if (!mounted) {
      return;
    }

    setState(() => _sending = false);

    if (result != null) {
      _replyController.clear();
      Get.snackbar('Success', 'Reply posted');
    } else {
      Get.snackbar('Error', 'Failed to post reply');
    }
  }

  Future<void> _toggleResolved(bool nextState) async {
    final ok = await _qaService.markQuestionResolved(widget.question.id, resolved: nextState);
    if (ok) {
      Get.snackbar('Updated', nextState ? 'Marked as resolved' : 'Marked as unresolved');
      setState(() {
        // Local UI hint until stream refreshes.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.currentUser.uid == widget.question.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: const Text('Forum Thread'),
        backgroundColor: const Color(0xFFF3F5F9),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: _QuestionThreadHeader(
              question: widget.question,
              isOwner: isOwner,
              onToggleResolved: _toggleResolved,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Answer>>(
              stream: _qaService.streamAnswersByQuestion(widget.question.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final answers = snapshot.data ?? const [];
                if (answers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No replies yet. Be the first to answer.',
                      style: TextStyle(color: Color(0xFF6E7891), fontWeight: FontWeight.w600),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  itemCount: answers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final answer = answers[index];
                    return _AnswerCard(answer: answer);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        filled: true,
                        fillColor: const Color(0xFFE7EBF3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF2748A9),
                    child: IconButton(
                      onPressed: _sending ? null : _sendReply,
                      icon: _sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePostScreen extends StatefulWidget {
  const _CreatePostScreen({required this.course, required this.currentUser});

  final Course course;
  final User currentUser;

  @override
  State<_CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<_CreatePostScreen> {
  final QAService _qaService = QAService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  bool _isUrgent = false;
  bool _isAnonymous = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      Get.snackbar('Validation', 'Title and description are required');
      return;
    }

    setState(() => _saving = true);

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final question = Question(
      id: '',
      courseId: widget.course.id,
      courseName: widget.course.code.isNotEmpty ? '${widget.course.code}: ${widget.course.name}' : widget.course.name,
      userId: widget.currentUser.uid,
      userName: _isAnonymous ? 'Anonymous' : widget.currentUser.fullName,
      userRole: widget.currentUser.role,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      answerCount: 0,
      isResolved: false,
      isUrgent: _isUrgent,
      isAnonymous: _isAnonymous,
      tags: tags,
    );

    final id = await _qaService.postQuestion(question);
    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (id != null) {
      Get.back(result: id);
      Get.snackbar('Success', 'Post created successfully');
    } else {
      Get.snackbar('Error', 'Failed to create post');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: const Color(0xFFF3F5F9),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2748A9),
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E9F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Posting in: ${widget.course.code.isNotEmpty ? widget.course.code : widget.course.name}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF243A79)),
            ),
          ),
          const SizedBox(height: 18),
          _inputLabel('Title'),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: _fieldDecoration('Enter a descriptive title'),
          ),
          const SizedBox(height: 14),
          _inputLabel('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            minLines: 6,
            maxLines: 8,
            decoration: _fieldDecoration('Explain your question or share your thoughts...'),
          ),
          const SizedBox(height: 14),
          _inputLabel('Tags (comma separated)'),
          const SizedBox(height: 8),
          TextField(
            controller: _tagsController,
            decoration: _fieldDecoration('indexing, joins, recursion'),
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            value: _isUrgent,
            activeThumbColor: const Color(0xFF2748A9),
            title: const Text('Mark as Urgent', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Highlights this post for faster response'),
            onChanged: (value) => setState(() => _isUrgent = value),
          ),
          const Divider(height: 14),
          SwitchListTile.adaptive(
            value: _isAnonymous,
            activeThumbColor: const Color(0xFF2748A9),
            title: const Text('Post Anonymously', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Your name will be hidden from peers'),
            onChanged: (value) => setState(() => _isAnonymous = value),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFE7EBF3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF25304A),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.onTap});

  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tag = question.isResolved
        ? const _StateTag(label: 'Resolved', color: Color(0xFFD5F4E4), textColor: Color(0xFF0F7E4E), icon: Icons.check_circle)
        : question.answerCount == 0
            ? const _StateTag(label: 'Unanswered', color: Color(0xFFFFEED1), textColor: Color(0xFF8B5C09), icon: Icons.pending)
            : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE2EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (tag != null) tag,
                if (question.isUrgent) ...[
                  if (tag != null) const SizedBox(width: 8),
                  const _StateTag(
                    label: 'Urgent',
                    color: Color(0xFFFFE2E0),
                    textColor: Color(0xFFB4251B),
                    icon: Icons.priority_high,
                  ),
                ],
                const Spacer(),
                Text(_relativeTime(question.lastActivityAt), style: const TextStyle(color: Color(0xFF8390AB), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.title,
              style: const TextStyle(
                fontSize: 20,
                height: 1.2,
                color: Color(0xFF162038),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: Color(0xFF3E4D6B), height: 1.35),
            ),
            if (question.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: question.tags
                    .take(3)
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF1F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('#$e', style: const TextStyle(color: Color(0xFF526082), fontWeight: FontWeight.w700)),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Color(0xFF5E6C8D)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    question.userName,
                    style: const TextStyle(color: Color(0xFF2C3854), fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.mode_comment_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${question.answerCount}', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionThreadHeader extends StatelessWidget {
  const _QuestionThreadHeader({
    required this.question,
    required this.isOwner,
    required this.onToggleResolved,
  });

  final Question question;
  final bool isOwner;
  final ValueChanged<bool> onToggleResolved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE2EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question.courseName,
                  style: const TextStyle(color: Color(0xFF2E4CA1), fontWeight: FontWeight.w700),
                ),
              ),
              if (question.isResolved)
                const _StateTag(label: 'Resolved', color: Color(0xFFD5F4E4), textColor: Color(0xFF0F7E4E), icon: Icons.check_circle),
              if (isOwner) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => onToggleResolved(!question.isResolved),
                  icon: Icon(question.isResolved ? Icons.undo : Icons.task_alt, size: 18),
                  label: Text(question.isResolved ? 'Reopen' : 'Mark Resolved'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(question.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF172039))),
          const SizedBox(height: 8),
          Text(question.description, style: const TextStyle(fontSize: 18, color: Color(0xFF33425E), height: 1.35)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: Color(0xFF6B7893)),
              const SizedBox(width: 4),
              Text(question.userName, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C3754))),
              const SizedBox(width: 10),
              Text(_relativeTime(question.createdAt), style: const TextStyle(color: Color(0xFF8B96AF))),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer});

  final Answer answer;

  @override
  Widget build(BuildContext context) {
    final isTeacher = answer.userRole == 'teacher';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTeacher ? const Color(0xFFF3F5FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8DFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(answer.userName, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C2742))),
              if (isTeacher) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2445A4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('TEACHER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              Text(_relativeTime(answer.createdAt), style: const TextStyle(color: Color(0xFF8390AB))),
            ],
          ),
          const SizedBox(height: 8),
          Text(answer.content, style: const TextStyle(fontSize: 16, height: 1.35, color: Color(0xFF303F5F))),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2445A4) : const Color(0xFFE7EBF3),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF3E4C68),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StateTag extends StatelessWidget {
  const _StateTag({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays == 1) {
    return 'Yesterday';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  return '${time.day}/${time.month}/${time.year}';
}
