import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  String? firebaseInitError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    firebaseInitError = e.toString();
    debugPrint('Firebase initialization error: $e');
  }

  runApp(PBLCApp(
    firebaseReady: firebaseReady,
    firebaseInitError: firebaseInitError,
  ));
}

class PBLCApp extends StatelessWidget {
  const PBLCApp({
    super.key,
    required this.firebaseReady,
    this.firebaseInitError,
  });

  final bool firebaseReady;
  final String? firebaseInitError;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PSTU Blended Learning Center',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: firebaseReady
          ? const SplashScreen()
          : FirebaseSetupScreen(errorText: firebaseInitError),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, this.errorText});

  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase setup incomplete for this platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Web app চালাতে Firebase Console এ Web app add করে firebase_options.dart update করতে হবে।',
                  textAlign: TextAlign.center,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'বর্তমানে Android config আছে, কিন্তু Web config অসম্পূর্ণ।',
                    textAlign: TextAlign.center,
                  ),
                ],
                if (errorText != null && errorText!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      errorText!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Splash Screen - Loading indicator while initialization happens
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  void _navigateToAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Get.off(() => const AuthWrapper());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('PSTU Blended Learning Center'),
            const SizedBox(height: 10),
            const Text('Loading...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// AuthWrapper - ব্যবহারকারী লগইন আছে কিনা তা চেক করে সঠিক স্ক্রিন দেখায়
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges(),
      builder: (context, snapshot) {
        // যখন Firebase থেকে ডাটা লোড হচ্ছে
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // যদি কোন ইউজার লগইন না থাকে তাহলে Login Screen দেখাও
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // First login এ default user create করা
        if (snapshot.hasData) {
          _authService.ensureUserExists();
        }

        // যদি ইউজার লগইন থাকে তাহলে তার রোল অনুযায়ী ড্যাশবোর্ড দেখাও
        return const RoleBasedDashboard();
      },
    );
  }
}

// RoleBasedDashboard - ইউজারের রোল অনুযায়ী সঠিক ড্যাশবোর্ড দেখায়
class RoleBasedDashboard extends StatefulWidget {
  const RoleBasedDashboard({Key? key}) : super(key: key);

  @override
  State<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<RoleBasedDashboard> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.ensureUserExists();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Session expired. Please login again.')),
      );
    }

    return StreamBuilder(
      stream: _authService.userInfoStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        // রোল অনুযায়ী সঠিক ড্যাশবোর্ড রিটার্ন করা
        if (user != null) {
          if (user.role == 'student') {
            return const StudentDashboard();
          } else if (user.role == 'teacher') {
            return const TeacherDashboard();
          } else if (user.role == 'admin' || user.role == 'super_admin') {
            return const AdminDashboard();
          }
        }

        return const Scaffold(
          body: Center(
            child: Text('Unknown Role'),
          ),
        );
      },
    );
  }
}
