import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// Firebase Authentication Service
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _superAdminEmail = 'admin@pstu.ac.bd';

  bool _isReservedSuperAdminEmail(String email) {
    return email.trim().toLowerCase() == _superAdminEmail;
  }

  // Get current logged-in user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<firebase_auth.User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Stream<User?> userInfoStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return User.fromMap(doc.data() as Map<String, dynamic>, uid);
    });
  }

  // Sign Up - নতুন ব্যবহারকারী তৈরি করা
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String role,
    String? facultyId,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final effectiveRole = _isReservedSuperAdminEmail(normalizedEmail)
          ? 'super_admin'
          : role;

      // Firebase Authentication-এ ইউজার তৈরি করা
      firebase_auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      // Firestore-এ ইউজার ডাটা সেভ করা
      User newUser = User(
        uid: userCredential.user!.uid,
        email: normalizedEmail,
        fullName: fullName,
        username: username,
        role: effectiveRole,
        facultyId: facultyId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toMap());

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Sign Up Error: ${e.message}');
      return false;
    }
  }

  // Sign In - লগইন করা
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      await ensureUserExists();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Sign In Error: ${e.message}');
      return false;
    }
  }

  // Sign Out - লগআউট করা
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
    String? facultyId,
    String? photoUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return false;
      }

      final trimmedName = fullName.trim();
      final trimmedEmail = email.trim();

      if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
        return false;
      }

      if (user.email != trimmedEmail) {
        await user.verifyBeforeUpdateEmail(trimmedEmail);
      }

      await user.updateDisplayName(trimmedName);

      final updateData = <String, dynamic>{
        'fullName': trimmedName,
        'email': trimmedEmail,
        'facultyId': facultyId,
      };

      if (photoUrl != null && photoUrl.isNotEmpty) {
        updateData['photoUrl'] = photoUrl;
      }

      await _firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Update Profile Auth Error: ${e.message}');
      return false;
    } catch (e) {
      print('Update Profile Error: $e');
      return false;
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        return false;
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Update Password Auth Error: ${e.message}');
      return false;
    } catch (e) {
      print('Update Password Error: $e');
      return false;
    }
  }

  // Get User Information from Firestore
  Future<User?> getUserInfo(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      print('Get User Info Error: $e');
      return null;
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Reset Password Error: ${e.message}');
      return false;
    }
  }

  // Ensure user exists in Firestore (প্রথম লগইন এ ইউজার তৈরি করা)
  Future<void> ensureUserExists() async {
    try {
      if (currentUser != null) {
        final uid = currentUser!.uid;
        final email = (currentUser!.email ?? '').trim().toLowerCase();
        final isReservedSuperAdmin = _isReservedSuperAdminEmail(email);

        final userDoc = await _firestore.collection('users').doc(uid).get();
        
        // যদি ইউজার exist না করে তাহলে default user তৈরি করা
        if (!userDoc.exists) {
          User newUser = User(
            uid: uid,
            email: email,
            fullName: currentUser!.displayName ?? 'User',
            username: currentUser!.email?.split('@')[0] ?? 'user',
            role: isReservedSuperAdmin ? 'super_admin' : 'student',
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(uid)
              .set(newUser.toMap());
              
          print('User created in Firestore');
          return;
        }

        if (isReservedSuperAdmin) {
          final data = userDoc.data() ?? <String, dynamic>{};
          final currentRole = (data['role'] as String?) ?? 'student';
          final isActive = (data['isActive'] as bool?) ?? true;

          if (currentRole != 'super_admin' || !isActive) {
            await _firestore.collection('users').doc(uid).set({
              'role': 'super_admin',
              'isActive': true,
              'email': email,
            }, SetOptions(merge: true));
            print('Reserved super admin role synchronized');
          }
        }
      }
    } catch (e) {
      print('Ensure User Exists Error: $e');
    }
  }
}

