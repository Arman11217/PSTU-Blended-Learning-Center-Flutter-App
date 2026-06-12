## PBLC Flutter App - Setup Guide

আমরা Flutter + Firebase দিয়ে PBLC অ্যাপ্লিকেশন তৈরি করছি।

### প্রজেক্ট স্ট্রাকচার
```
lib/
  ├── main.dart                    # অ্যাপ শুরু হওয়ার জায়গা
  ├── firebase_options.dart        # Firebase Configuration
  ├── models/                      # ডাটা মডেলস
  │   ├── user_model.dart
  │   ├── course_model.dart
  │   ├── assignment_model.dart
  │   └── lecture_qa_model.dart
  ├── services/                    # Firebase সেবা
  │   ├── auth_service.dart
  │   ├── course_service.dart
  │   ├── assignment_service.dart
  │   └── lecture_qa_service.dart
  └── screens/                     # UI স্ক্রিনগুলি
      ├── auth/
      │   └── login_screen.dart
      ├── student/
      │   └── student_dashboard.dart
      ├── teacher/
      │   └── teacher_dashboard.dart
      └── admin/
          └── admin_dashboard.dart
```

### প্রতিটি ফাইল কী করে?

#### 1. **Models** - ডাটা স্ট্রাকচার
```
user_model.dart         → ইউজার তথ্য (নাম, ইমেইল, রোল)
course_model.dart       → কোর্স তথ্য 
assignment_model.dart   → অ্যাসাইনমেন্ট এবং সাবমিশন
lecture_qa_model.dart   → লেকচার এবং প্রশ্ন-উত্তর
```

#### 2. **Services** - Firebase অপারেশন
```
auth_service.dart           → লগইন, সাইনআপ, লগআউট
course_service.dart         → কোর্স তৈরি, এনরোল, ডেলিট
assignment_service.dart     → অ্যাসাইনমেন্ট সাবমিট, ইভালুয়েট
lecture_qa_service.dart     → প্রশ্ন জিজ্ঞাসা, উত্তর দেওয়া
```

#### 3. **Screens** - UI/UX
```
login_screen.dart           → লগইন এবং রেজিস্ট্রেশন
student_dashboard.dart      → শিক্ষার্থীর ড্যাশবোর্ড (4 ট্যাব)
teacher_dashboard.dart      → শিক্ষকের ড্যাশবোর্ড (4 ট্যাব)
admin_dashboard.dart        → অ্যাডমিনের ড্যাশবোর্ড (4 ট্যাব)
```

---

### Setup Steps

#### Step 1: Firebase Setup
1. https://console.firebase.google.com এ যাও
2. নতুন প্রজেক্ট তৈরি করো
3. Android এবং iOS অ্যাপ add করো
4. Configuration ফাইল ডাউনলোড করো:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

#### Step 2: Firebase Credentials
`lib/firebase_options.dart` তে উপরের values যোগ করো:
```dart
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',        // Firebase Console থেকে copy করো
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}
```

#### Step 3: Flutter Setup
```bash
flutter pub get
flutter pub upgrade
```

#### Step 4: Run App
```bash
flutter run
```

---

### Firebase Configuration (Firestore Rules)

Firestore-এ এই collections তৈরি করতে হবে:

```
users/                      → ব্যবহারকারীর তথ্য
courses/                    → কোর্সের তথ্য
courseEnrollments/          → কে কোন কোর্সে enrolled
assignments/                → অ্যাসাইনমেন্ট
assignmentSubmissions/      → অ্যাসাইনমেন্ট সাবমিশন
lectures/                   → লেকচার উপকরণ
questions/                  → Q&A প্রশ্ন
answers/                    → Q&A উত্তর
```

---

### কোড বোঝার উপায়

#### Authentication Flow
```
Login Screen
    ↓
AuthService.signIn() → Firebase Auth
    ↓
Main.dart → AuthWrapper → RoleBasedDashboard
    ↓
Student/Teacher/Admin Dashboard
```

#### Course Enrollment Flow
```
Student Dashboard (CoursesTab)
    ↓
getCourseById() → Course Detail Screen
    ↓
Enroll Button → enrollStudentInCourse()
    ↓
Firebase: courseEnrollments collection update
```

#### Assignment Flow
```
Teacher: CreateAssignmentTab
    ↓
createAssignment() → assignments collection
    ↓
Student: AssignmentsTab
    ↓
submitAssignment() → assignmentSubmissions collection
    ↓
Teacher: EvaluateSubmissionsTab
    ↓
evaluateSubmission() → marks + feedback update
```

---

### Key Functions ব্যাখ্যা

#### Auth Service
```dart
signUp()        // নতুন অ্যাকাউন্ট তৈরি করা
signIn()        // লগইন করা
signOut()       // লগআউট করা
getUserInfo()   // ব্যবহারকারীর তথ্য পেতে
```

#### Course Service
```dart
getAllCourses()              // সব কোর্স দেখা
getCourseById()              // একটি কোর্সের বিস্তারিত
getTeacherCourses()          // শিক্ষকের নিজের কোর্স
getEnrolledCourses()         // শিক্ষার্থীর যে কোর্সে আছে
enrollStudentInCourse()      // কোর্সে ভর্তি হওয়া
```

#### Assignment Service
```dart
createAssignment()           // অ্যাসাইনমেন্ট তৈরি
submitAssignment()           // অ্যাসাইনমেন্ট জমা দেওয়া
evaluateSubmission()         // মার্কিং করা
getStudentSubmissions()      // শিক্ষার্থীর সাবমিশন দেখা
```

---

### কাস্টমাইজেশন

প্রতিটি Screen-এ "Coming Soon" লেখা আছে। তুমি যা করতে পারো:

1. **AssignmentsTab** কে সম্পূর্ণ করো
2. **QAForumTab** এ প্রশ্ন-উত্তর যুক্ত করো
3. **ProfileTab** এ প্রোফাইল সম্পাদনা যোগ করো
4. **Student Enrollment Logic** upgrade করো
5. **Performance Analytics** যোগ করো

---

### Firebase Database Example

#### users collection
```json
{
  "uid": "user123",
  "email": "student@example.com",
  "fullName": "John Doe",
  "username": "johndoe",
  "role": "student",
  "createdAt": "2024-04-04"
}
```

#### courses collection
```json
{
  "id": "course1",
  "name": "Introduction to Flutter",
  "description": "Learn Flutter basics",
  "teacherId": "teacher1",
  "department": "CSE",
  "totalLectures": 10,
  "totalAssignments": 5,
  "isActive": true
}
```

#### assignments collection
```json
{
  "id": "assign1",
  "courseId": "course1",
  "title": "Build a counter app",
  "description": "Create a simple counter",
  "dueDate": "2024-04-15",
  "createdBy": "teacher1"
}
```

---

### Troubleshooting

**Issue:** Firebase connection error
**Solution:** `firebase_options.dart` এর credentials check করো

**Issue:** Login works but dashboard not loading
**Solution:** Firestore rules check করো, users collection এ ডাটা আছে কিনা দেখো

**Issue:** Courses not showing
**Solution:** Firestore console-এ courses collection create করেছ কিনা check করো

---

### Next Steps

1. ✅ Firebase setup complete
2. ⏳ Auth এবং basic dashboards ready
3. ⏳ Assignments এবং Q&A কার্যকরী করা
4. ⏳ UI/UX improvement
5. ⏳ Testing এবং deployment

---

**সব ফাইলে ইংরেজিশ কমেন্ট আছে যা কোড ব্যাখ্যা করে। আপনি সহজেই বুঝতে পারবেন!**
