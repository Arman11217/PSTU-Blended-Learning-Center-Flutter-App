import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/course_model.dart';
import '../../models/faculty_department_model.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';

// Admin Dashboard - অ্যাডমিনদের জন্য ড্যাশবোর্ড
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        backgroundColor: const Color(0xFF2F4AA0),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () {
                  _authService.signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          OverviewTab(),
          ManageUsersTab(),
          ManageCoursesTab(),
          AdminProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

// Overview Tab - সিস্টেম ওভারভিউ
class OverviewTab extends StatefulWidget {
  const OverviewTab({Key? key}) : super(key: key);

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final AdminService _adminService = AdminService();
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _adminService.getSystemStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? const {};

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _statsFuture = _adminService.getSystemStatistics();
            });
            await _statsFuture;
          },
          child: ListView(
            padding: const EdgeInsets.all(15),
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Users',
                      count: '${stats['totalUsers'] ?? 0}',
                      color: Colors.blue,
                      icon: Icons.people,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Active Courses',
                      count: '${stats['activeCourses'] ?? 0}',
                      color: Colors.green,
                      icon: Icons.book,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Assignments',
                      count: '${stats['assignments'] ?? 0}',
                      color: Colors.orange,
                      icon: Icons.assignment,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Submissions',
                      count: '${stats['submissions'] ?? 0}',
                      color: Colors.purple,
                      icon: Icons.check_circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'All Courses',
                      count: '${stats['totalCourses'] ?? 0}',
                      color: Colors.teal,
                      icon: Icons.school,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Forum Questions',
                      count: '${stats['questions'] ?? 0}',
                      color: Colors.indigo,
                      icon: Icons.forum,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.account_balance_outlined,
                      iconColor: Color(0xFFDF3041),
                      title: 'Create Faculty',
                      subtitle: 'Add new faculty',
                      onTap: () => Get.to(() => const ManageFacultiesScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.groups_outlined,
                      iconColor: Color(0xFF1E63D7),
                      title: 'Manage Users',
                      subtitle: 'Add, edit, remove users',
                      onTap: () => Get.to(() => const _UsersQuickPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.apartment_outlined,
                      iconColor: Color(0xFF1E8A58),
                      title: 'Manage Departments',
                      subtitle: 'Organize departments',
                      onTap: () => Get.to(() => const ManageDepartmentsScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.menu_book_outlined,
                      iconColor: Color(0xFF17A4C6),
                      title: 'Manage Courses',
                      subtitle: 'Oversee all courses',
                      onTap: () => Get.to(() => const _CoursesQuickPage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Stat Card Widget
class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const StatCard({
    Key? key,
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 146,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EAF2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 38),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF5E6B84))),
          ],
        ),
      ),
    );
  }
}

// Manage Users Tab - সব users দেখা এবং manage করা
class ManageUsersTab extends StatefulWidget {
  const ManageUsersTab({Key? key}) : super(key: key);

  @override
  State<ManageUsersTab> createState() => _ManageUsersTabState();
}

class _ManageUsersTabState extends State<ManageUsersTab> {
  final AdminService _adminService = AdminService();
  final _searchController = TextEditingController();
  String _filterRole = 'all'; // Filter by role

  Future<void> _changeRole(User user) async {
    final roleOptions = ['student', 'teacher', 'admin'];
    String selectedRole = roleOptions.contains(user.role) ? user.role : 'student';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Change Role: ${user.fullName.isNotEmpty ? user.fullName : user.email}'),
              content: DropdownButtonFormField<String>(
                initialValue: selectedRole,
                items: roleOptions
                    .map((r) => DropdownMenuItem<String>(value: r, child: Text(r.toUpperCase())))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedRole = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final ok = await _adminService.updateUserRole(user.uid, selectedRole);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Role updated' : 'Failed to update role')),
    );
    if (ok) {
      setState(() {});
    }
  }

  Future<void> _toggleUser(User user) async {
    final ok = await _adminService.toggleUserStatus(user.uid, makeActive: !user.isActive);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? (user.isActive ? 'User deactivated' : 'User activated') : 'Status update failed')),
    );
    if (ok) {
      setState(() {});
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.fullName.isNotEmpty ? user.fullName : user.email}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    final reason = await _adminService.deleteUserWithRules(user);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(reason ?? 'User deleted successfully')),
    );
    if (reason == null) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(15),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),

        // Role Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Super Admin', 'super_admin'),
                _buildFilterChip('Admin', 'admin'),
                _buildFilterChip('Teacher', 'teacher'),
                _buildFilterChip('Student', 'student'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Users List
        Expanded(
          child: FutureBuilder<List<User>>(
            future: _adminService.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              List<User> allUsers = snapshot.data!;

              // Apply filters
              List<User> filteredUsers = allUsers.where((user) {
                bool matchesSearch = _searchController.text.isEmpty ||
                    user.email
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase()) ||
                    user.fullName
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase());

                bool matchesRole =
                    _filterRole == 'all' || user.role == _filterRole;

                return matchesSearch && matchesRole;
              }).toList();

              return ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(user.fullName.isNotEmpty ? user.fullName[0] : 'U'),
                      ),
                      title: Text(user.fullName.isNotEmpty ? user.fullName : user.email),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text(
                            user.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              color: user.isActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              color: user.isSuperAdmin
                                  ? Colors.red
                                  : user.isAdmin
                                      ? Colors.orange
                                      : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'toggle') {
                            await _toggleUser(user);
                          } else if (value == 'role') {
                            await _changeRole(user);
                          } else if (value == 'delete') {
                            await _deleteUser(user);
                          }
                        },
                        itemBuilder: (_) => [
                          if (!user.isSuperAdmin)
                            PopupMenuItem<String>(
                              value: 'toggle',
                              child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                            ),
                          if (!user.isSuperAdmin)
                            const PopupMenuItem<String>(
                              value: 'role',
                              child: Text('Change Role'),
                            ),
                          if (!user.isSuperAdmin)
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete User'),
                            ),
                          if (user.isSuperAdmin)
                            const PopupMenuItem<String>(
                              enabled: false,
                              child: Text('Cannot delete Super Admin'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterRole == value,
        onSelected: (selected) {
          setState(() => _filterRole = value);
        },
      ),
    );
  }
}


// Manage Courses Tab
class ManageCoursesTab extends StatefulWidget {
  const ManageCoursesTab({Key? key}) : super(key: key);

  @override
  State<ManageCoursesTab> createState() => _ManageCoursesTabState();
}

class _ManageCoursesTabState extends State<ManageCoursesTab> {
  final AdminService _adminService = AdminService();
  final _searchController = TextEditingController();
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _adminService.getAllCoursesForAdmin();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _coursesFuture = _adminService.getAllCoursesForAdmin();
    });
    await _coursesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by course name or code',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Course>>(
            future: _coursesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = (snapshot.data ?? [])
                  .where((c) {
                    final q = _searchController.text.trim().toLowerCase();
                    if (q.isEmpty) {
                      return true;
                    }
                    return c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q);
                  })
                  .toList();

              if (courses.isEmpty) {
                return const Center(child: Text('No courses found'));
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                      child: ListTile(
                        title: Text(course.name),
                        subtitle: Text('${course.code.isEmpty ? 'N/A' : course.code} • ${course.department}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (value == 'toggle') {
                              final ok = await _adminService.toggleCourseStatus(course.id, !course.isActive);
                              if (!mounted) {
                                return;
                              }
                              if (ok) {
                                await _refresh();
                                messenger.showSnackBar(
                                  SnackBar(content: Text(course.isActive ? 'Course deactivated' : 'Course activated')),
                                );
                              }
                            } else if (value == 'delete') {
                              final reason = await _adminService.deleteCourseWithRules(course.id);
                              if (!mounted) {
                                return;
                              }
                              if (reason == null) {
                                await _refresh();
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Course deleted successfully')),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(reason)),
                                );
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem<String>(
                              value: 'toggle',
                              child: Text(course.isActive ? 'Deactivate' : 'Activate'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: course.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                          child: Icon(
                            course.isActive ? Icons.check_circle : Icons.pause_circle,
                            color: course.isActive ? Colors.green : Colors.grey,
                          ),
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
    );
  }
}

class _UsersQuickPage extends StatelessWidget {
  const _UsersQuickPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: const ManageUsersTab(),
    );
  }
}

class _CoursesQuickPage extends StatelessWidget {
  const _CoursesQuickPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Courses')),
      body: const ManageCoursesTab(),
    );
  }
}

class ManageFacultiesScreen extends StatefulWidget {
  const ManageFacultiesScreen({Key? key}) : super(key: key);

  @override
  State<ManageFacultiesScreen> createState() => _ManageFacultiesScreenState();
}

class _ManageFacultiesScreenState extends State<ManageFacultiesScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<FacultyItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _adminService.getFaculties(onlyActive: false);
  }

  Future<void> _refresh() async {
    setState(() => _future = _adminService.getFaculties(onlyActive: false));
    await _future;
  }

  Future<void> _createFaculty() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Faculty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Faculty Name')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) {
      return;
    }

    final id = await _adminService.createFaculty(
      name: nameController.text,
      description: descriptionController.text,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(id == null ? 'Failed or duplicate faculty' : 'Faculty created')),
    );
    if (id != null) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Faculties')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFaculty,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<FacultyItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final faculties = snapshot.data ?? const [];
          if (faculties.isEmpty) {
            return const Center(child: Text('No faculties found'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: faculties.length,
              itemBuilder: (context, index) {
                final item = faculties[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: ListTile(
                    leading: Icon(item.isActive ? Icons.check_circle : Icons.pause_circle, color: item.isActive ? Colors.green : Colors.grey),
                    title: Text(item.name),
                    subtitle: Text(item.description.isEmpty ? 'No description' : item.description),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (value == 'toggle') {
                          final ok = await _adminService.updateFaculty(
                            FacultyItem(
                              id: item.id,
                              name: item.name,
                              description: item.description,
                              isActive: !item.isActive,
                              createdAt: item.createdAt,
                            ),
                          );
                          if (ok) {
                            await _refresh();
                            messenger.showSnackBar(SnackBar(content: Text(item.isActive ? 'Faculty deactivated' : 'Faculty activated')));
                          }
                        } else if (value == 'delete') {
                          final reason = await _adminService.deleteFacultyWithRules(item);
                          if (reason == null) {
                            await _refresh();
                            messenger.showSnackBar(const SnackBar(content: Text('Faculty deleted')));
                          } else {
                            messenger.showSnackBar(SnackBar(content: Text(reason)));
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(value: 'toggle', child: Text(item.isActive ? 'Deactivate' : 'Activate')),
                        const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
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

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({Key? key}) : super(key: key);

  @override
  State<ManageDepartmentsScreen> createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<DepartmentItem>> _departmentsFuture;

  @override
  void initState() {
    super.initState();
    _departmentsFuture = _adminService.getDepartments(onlyActive: false);
  }

  Future<void> _refresh() async {
    setState(() {
      _departmentsFuture = _adminService.getDepartments(onlyActive: false);
    });
    await _departmentsFuture;
  }

  Future<void> _createDepartment() async {
    final faculties = await _adminService.getFaculties(onlyActive: true);
    if (!mounted) {
      return;
    }

    if (faculties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create faculty first')));
      return;
    }

    final nameController = TextEditingController();
    String facultyId = faculties.first.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Create Department'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: facultyId,
                  items: faculties
                      .map((f) => DropdownMenuItem<String>(value: f.id, child: Text(f.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => facultyId = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Faculty'),
                ),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Department Name')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
            ],
          ),
        );
      },
    );

    if (ok != true) {
      return;
    }

    final faculty = faculties.firstWhere((f) => f.id == facultyId);
    final id = await _adminService.createDepartment(
      facultyId: facultyId,
      facultyName: faculty.name,
      name: nameController.text,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(id == null ? 'Failed or duplicate department' : 'Department created')),
    );
    if (id != null) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Departments')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDepartment,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<DepartmentItem>>(
        future: _departmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final departments = snapshot.data ?? const [];
          if (departments.isEmpty) {
            return const Center(child: Text('No departments found'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: departments.length,
              itemBuilder: (context, index) {
                final item = departments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: ListTile(
                    leading: Icon(item.isActive ? Icons.check_circle : Icons.pause_circle, color: item.isActive ? Colors.green : Colors.grey),
                    title: Text(item.name),
                    subtitle: Text(item.facultyName),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (value == 'toggle') {
                          final ok = await _adminService.updateDepartment(
                            DepartmentItem(
                              id: item.id,
                              facultyId: item.facultyId,
                              facultyName: item.facultyName,
                              name: item.name,
                              isActive: !item.isActive,
                              createdAt: item.createdAt,
                            ),
                          );
                          if (ok) {
                            await _refresh();
                            messenger.showSnackBar(SnackBar(content: Text(item.isActive ? 'Department deactivated' : 'Department activated')));
                          }
                        } else if (value == 'delete') {
                          final reason = await _adminService.deleteDepartmentWithRules(item);
                          if (reason == null) {
                            await _refresh();
                            messenger.showSnackBar(const SnackBar(content: Text('Department deleted')));
                          } else {
                            messenger.showSnackBar(SnackBar(content: Text(reason)));
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(value: 'toggle', child: Text(item.isActive ? 'Deactivate' : 'Activate')),
                        const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
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

// Admin Profile Tab
class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Not logged in'));
    }

    return FutureBuilder<User?>(
      future: authService.getUserInfo(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('Admin profile not found'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(radius: 32, child: Text(user.fullName.isNotEmpty ? user.fullName[0] : 'A')),
                    const SizedBox(height: 10),
                    Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Chip(label: Text(user.role.toUpperCase())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.settings),
              title: const Text('Account Settings'),
              subtitle: const Text('Use student profile tab settings module'),
              onTap: () {
                Get.snackbar('Info', 'Profile settings module already available in app.');
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => authService.signOut(),
            ),
          ],
        );
      },
    );
  }
}
