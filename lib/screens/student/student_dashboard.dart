import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import '../../models/lecture_qa_model.dart';
import '../../models/exam_system_model.dart';
import '../../screens/student/student_assignments_screen.dart';
import '../../screens/student/student_exams_screen.dart';
import '../../screens/student/profile_settings_screen.dart';
import '../../screens/shared/course_forum_screen.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/exam_system_service.dart';
import '../../services/lecture_qa_service.dart';
import '../../services/student_dashboard_service.dart';
//import '../../models/user_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);


  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF2F4F8);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        toolbarHeight: 74,
        titleSpacing: 16,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFDCE3EF),
              child: Icon(Icons.person, color: Color(0xFF334A78)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Student Portal',
                style: TextStyle(
                  color: Color(0xFF17203A),
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                ),
              ),
            ),
            _iconPill(Icons.search_rounded),
            const SizedBox(width: 10),
            Stack(
              children: [
                _iconPill(Icons.notifications_none_rounded),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF8A97B2)),
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
          HomeTab(),
          CoursesTab(),
          AssignmentsTab(),
          ExamsTab(),
          QAForumTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 74,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE9EEFF),
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Courses'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz), label: 'Exams'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Forum'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _iconPill(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF6),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Icon(icon, color: const Color(0xFF29449B)),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final AuthService _authService = AuthService();
  final StudentDashboardService _dashboardService = StudentDashboardService();
  late Future<StudentDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<StudentDashboardData> _loadDashboard() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return _dashboardService.fetchDashboardData(user.uid);
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentDashboardData>(
      future: _dashboardFuture,
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load dashboard data',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF7C89A4), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            children: [
              _welcomeCard(data.studentName, data.facultyName),
              const SizedBox(height: 14),
              _statCard(
                title: 'Enrolled Courses',
                value: data.enrolledCourses.toString(),
                subtitle: '+${data.newlyEnrolledCourses} new',
                subtitleColor: const Color(0xFF00A46C),
                icon: Icons.bookmark_outline,
                iconColor: const Color(0xFF29449B),
              ),
              const SizedBox(height: 12),
              _statCard(
                title: 'Upcoming Exams',
                value: data.upcomingExams.toString(),
                subtitle: data.upcomingExamHint,
                subtitleColor: const Color(0xFF6A7896),
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFFD98913),
              ),
              const SizedBox(height: 12),
              _statCard(
                title: 'Pending Assignments',
                value: data.pendingAssignments.toString(),
                subtitle: '${data.overdueAssignments} overdue',
                subtitleColor:
                    data.overdueAssignments > 0 ? const Color(0xFFE11D48) : const Color(0xFF6A7896),
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFFE11D48),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF182033),
                    ),
                  ),
                  Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF29449B),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (data.activities.isEmpty)
                _emptyActivityCard()
              else
                ...data.activities.map((activity) => _activityCard(activity)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _welcomeCard(String studentName, String facultyName) {
    final firstName = studentName.trim().isEmpty ? 'Student' : studentName.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF29449B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: Color(0xFF4A6CB8),
            child: Icon(Icons.person, size: 44, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,\n$firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  facultyName,
                  style: const TextStyle(
                    color: Color(0xFFD8E1FF),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6A7896),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF182033),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }

  Widget _emptyActivityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        'No recent activity yet. Start by enrolling in a course or submitting an assignment.',
        style: TextStyle(color: Color(0xFF6A7896), fontSize: 16),
      ),
    );
  }

  Widget _activityCard(DashboardActivity activity) {
    final meta = _activityMeta(activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: meta.bgColor, borderRadius: BorderRadius.circular(23)),
            child: Icon(meta.icon, color: meta.iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: Color(0xFF182033),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: const TextStyle(color: Color(0xFF6A7896), fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(activity.timestamp),
                  style: const TextStyle(
                    color: Color(0xFF8E9AB5),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  _ActivityMeta _activityMeta(String type) {
    switch (type) {
      case 'submission':
        return const _ActivityMeta(
          icon: Icons.check_circle_outline,
          iconColor: Color(0xFF00A46C),
          bgColor: Color(0xFFE8F7F0),
        );
      case 'resource':
        return const _ActivityMeta(
          icon: Icons.insert_drive_file_outlined,
          iconColor: Color(0xFF29449B),
          bgColor: Color(0xFFEEF2FB),
        );
      case 'forum':
        return const _ActivityMeta(
          icon: Icons.forum_outlined,
          iconColor: Color(0xFFD98913),
          bgColor: Color(0xFFF8F2E6),
        );
      default:
        return const _ActivityMeta(
          icon: Icons.school_outlined,
          iconColor: Color(0xFF7D8CA6),
          bgColor: Color(0xFFF0F3F8),
        );
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'JUST NOW';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} MIN AGO';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} HOUR${diff.inHours == 1 ? '' : 'S'} AGO';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} DAY${diff.inDays == 1 ? '' : 'S'} AGO';
    }
    return 'OLDER';
  }
}

class _ActivityMeta {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _ActivityMeta({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class CoursesTab extends StatefulWidget {
  const CoursesTab({Key? key}) : super(key: key);

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();
  final AssignmentService _assignmentService = AssignmentService();
  late Future<_StudentCoursesData> _coursesFuture;
  String _query = '';
  bool _showDiscover = false;
  String? _selectedFaculty;
  String? _selectedDepartment;
  String? _enrollingCourseId;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadCourses();
  }

  Future<_StudentCoursesData> _loadCourses() async {
    final user = _authService.currentUser;
    if (user == null) {
      return const _StudentCoursesData(enrolled: [], discover: []);
    }

    final enrolledCourses = await _courseService.getEnrolledCourses(user.uid);
    final allCourses = await _courseService.getAllCourses();
    final enrolledIds = enrolledCourses.map((e) => e.id).toSet();

    final submissions = await _assignmentService.getStudentSubmissions(user.uid);
    final submissionIds = submissions.map((s) => s.assignmentId).toSet();

    // Fetch teacher full names (teacherId -> users.fullName) to show correct UI names
    final teacherIds = <String>{
      for (final c in enrolledCourses) c.teacherId,
      for (final c in allCourses.where((c) => c.isPublic && !enrolledIds.contains(c.id))) c.teacherId,
    }..removeWhere((id) => id.trim().isEmpty);

    final authService = AuthService();
    final teacherNameById = <String, String>{};
    for (final tid in teacherIds) {
      final user = await authService.getUserInfo(tid);
      teacherNameById[tid] = (user?.fullName.trim().isNotEmpty == true) ? user!.fullName.trim() : 'Unknown';
    }

    final enrolled = <_StudentCourseCardVm>[];
    for (final course in enrolledCourses) {
      final assignments = await _assignmentService.getAssignmentsByCourse(course.id);
      final assignmentIds = assignments.map((a) => a.id).toSet();
      final submittedCount = submissionIds.where((id) => assignmentIds.contains(id)).length;
      final total = assignments.length;
      final progress = total == 0 ? 0 : ((submittedCount / total) * 100).round();

      final teacherFullName = teacherNameById[course.teacherId] ?? 'Unknown';
      enrolled.add(
        _StudentCourseCardVm(
          course: course,
          progress: progress,
          teacherName: '{$teacherFullName}',
        ),
      );
    }

    final discover = allCourses
        .where((course) => course.isPublic && !enrolledIds.contains(course.id))
        .map(
          (course) => _CourseDiscoverVm(
            course: course,
            teacherName: '${teacherNameById[course.teacherId] ?? 'Unknown'} ',
          ),
        )
        .toList();

    return _StudentCoursesData(enrolled: enrolled, discover: discover);

  }

  Future<void> _enrollCourse(Course course) async {
    if (_enrollingCourseId != null) {
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _enrollingCourseId = course.id);
    final ok = await _courseService.enrollStudentInCourse(course.id, user.uid);
    if (!mounted) {
      return;
    }

    setState(() {
      _enrollingCourseId = null;
      if (ok) {
        _showDiscover = false;
        _coursesFuture = _loadCourses();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Enrolled successfully' : 'Enrollment failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StudentCoursesData>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? const _StudentCoursesData(enrolled: [], discover: []);
        final lowerQuery = _query.toLowerCase();
        final enrolledFiltered = data.enrolled
            .where((c) => c.course.name.toLowerCase().contains(lowerQuery))
            .toList();
        final discoverFilteredByText = data.discover
            .where((c) => c.course.name.toLowerCase().contains(lowerQuery))
            .toList();

        final discoverFaculties = discoverFilteredByText
            .map((c) => c.course.faculty.trim())
            .where((f) => f.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        if (_selectedFaculty != null && !discoverFaculties.contains(_selectedFaculty)) {
          _selectedFaculty = null;
          _selectedDepartment = null;
        }

        final discoverDepartments = discoverFilteredByText
            .where((c) => _selectedFaculty == null || c.course.faculty == _selectedFaculty)
            .map((c) => c.course.department.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        if (_selectedDepartment != null && !discoverDepartments.contains(_selectedDepartment)) {
          _selectedDepartment = null;
        }

        final discoverFiltered = discoverFilteredByText.where((c) {
          final byFaculty = _selectedFaculty == null || c.course.faculty == _selectedFaculty;
          final byDepartment = _selectedDepartment == null || c.course.department == _selectedDepartment;
          return byFaculty && byDepartment;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _coursesFuture = _loadCourses());
            await _coursesFuture;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: _showDiscover ? 'Search available courses...' : 'Search your courses...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Enrolled'),
                    selected: !_showDiscover,
                    onSelected: (_) => setState(() {
                      _showDiscover = false;
                      _selectedFaculty = null;
                      _selectedDepartment = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Discover'),
                    selected: _showDiscover,
                    onSelected: (_) => setState(() => _showDiscover = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_showDiscover) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD8E0EE)),
                  ),
                  child: DropdownButton<String?>(
                    value: _selectedFaculty,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: const Text('Filter by faculty'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Faculties')),
                      ...discoverFaculties.map((f) => DropdownMenuItem<String?>(value: f, child: Text(f))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFaculty = value;
                        _selectedDepartment = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD8E0EE)),
                  ),
                  child: DropdownButton<String?>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: const Text('Filter by department'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Departments')),
                      ...discoverDepartments.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d))),
                    ],
                    onChanged: (value) => setState(() => _selectedDepartment = value),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!_showDiscover && enrolledFiltered.isEmpty)
                const _EmptyBox(text: 'No enrolled course matches your search')
              else if (_showDiscover && discoverFiltered.isEmpty)
                const _EmptyBox(text: 'No available course found for enrollment')
              else if (!_showDiscover)
                ...enrolledFiltered.map((item) => _courseCard(context, item))
              else
                ...discoverFiltered.map((item) => _discoverCourseCard(item)),
            ],
          ),
        );
      },
    );
  }

  Widget _courseCard(BuildContext context, _StudentCourseCardVm item) {
    final isStarted = item.progress > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF29449B),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: item.course.bannerImageUrl != null && item.course.bannerImageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(item.course.bannerImageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF29449B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('ENROLLED', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.course.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF17203A))),
                const SizedBox(height: 2),
                Text(item.teacherName, style: const TextStyle(color: Color(0xFF7A88A6))),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Course Progress', style: TextStyle(color: Color(0xFF657492), fontWeight: FontWeight.w600)),
                    Text('${item.progress}%', style: const TextStyle(color: Color(0xFF29449B), fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: item.progress / 100,
                    backgroundColor: const Color(0xFFE5EAF4),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF29449B)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => CourseDetailScreen(course: item.course, progress: item.progress)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isStarted ? const Color(0xFF29449B) : const Color(0xFFE9EDF6),
                      foregroundColor: isStarted ? Colors.white : const Color(0xFF29449B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(isStarted ? 'Resume Learning' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _discoverCourseCard(_CourseDiscoverVm item) {
    final isBusy = _enrollingCourseId == item.course.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.course.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF17203A))),
            const SizedBox(height: 4),
            Text(item.teacherName, style: const TextStyle(color: Color(0xFF7A88A6))),
            const SizedBox(height: 2),
            Text(item.course.department, style: const TextStyle(color: Color(0xFF7A88A6))),
            const SizedBox(height: 10),
            Text(
              item.course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF4A5876), height: 1.35),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enrollingCourseId == null ? () => _enrollCourse(item.course) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29449B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enroll Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final int progress;

  const CourseDetailScreen({Key? key, required this.course, required this.progress}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _selectedTab = 0;
  final LectureService _lectureService = LectureService();
  final AssignmentService _assignmentService = AssignmentService();
  final ExamSystemService _examSystemService = ExamSystemService();
  final AuthService _authService = AuthService();
  late Future<List<Lecture>> _lecturesFuture;
  late Future<List<Assignment>> _assignmentsFuture;
  late Future<List<McqExam>> _examsFuture;

  final List<String> _tabs = const ['Overview', 'Materials', 'Assignments', 'Exams'];

  @override
  void initState() {
    super.initState();
    _lecturesFuture = _lectureService.getLecturesByCourse(widget.course.id);
    _assignmentsFuture = _assignmentService.getAssignmentsByCourse(widget.course.id);
    _examsFuture = _loadExamsByCourse();
  }

  Future<List<McqExam>> _loadExamsByCourse() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return [];
    }
    return _examSystemService.getStudentExamsByCourse(uid, widget.course.id);
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Text(widget.course.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final selected = _selectedTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 18),
                      padding: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? const Color(0xFF29449B) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          color: selected ? const Color(0xFF29449B) : const Color(0xFF6C7A98),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF29449B),
                borderRadius: BorderRadius.circular(18),
                image: widget.course.bannerImageUrl != null && widget.course.bannerImageUrl!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(widget.course.bannerImageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${widget.course.code.isEmpty ? 'N/A' : widget.course.code} • ${widget.course.department}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedTab == 0) ...[
              const Text('Course Description', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF29449B))),
              const SizedBox(height: 10),
              Text(widget.course.description, style: const TextStyle(fontSize: 17, height: 1.55, color: Color(0xFF263754))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Learning Objectives', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF29449B))),
                    const SizedBox(height: 10),
                    ...((widget.course.learningObjectives.isEmpty
                            ? const [
                                'Understand core topics of this course.',
                                'Apply concepts through practical assignments.',
                                'Prepare for exams and project work.',
                              ]
                            : widget.course.learningObjectives)
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF29449B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(item, style: const TextStyle(color: Color(0xFF2E3C58)))),
                                ],
                              ),
                            )))
                        .toList(),
                  ],
                ),
              ),
            ] else if (_selectedTab == 1) ...[
              _materialBox(widget.course.syllabusUrl),
            ] else if (_selectedTab == 2) ...[
              _assignmentSummary(),
            ] else ...[
              _examSummary(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _materialBox(String? syllabusUrl) {
    return FutureBuilder<List<Lecture>>(
      future: _lecturesFuture,
      builder: (context, snapshot) {
        final lectures = snapshot.data ?? const [];
        final noSyllabus = syllabusUrl == null || syllabusUrl.isEmpty;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (noSyllabus && lectures.isEmpty) {
          return const _EmptyBox(text: 'No syllabus/material uploaded yet');
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!noSyllabus) ...[
                const Text('Syllabus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _openExternalUrl(syllabusUrl),
                  child: Text(
                    syllabusUrl,
                    style: const TextStyle(
                      color: Color(0xFF29449B),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text('Lectures', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              if (lectures.isEmpty)
                const Text('No lectures uploaded yet', style: TextStyle(color: Color(0xFF6C7A98)))
              else
                ...lectures.map(
                  (l) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l.lectureOrder}. ${l.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF17203A)),
                        ),
                        const SizedBox(height: 4),
                        Text(l.description, style: const TextStyle(color: Color(0xFF4A5876))),
                        if ((l.pdfUrl ?? '').isNotEmpty || (l.videoUrl ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          if ((l.pdfUrl ?? '').isNotEmpty)
                            InkWell(
                              onTap: () => _openExternalUrl(l.pdfUrl!),
                              child: const Text(
                                'Open PDF Material',
                                style: TextStyle(
                                  color: Color(0xFF29449B),
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          if ((l.videoUrl ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: InkWell(
                                onTap: () => _openExternalUrl(l.videoUrl!),
                                child: const Text(
                                  'Open Video Link',
                                  style: TextStyle(
                                    color: Color(0xFF29449B),
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _assignmentSummary() {
    return FutureBuilder<List<Assignment>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = snapshot.data ?? const <Assignment>[];
        if (assignments.isEmpty) {
          return const _EmptyBox(text: 'No assignment published yet');
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total assignments: ${assignments.length}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 10),
              ...assignments.map(
                (a) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentAssignmentsScreen(
                          initialCourseId: widget.course.id,
                          initialAssignmentId: a.id,
                          openAssignmentOnLoad: true,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF17203A))),
                        const SizedBox(height: 4),
                        Text('Due: ${a.dueDate.day}/${a.dueDate.month}/${a.dueDate.year}', style: const TextStyle(color: Color(0xFF4A5876))),
                        if (a.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            a.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF4A5876)),
                          ),
                        ],
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.open_in_new, size: 14, color: Color(0xFF29449B)),
                            SizedBox(width: 6),
                            Text(
                              'Open details & submit',
                              style: TextStyle(
                                color: Color(0xFF29449B),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _examSummary() {
    return FutureBuilder<List<McqExam>>(
      future: _examsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final exams = snapshot.data ?? const <McqExam>[];
        if (exams.isEmpty) {
          return const _EmptyBox(text: 'No exam scheduled for this course yet');
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: exams
                .map(
                  (exam) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF17203A))),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${exam.startAt.day}/${exam.startAt.month}/${exam.startAt.year} • ${exam.durationMinutes} mins • ${exam.questionIds.length} MCQ',
                          style: const TextStyle(color: Color(0xFF4A5876)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _StudentCourseCardVm {
  final Course course;
  final int progress;
  final String teacherName;

  const _StudentCourseCardVm({
    required this.course,
    required this.progress,
    required this.teacherName,
  });
}

class _CourseDiscoverVm {
  final Course course;
  final String teacherName;

  const _CourseDiscoverVm({
    required this.course,
    required this.teacherName,
  });
}

class _StudentCoursesData {
  final List<_StudentCourseCardVm> enrolled;
  final List<_CourseDiscoverVm> discover;

  const _StudentCoursesData({
    required this.enrolled,
    required this.discover,
  });
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF6C7A98))),
    );
  }
}

class AssignmentsTab extends StatelessWidget {
  const AssignmentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const StudentAssignmentsScreen();
  }
}

class ExamsTab extends StatelessWidget {
  const ExamsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const StudentExamsScreen();
  }
}

class QAForumTab extends StatelessWidget {
  const QAForumTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CourseForumScreen();
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProfileSettingsScreen();
  }
}
