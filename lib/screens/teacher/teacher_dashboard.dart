import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import '../../models/faculty_department_model.dart';
import '../../models/user_model.dart';
import '../../screens/student/profile_settings_screen.dart';
import '../../screens/shared/course_forum_screen.dart';
import '../../screens/teacher/teacher_create_assignment_screen.dart';
import '../../screens/teacher/teacher_manage_lectures_screen.dart';
import '../../screens/teacher/teacher_manage_assignments_screen.dart';
import '../../screens/teacher/teacher_question_bank_screen.dart';
import '../../screens/teacher/teacher_upload_lecture_screen.dart';
import '../../services/admin_service.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF2F5F8);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        toolbarHeight: 72,
        title: const Text(
          'Teacher Portal',
          style: TextStyle(
            color: Color(0xFF182033),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF8796B4)),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () => _authService.signOut(),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          TeacherOverviewTab(),
          TeacherCoursesTab(),
          TeacherQuestionBankScreen(),
          CourseForumScreen(),
          EvaluateSubmissionsTab(),
          ProfileSettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 74,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE7EDFF),
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Courses'),
          NavigationDestination(icon: Icon(Icons.help_center_outlined), selectedIcon: Icon(Icons.help_center), label: 'Questions'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Forum'),
          NavigationDestination(icon: Icon(Icons.rule_folder_outlined), selectedIcon: Icon(Icons.rule_folder), label: 'Evaluate'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class TeacherOverviewTab extends StatefulWidget {
  const TeacherOverviewTab({Key? key}) : super(key: key);

  @override
  State<TeacherOverviewTab> createState() => _TeacherOverviewTabState();
}

class _TeacherOverviewTabState extends State<TeacherOverviewTab> {
  final _authService = AuthService();
  final _courseService = CourseService();
  final _assignmentService = AssignmentService();

  late Future<_TeacherOverviewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_TeacherOverviewData> _load() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final teacherCourses = await _courseService.getTeacherCourses(user.uid);
    var assignmentCount = 0;
    var pendingEvaluation = 0;
    final recentAssignments = <_AssignmentWithCourse>[];

    for (final course in teacherCourses) {
      final assignments = await _assignmentService.getAssignmentsByCourse(course.id);
      assignmentCount += assignments.length;

      for (final assignment in assignments) {
        recentAssignments.add(_AssignmentWithCourse(assignment: assignment, courseName: course.name));

        final submissions = await _assignmentService.getSubmissionsByAssignment(assignment.id);
        pendingEvaluation += submissions.where((s) => !s.isEvaluated).length;
      }
    }

    recentAssignments.sort((a, b) => b.assignment.createdAt.compareTo(a.assignment.createdAt));

    return _TeacherOverviewData(
      teacherName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? 'Teacher'),
      coursesCount: teacherCourses.length,
      assignmentsCount: assignmentCount,
      pendingEvaluationCount: pendingEvaluation,
      recentAssignments: recentAssignments.take(5).toList(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _load();
    });
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TeacherOverviewData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 44),
                  const SizedBox(height: 10),
                  const Text('Failed to load teacher dashboard'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No dashboard data'));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F4AA0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${data.teacherName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track courses, publish assignments, and evaluate submissions.',
                      style: TextStyle(color: Color(0xFFDCE5FF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _metricCard('My Courses', data.coursesCount.toString(), Icons.menu_book_rounded, const Color(0xFF2F4AA0)),
              const SizedBox(height: 10),
              _metricCard('Assignments', data.assignmentsCount.toString(), Icons.assignment_outlined, const Color(0xFF0BAA60)),
              const SizedBox(height: 10),
              _metricCard('Pending Evaluation', data.pendingEvaluationCount.toString(), Icons.rule_rounded, const Color(0xFFE67E22)),
              const SizedBox(height: 18),
              const Text(
                'Recently Created Assignments',
                style: TextStyle(
                  color: Color(0xFF182033),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              if (data.recentAssignments.isEmpty)
                const _EmptyBox(text: 'No assignment created yet')
              else
                ...data.recentAssignments.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.assignment.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF182033)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.courseName,
                          style: const TextStyle(color: Color(0xFF6C7A98), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF6C7A98), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF182033))),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
        ],
      ),
    );
  }
}

class TeacherCoursesTab extends StatefulWidget {
  const TeacherCoursesTab({Key? key}) : super(key: key);

  @override
  State<TeacherCoursesTab> createState() => _TeacherCoursesTabState();
}

class _TeacherCoursesTabState extends State<TeacherCoursesTab> {
  final _courseService = CourseService();
  final _authService = AuthService();
  final _assignmentService = AssignmentService();

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please login again'));
    }

    return StreamBuilder<List<Course>>(
      stream: _courseService.streamTeacherCourses(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final courses = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherCreateCourseScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F4AA0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Course', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            Expanded(
              child: courses.isEmpty
                  ? const Center(child: Text('No course found for this teacher'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final c = courses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: FutureBuilder<int>(
                                  future: _assignmentService.getAssignmentsCountByCourse(c.id),
                                  builder: (context, countSnapshot) {
                                    final count = countSnapshot.data ?? c.totalAssignments;
                                    return Text('${c.department} • $count assignments');
                                  },
                                ),
                                trailing: Text('${c.totalLectures} L', style: const TextStyle(color: Color(0xFF6C7A98))),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherManageAssignmentsScreen(course: c),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => Get.to(() => const TeacherUploadLectureScreen()),
                                        icon: const Icon(Icons.upload_file_outlined, size: 16),
                                        label: const Text('Upload Material'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => Get.to(() => const TeacherManageLecturesScreen()),
                                        icon: const Icon(Icons.folder_open_outlined, size: 16),
                                        label: const Text('Manage Materials'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class TeacherCreateCourseScreen extends StatelessWidget {
  const TeacherCreateCourseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F8),
        elevation: 0,
        title: const Text(
          'Create Course',
          style: TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800),
        ),
      ),
      body: const CreateCourseTab(),
    );
  }
}

class CreateCourseTab extends StatefulWidget {
  const CreateCourseTab({Key? key}) : super(key: key);

  @override
  State<CreateCourseTab> createState() => _CreateCourseTabState();
}

class _CreateCourseTabState extends State<CreateCourseTab> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _overviewController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _syllabusController = TextEditingController();
  final _courseService = CourseService();
  final _authService = AuthService();
  final _adminService = AdminService();

  bool _saving = false;
  bool _publicAccess = true;
  String? _faculty;
  String? _department;
  String? _facultyId;
  List<FacultyItem> _faculties = const [];
  List<DepartmentItem> _departments = const [];
  bool _loadingAcademicData = true;
  final List<String> _objectives = [];

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  List<DepartmentItem> get _visibleDepartments {
    final fid = _facultyId;
    if (fid == null) {
      return const [];
    }
    return _departments.where((d) => d.facultyId == fid && d.isActive).toList();
  }

  Future<void> _loadAcademicData() async {
    final faculties = await _adminService.getFaculties(onlyActive: true);
    final departments = await _adminService.getDepartments(onlyActive: true);

    if (!mounted) {
      return;
    }

    if (faculties.isEmpty) {
      setState(() {
        _faculties = const [];
        _departments = const [];
        _faculty = null;
        _department = null;
        _facultyId = null;
        _loadingAcademicData = false;
      });
      return;
    }

    final selectedFaculty = faculties.first;
    final visibleDepartments = departments
        .where((d) => d.facultyId == selectedFaculty.id && d.isActive)
        .toList();

    setState(() {
      _faculties = faculties;
      _departments = departments;
      _facultyId = selectedFaculty.id;
      _faculty = selectedFaculty.name;
      _department = visibleDepartments.isNotEmpty ? visibleDepartments.first.name : null;
      _loadingAcademicData = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _overviewController.dispose();
    _objectiveController.dispose();
    _syllabusController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final teacherId = _authService.currentUser?.uid;
    if (teacherId == null) {
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _codeController.text.trim().isEmpty ||
        _overviewController.text.trim().isEmpty ||
        _faculty == null ||
        _department == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields first')));
      return;
    }

    setState(() => _saving = true);

    final course = Course(
      id: '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      description: _overviewController.text.trim(),
      teacherId: teacherId,
      faculty: _faculty!,
      department: _department!,
      isPublic: _publicAccess,
      syllabusUrl: _syllabusController.text.trim().isEmpty ? null : _syllabusController.text.trim(),
      learningObjectives: List<String>.from(_objectives),
      createdAt: DateTime.now(),
    );

    final id = await _courseService.createCourse(course);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create course')));
      return;
    }

    _nameController.clear();
    _codeController.clear();
    _overviewController.clear();
    _objectiveController.clear();
    _syllabusController.clear();
    setState(() {
      _objectives.clear();
      if (_faculties.isNotEmpty) {
        _facultyId = _faculties.first.id;
        _faculty = _faculties.first.name;
        final visibleDepartments = _visibleDepartments;
        _department = visibleDepartments.isNotEmpty ? visibleDepartments.first.name : null;
      } else {
        _facultyId = null;
        _faculty = null;
        _department = null;
      }
      _publicAccess = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course created successfully')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAcademicData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_faculties.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No faculty found. Please add faculty and department from admin dashboard first.'),
        ),
      );
    }

    final visibleDepartments = _visibleDepartments;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Create New Course',
          style: TextStyle(
            color: Color(0xFF182033),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration('Course name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _codeController,
          decoration: _inputDecoration('Course code (e.g. CS402)'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _facultyId,
          items: _faculties
              .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            final faculty = _faculties.firstWhere((f) => f.id == value);
            setState(() {
              _facultyId = value;
              _faculty = faculty.name;
              final nextDepartments = _visibleDepartments;
              _department = nextDepartments.isNotEmpty ? nextDepartments.first.name : null;
            });
          },
          decoration: _inputDecoration('Select Faculty'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _department,
          items: visibleDepartments
              .map((d) => DropdownMenuItem(value: d.name, child: Text(d.name)))
              .toList(),
          onChanged: (value) => setState(() => _department = value),
          decoration: _inputDecoration('Select Department'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _overviewController,
          minLines: 4,
          maxLines: 6,
          decoration: _inputDecoration('Course overview'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _objectiveController,
          decoration: _inputDecoration('Add learning objective'),
          onSubmitted: (value) {
            final v = value.trim();
            if (v.isEmpty) {
              return;
            }
            setState(() {
              _objectives.add(v);
              _objectiveController.clear();
            });
          },
        ),
        if (_objectives.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _objectives
                .asMap()
                .entries
                .map((entry) => Chip(
                      label: Text(entry.value),
                      onDeleted: () {
                        setState(() => _objectives.removeAt(entry.key));
                      },
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _syllabusController,
          decoration: _inputDecoration('Syllabus URL (optional)'),
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          value: _publicAccess,
          onChanged: (value) => setState(() => _publicAccess = value),
          title: const Text('Public Access', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Allow students to view this course'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _saving ? null : _create,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F4AA0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create Course', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Get.to(() => const TeacherCreateAssignmentScreen()),
          icon: const Icon(Icons.assignment_outlined),
          label: const Text('Go To Create Assignment'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Get.to(() => const TeacherUploadLectureScreen()),
          icon: const Icon(Icons.slideshow_outlined),
          label: const Text('Go To Upload Lecture'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Get.to(() => const TeacherManageLecturesScreen()),
          icon: const Icon(Icons.view_list_outlined),
          label: const Text('Go To Manage Lectures'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
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
        borderSide: const BorderSide(color: Color(0xFF2F4AA0), width: 1.2),
      ),
    );
  }
}

class EvaluateSubmissionsTab extends StatefulWidget {
  const EvaluateSubmissionsTab({Key? key}) : super(key: key);

  @override
  State<EvaluateSubmissionsTab> createState() => _EvaluateSubmissionsTabState();
}

class _EvaluateSubmissionsTabState extends State<EvaluateSubmissionsTab> {
  final _authService = AuthService();
  final _courseService = CourseService();
  final _assignmentService = AssignmentService();

  late Future<List<_SubmissionView>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _submissionsFuture = _load();
  }

  Future<List<_SubmissionView>> _load() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return [];
    }

    final courses = await _courseService.getTeacherCourses(uid);
    final views = <_SubmissionView>[];
    final userCache = <String, User?>{};

    for (final c in courses) {
      final assignments = await _assignmentService.getAssignmentsByCourse(c.id);
      for (final a in assignments) {
        final submissions = await _assignmentService.getSubmissionsByAssignment(a.id);
        for (final s in submissions) {
          User? student;
          if (userCache.containsKey(s.studentId)) {
            student = userCache[s.studentId];
          } else {
            student = await _authService.getUserInfo(s.studentId);
            userCache[s.studentId] = student;
          }

          views.add(
            _SubmissionView(
              course: c,
              assignment: a,
              submission: s,
              student: student,
            ),
          );
        }
      }
    }

    views.sort((a, b) => b.submission.submittedAt.compareTo(a.submission.submittedAt));
    return views;
  }

  Future<void> _refresh() async {
    setState(() => _submissionsFuture = _load());
    await _submissionsFuture;
  }

  Future<void> _openEvaluationDialog(_SubmissionView view) async {
    final marksController = TextEditingController(text: view.submission.marks ?? '');
    final feedbackController = TextEditingController(text: view.submission.feedback ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        var saving = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Evaluate Submission'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assignment: ${view.assignment.title}'),
                    const SizedBox(height: 4),
                    Text('Student: ${view.studentName}'),
                    const SizedBox(height: 2),
                    Text('Student ID: ${view.submission.studentId}'),
                    if (view.submission.fileUrl.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _openSubmissionFile(view.submission.fileUrl),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Open Submitted File'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: marksController,
                      decoration: const InputDecoration(labelText: 'Marks'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: feedbackController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Feedback'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (marksController.text.trim().isEmpty) {
                            return;
                          }
                          setStateDialog(() => saving = true);
                          final ok = await _assignmentService.evaluateSubmission(
                            view.submission.id,
                            marksController.text.trim(),
                            feedbackController.text.trim(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pop(context, ok);
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evaluation updated')));
      _refresh();
    }
  }

  Future<void> _openSubmissionFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid submission file URL')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open submission file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_SubmissionView>>(
      future: _submissionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final views = snapshot.data ?? [];
        if (views.isEmpty) {
          return const Center(child: Text('No submissions found yet'));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: views.length,
            itemBuilder: (context, index) {
              final v = views[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE7ECF7),
                    backgroundImage: (v.student?.photoUrl != null && v.student!.photoUrl!.isNotEmpty)
                        ? NetworkImage(v.student!.photoUrl!)
                        : null,
                    child: (v.student?.photoUrl == null || v.student!.photoUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 20, color: Color(0xFF4D5F85))
                        : null,
                  ),
                  title: Text(v.assignment.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${v.course.name}\nStudent: ${v.studentName}'),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: v.submission.isEvaluated
                          ? const Color(0xFFE8F7F0)
                          : const Color(0xFFFFF4E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      v.submission.isEvaluated ? 'Evaluated' : 'Pending',
                      style: TextStyle(
                        color: v.submission.isEvaluated
                            ? const Color(0xFF0BAA60)
                            : const Color(0xFFE67E22),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onTap: () => _openEvaluationDialog(v),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TeacherOverviewData {
  final String teacherName;
  final int coursesCount;
  final int assignmentsCount;
  final int pendingEvaluationCount;
  final List<_AssignmentWithCourse> recentAssignments;

  const _TeacherOverviewData({
    required this.teacherName,
    required this.coursesCount,
    required this.assignmentsCount,
    required this.pendingEvaluationCount,
    required this.recentAssignments,
  });
}

class _AssignmentWithCourse {
  final Assignment assignment;
  final String courseName;

  const _AssignmentWithCourse({required this.assignment, required this.courseName});
}

class _SubmissionView {
  final Course course;
  final Assignment assignment;
  final AssignmentSubmission submission;
  final User? student;

  String get studentName {
    final n = student?.fullName.trim() ?? '';
    return n.isEmpty ? submission.studentId : n;
  }

  const _SubmissionView({
    required this.course,
    required this.assignment,
    required this.submission,
    required this.student,
  });
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
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF6C7A98)),
      ),
    );
  }
}
