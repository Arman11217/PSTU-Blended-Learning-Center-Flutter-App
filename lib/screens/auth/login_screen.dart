import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/faculty_department_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

// Login & Registration Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();

  // Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();

  bool isLogin = true; // true = Login, false = Register
  bool isLoading = false;
  bool stayLoggedIn = true;
  bool obscurePassword = true;
  String? selectedRole = 'student'; // Default role for new user
  String? selectedFaculty;
  bool _loadingFaculties = true;
  List<FacultyItem> _faculties = const [];

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    final faculties = await _adminService.getFaculties(onlyActive: true);
    if (!mounted) {
      return;
    }

    setState(() {
      _faculties = faculties;
      _loadingFaculties = false;
      if (faculties.isNotEmpty) {
        selectedFaculty = faculties.first.name;
      } else {
        selectedFaculty = null;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Login function
  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    setState(() => isLoading = true);

    bool success = await _authService.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => isLoading = false);

    if (success) {
      Get.snackbar('Success', 'Logged in successfully');
    } else {
      Get.snackbar('Error', 'Login failed. Check credentials');
    }
  }

  // Sign Up function
  void _signup() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    if ((selectedRole ?? 'student') == 'student' &&
        (selectedFaculty == null || selectedFaculty!.trim().isEmpty)) {
      Get.snackbar('Error', 'Please select faculty');
      return;
    }

    setState(() => isLoading = true);

    bool success = await _authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _fullNameController.text,
      username: _usernameController.text,
      role: selectedRole ?? 'student',
      facultyId: selectedFaculty,
    );

    setState(() => isLoading = false);

    if (success) {
      Get.snackbar('Success', 'Account created! Now login');
      setState(() => isLogin = true);
      _emailController.clear();
      _passwordController.clear();
      _fullNameController.clear();
      _usernameController.clear();
    } else {
      Get.snackbar('Error', 'Sign up failed');
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF95A4BE)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF1F4F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF29449B), width: 1.4),
      ),
    );
  }

  Widget _authCard({required BuildContext context}) {
    return Container(
      width: 420,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 42,
            offset: const Offset(0, 24),
            color: const Color(0xFF344A8F).withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.school_rounded, color: Color(0xFF29449B), size: 30),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              isLogin ? 'Welcome Back' : 'Create Account',
              style: const TextStyle(
                fontSize: 40,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17203A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              isLogin
                  ? 'Please enter your credentials to access the PBLC'
                  : 'Start your academic journey with us today.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF63708A),
                fontSize: 18,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 26),
          if (!isLogin) ...[
            const Text(
              'SELECT YOUR ROLE',
              style: TextStyle(
                letterSpacing: 1,
                color: Color(0xFF17203A),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFECF0F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedRole = 'student'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: selectedRole == 'student' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline,
                                color: selectedRole == 'student'
                                    ? const Color(0xFF29449B)
                                    : const Color(0xFF7D8CA6)),
                            const SizedBox(width: 8),
                            Text(
                              'Student',
                              style: TextStyle(
                                color: selectedRole == 'student'
                                    ? const Color(0xFF29449B)
                                    : const Color(0xFF7D8CA6),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedRole = 'teacher'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: selectedRole == 'teacher' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cast_for_education_outlined,
                                color: selectedRole == 'teacher'
                                    ? const Color(0xFF29449B)
                                    : const Color(0xFF7D8CA6)),
                            const SizedBox(width: 8),
                            Text(
                              'Teacher',
                              style: TextStyle(
                                color: selectedRole == 'teacher'
                                    ? const Color(0xFF29449B)
                                    : const Color(0xFF7D8CA6),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (!isLogin) ...[
            const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF25324B))),
            const SizedBox(height: 8),
            TextField(controller: _fullNameController, decoration: _fieldDecoration(hint: 'e.g. Arman Hossain', icon: Icons.badge_outlined)),
            const SizedBox(height: 16),
            const Text('User Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF25324B))),
            const SizedBox(height: 8),
            TextField(controller: _usernameController, decoration: _fieldDecoration(hint: 'e.g. armd26', icon: Icons.perm_identity_outlined)),
            const SizedBox(height: 16),
          ],
          Text(isLogin ? 'Email' : 'University Email Address',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF25324B))),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _fieldDecoration(
              hint: isLogin ? 'e.g. @pstu.ac.bd' : 'e.g. ug22@pstu.ac.bd',
              icon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),
          Text('Password',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF25324B))),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: obscurePassword,
            decoration: _fieldDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () => setState(() => obscurePassword = !obscurePassword),
                icon: Icon(
                  obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF95A4BE),
                ),
              ),
            ),
          ),
          if (!isLogin) ...[
            const SizedBox(height: 16),
            const Text('Faculty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF25324B))),
            const SizedBox(height: 8),
            if (_loadingFaculties)
              const LinearProgressIndicator(minHeight: 3)
            else
              Builder(
                builder: (context) {
                  final names = _faculties.map((f) => f.name).toList();
                  final value = names.contains(selectedFaculty) ? selectedFaculty : null;
                  return DropdownButtonFormField<String>(
                    initialValue: value,
                    items: names
                        .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (next) => setState(() => selectedFaculty = next),
                    decoration: _fieldDecoration(
                      hint: _faculties.isEmpty ? 'No faculty configured by admin' : 'Select Faculty',
                      icon: Icons.account_balance_outlined,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7D8CA6)),
                  );
                },
              ),
          ],
          if (isLogin) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: stayLoggedIn,
                  onChanged: (value) => setState(() => stayLoggedIn = value ?? false),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  side: const BorderSide(color: Color(0xFFC8D3E5)),
                ),
                const Expanded(
                  child: Text(
                    'Stay logged in for 30 days',
                    style: TextStyle(color: Color(0xFF4E5F7F), fontSize: 15),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_emailController.text.isEmpty) {
                      Get.snackbar('Error', 'Enter your email first');
                      return;
                    }
                    _authService.resetPassword(_emailController.text);
                    Get.snackbar('Info', 'Password reset email sent');
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF29449B)),
                  ),
                )
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : (isLogin ? _login : _signup),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF29449B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(
                      isLogin ? 'Sign In →' : 'Register',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5EAF2)),
          const SizedBox(height: 18),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLogin ? 'New student? ' : 'Already have an account? ',
                  style: const TextStyle(fontSize: 15, color: Color(0xFF546482)),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => isLogin = !isLogin);
                  },
                  child: Text(
                    isLogin ? 'Create an account' : 'Sign In',
                    style: const TextStyle(
                      color: Color(0xFF29449B),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLogin) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '© 2026 PSTU Blended Learning Center',
                style: TextStyle(color: Color(0xFF98A6C0), fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: _authCard(context: context),
          ),
        ),
      ),
    );
  }
}
