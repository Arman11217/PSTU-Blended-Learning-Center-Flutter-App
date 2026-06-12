import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/faculty_department_model.dart';
import '../../models/user_model.dart';
import '../../screens/student/student_performance_screen.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/file_storage_service.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return StreamBuilder<User?>(
      stream: authService.userInfoStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const Center(child: Text('Profile not found'));
        }

        final firstName = profile.fullName.trim().isEmpty
            ? 'Student'
            : profile.fullName.split(' ').first;

        return ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFE7ECF7),
                    backgroundImage: (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: (profile.photoUrl == null || profile.photoUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Color(0xFF4D5F85), size: 58)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    firstName,
                    style: const TextStyle(
                      color: Color(0xFF17203A),
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                    ),
                  ),
                  Text(
                    profile.email,
                    style: const TextStyle(
                      color: Color(0xFF607091),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _chip('ID: ${profile.username.isEmpty ? profile.uid.substring(0, 6) : profile.username}'),
                  const SizedBox(height: 8),
                  _chip('Faculty: ${profile.facultyId ?? 'Not set'}'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 230,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(() => EditProfileScreen(initialUser: profile)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29449B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ACCOUNT SETTINGS',
                style: TextStyle(
                  color: Color(0xFF9CA8BF),
                  letterSpacing: 1,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _settingsTile(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF2E68FF),
                    title: 'Edit Profile Details',
                    onTap: () => Get.to(() => EditProfileScreen(initialUser: profile)),
                  ),
                  _settingsTile(
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFFE67E22),
                    title: 'Change Password',
                    onTap: () => Get.to(() => const ChangePasswordScreen()),
                  ),
                  _settingsTile(
                    icon: Icons.insights_outlined,
                    iconColor: const Color(0xFF0BAA60),
                    title: 'Performance Overview',
                    onTap: () {
                      Get.to(() => const StudentPerformanceScreen());
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF29449B),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D2742),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDC7D8)),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key, required this.initialUser}) : super(key: key);

  final User initialUser;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  final _adminService = AdminService();
  final _picker = ImagePicker();
  final _fileStorageService = FileStorageService();

  bool _saving = false;
  bool _loadingFaculties = true;
  String? _faculty;
  Uint8List? _pickedImageBytes;

  List<FacultyItem> _faculties = const [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialUser.fullName;
    _emailController.text = widget.initialUser.email;
    _faculty = widget.initialUser.facultyId;
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    final faculties = await _adminService.getFaculties(onlyActive: true);
    if (!mounted) {
      return;
    }

    setState(() {
      _faculties = faculties;
      if ((_faculty == null || _faculty!.trim().isEmpty) && faculties.isNotEmpty) {
        _faculty = faculties.first.name;
      }
      _loadingFaculties = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _pickedImageBytes = bytes;
    });
  }

  Future<String?> _uploadProfileImage(Uint8List bytes) async {
    final user = _authService.currentUser;
    if (user == null) {
      return null;
    }

    final path = 'profile_photos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _fileStorageService.uploadBinary(
      bytes: bytes,
      path: path,
      contentType: 'image/jpeg',
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please fill all required fields');
      return;
    }

    setState(() => _saving = true);

    String? photoUrl = widget.initialUser.photoUrl;
    try {
      if (_pickedImageBytes != null) {
        photoUrl = await _uploadProfileImage(_pickedImageBytes!);
      }

      final success = await _authService.updateProfile(
        fullName: _nameController.text,
        email: _emailController.text,
        facultyId: _faculty,
        photoUrl: photoUrl,
      );

      if (success) {
        if (!mounted) {
          return;
        }
        Get.back();
        Get.snackbar('Success', 'Profile updated successfully');
      } else {
        Get.snackbar('Error', 'Failed to update profile');
      }
    } catch (_) {
      Get.snackbar('Error', 'Image upload or profile update failed');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.initialUser.photoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF29449B)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 66,
                            backgroundColor: const Color(0xFFE5EAF4),
                            backgroundImage: _pickedImageBytes != null
                                ? MemoryImage(_pickedImageBytes!)
                                : (currentPhoto != null && currentPhoto.isNotEmpty
                                    ? NetworkImage(currentPhoto)
                                    : null) as ImageProvider?,
                            child: (_pickedImageBytes == null && (currentPhoto == null || currentPhoto.isEmpty))
                                ? const Icon(Icons.person, size: 72, color: Color(0xFF52617F))
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 2,
                            child: InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF29449B),
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.photo_camera_outlined, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Change Photo',
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Color(0xFF17203A)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Update your profile picture for the faculty directory',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF657492), fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: _inputDecoration('Enter full name', Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Enter email', Icons.mail_outline),
                    ),
                    const SizedBox(height: 16),
                    const Text('Faculty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_loadingFaculties)
                      const LinearProgressIndicator(minHeight: 3)
                    else
                      Builder(
                        builder: (context) {
                          final names = _faculties.map((f) => f.name).toList();
                          final value = names.contains(_faculty) ? _faculty : null;
                          return DropdownButtonFormField<String>(
                            initialValue: value,
                            items: names
                                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                                .toList(),
                            onChanged: (next) => setState(() => _faculty = next),
                            decoration: _inputDecoration(
                              _faculties.isEmpty ? 'No faculty configured by admin' : 'Select Faculty',
                              Icons.school_outlined,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29449B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: Icon(icon, color: const Color(0xFF96A4BD)),
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD8E0EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF29449B), width: 1.4),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_newController.text);
  bool get _hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(_newController.text);

  Future<void> _submit() async {
    if (_currentController.text.isEmpty || _newController.text.isEmpty || _confirmController.text.isEmpty) {
      Get.snackbar('Error', 'All fields are required');
      return;
    }

    if (_newController.text != _confirmController.text) {
      Get.snackbar('Error', 'Confirm password does not match');
      return;
    }

    if (!_hasMinLength || !_hasUppercase || !_hasSpecial) {
      Get.snackbar('Error', 'Password does not meet requirements');
      return;
    }

    setState(() => _saving = true);

    final ok = await _authService.updatePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    setState(() => _saving = false);

    if (ok) {
      Get.back();
      Get.snackbar('Success', 'Password updated successfully');
    } else {
      Get.snackbar('Error', 'Failed to update password. Check current password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF29449B)),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Color(0xFF182033), fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Secure Your Account',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Color(0xFF17203A)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To secure your account, please enter your current password and choose a new one.',
                      style: TextStyle(fontSize: 18, color: Color(0xFF5F6E8D), height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    const Text('Current Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _currentController,
                      obscureText: _hideCurrent,
                      decoration: _passwordDecoration(
                        'Enter current password',
                        _hideCurrent,
                        () => setState(() => _hideCurrent = !_hideCurrent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('New Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newController,
                      obscureText: _hideNew,
                      onChanged: (_) => setState(() {}),
                      decoration: _passwordDecoration(
                        'Enter new password',
                        _hideNew,
                        () => setState(() => _hideNew = !_hideNew),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmController,
                      obscureText: _hideConfirm,
                      decoration: _passwordDecoration(
                        'Re-enter new password',
                        _hideConfirm,
                        () => setState(() => _hideConfirm = !_hideConfirm),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EDF6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD4DDEA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Password Requirements:',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF29449B)),
                          ),
                          const SizedBox(height: 10),
                          _ruleItem('At least 8 characters', _hasMinLength),
                          _ruleItem('One uppercase letter', _hasUppercase),
                          _ruleItem('One special character', _hasSpecial),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29449B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.1, color: Colors.white),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration(String hint, bool hide, VoidCallback toggle) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      ),
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
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
        borderSide: const BorderSide(color: Color(0xFF29449B), width: 1.4),
      ),
    );
  }

  Widget _ruleItem(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: ok ? const Color(0xFF29449B) : const Color(0xFFB3BED3),
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xFF384C70), fontSize: 15)),
        ],
      ),
    );
  }
}
