# Admin Management System

## 🛡️ Role-Based Hierarchy

```
Super Admin (Main Admin)
  ├─ Cannot be deleted
  ├─ Can create other admins
  ├─ Can deactivate any user
  ├─ Can view all statistics
  └─ Can manage all users

Admin (Regular Admin)
  ├─ Can be deactivated by Super Admin
  ├─ Cannot deactivate Super Admin
  ├─ Can manage teachers and students
  └─ Cannot delete other admins

Teacher
  ├─ Can manage courses
  ├─ Can create assignments
  ├─ Can evaluate submissions
  └─ Can manage Q&A

Student
  ├─ Can view courses
  ├─ Can enroll in courses
  ├─ Can submit assignments
  └─ Can ask questions
```

---

## 📱 Admin Features Implemented

### 1. **Manage Users Tab**
- View all users in a searchable list
- Filter by role (Super Admin, Admin, Teacher, Student)
- Search by name, email, or username
- Deactivate users (except Super Admin)
- View user statistics

### 2. **User Protection**
- Super Admin cannot be deleted/deactivated
- Prevents accidental deletion of main admin
- Shows "Cannot delete Super Admin" for protected users

### 3. **Admin Service Functions**

```dart
// Get all users
getAllUsers()

// Filter users by role
getUsersByRole(role)

// Deactivate a user (soft delete)
deactivateUser(userId)

// Reactivate a user
reactivateUser(userId)

// Update user role
updateUserRole(userId, newRole)

// Get user statistics
getUserStatistics()

// Search users
searchUsers(query)
```

---

## 🛠️ How to Add a New User

### Method 1: Through Firebase Console (Quick)

1. Go to Firebase Console > Firestore
2. Click `users` collection
3. Click "Add document"
4. Fill in these fields:

```
email: "newuser@pstu.edu.bd"
fullName: "User Name"
username: "username123"
role: "student" (or "teacher" or "super_admin")
isActive: true
createdAt: (current timestamp)
```

5. Then the user registers in the app with same email

### Method 2: Through App (In Development)

When adding user creation UI:
```dart
// Admin opens "Add User" dialog
// Fills email, name, role
// System creates Firebase Auth account
// System creates Firestore document
```

---

## 🚨 Super Admin Protection

**Super Admin** cannot be:
- ❌ Deleted
- ❌ Deactivated
- ❌ Removed from system
- ✅ Can change own profile
- ✅ Can manage everything

**Code Protection:**
```dart
bool get isSuperAdmin => role == 'super_admin';

if (user.isSuperAdmin) {
  return false; // Cannot deactivate
}
```

---

## 📊 Admin Dashboard Overview

```
Admin Dashboard
├── Overview Tab
│   ├── Total Users
│   ├── Active Courses
│   ├── Total Assignments
│   └── Submissions
│
├── Manage Users Tab ✅ (IMPLEMENTED)
│   ├── Search Bar
│   ├── Role Filter
│   ├── Users List
│   ├── Deactivate User
│   └── User Status
│
├── Manage Courses Tab
│   ├── View all courses
│   ├── Edit course
│   ├── Delete course
│   └── View enrollments
│
└── Profile Tab
    ├── Admin profile
    ├── Change password
    └── Logout
```

---

## 🔐 Security Rules (Firestore)

When implementing security in production:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only super_admin can delete users
    match /users/{userId} {
      allow read: if request.auth != null;
      
      allow update: if request.auth.uid == userId ||
                       userIsSuperAdmin(request.auth.uid);
      
      allow delete: if userIsSuperAdmin(request.auth.uid);
    }
  }
}
```

---

## 📝 Firebase Setup for Admin

In your Firebase project Firestore:

1. Create `users` collection
2. Add first Super Admin document manually:

```json
{
  "email": "admin@pstu.edu.bd",
  "fullName": "System Administrator",
  "username": "admin",
  "role": "super_admin",
  "isActive": true,
  "createdAt": "2024-04-04T00:00:00Z"
}
```

3. Register this admin in Firebase Authentication

---

## 🧪 Testing

### Test Case 1: Try to Delete Super Admin
```
1. Login as super_admin
2. Go to Manage Users
3. Try to deactivate super_admin account
4. Expected: Show "Cannot delete Super Admin"
5. Result: ✅ Deactivation blocked
```

### Test Case 2: Search Users
```
1. Go to Manage Users
2. Type a teacher's name
3. Expected: Only that teacher shows
4. Result: ✅ Search filters correctly
```

### Test Case 3: Filter by Role
```
1. Click "Teacher" filter
2. Expected: Only teachers show
3. Result: ✅ Filter works
```

---

## 📈 Future Enhancements

- [ ] Add user creation dialog in app
- [ ] Bulk user import from CSV
- [ ] Email verification for new users
- [ ] Auto-generate temporary passwords
- [ ] User activity logs
- [ ] Advanced analytics
- [ ] Department-based user management
- [ ] Role assignment from UI

---

## 🐛 Troubleshooting

**Issue:** "Super Admin still showing in user list"
- Solution: The Super Admin should show but cannot be deleted. This is correct.

**Issue:** "Delete button not working"
- Solution: Check Firestore rules. In test mode, all operations are allowed.

**Issue:** "Search not working"
- Solution: Make sure `_searchController` is properly connected to the text input.

---

**Status:** ✅ Admin Management System is LIVE and ready to use!
