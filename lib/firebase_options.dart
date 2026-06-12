import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

// Firebase Configuration File
// তুমি Firebase Console থেকে এই values যোগ করতে পারবে

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.example.pblcFlutter',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDpdc4LaOhRJez0kZm6GWUf65K_1o-LM0o',
    appId: '1:566284064349:android:b4035d6284f15b97fb5fb4',
    messagingSenderId: '566284064349',
    projectId: 'pblc-flutter',
    storageBucket: 'pblc-flutter.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDpdc4LaOhRJez0kZm6GWUf65K_1o-LM0o',
    appId: '1:566284064349:web:8f1c2d3e4f5g6h7i8j9k0l',
    messagingSenderId: '566284064349',
    projectId: 'pblc-flutter',
    storageBucket: 'pblc-flutter.firebasestorage.app',
  );
}

// Firebase Setup Instructions:
// 1. https://console.firebase.google.com এ যাও
// 2. নতুন প্রজেক্ট create করো
// 3. Android/iOS এপ্লিকেশন add করো
// 4. google-services.json (Android) এবং GoogleService-Info.plist (iOS) ডাউনলোড করো
// 5. উপরের values গুলি আপনার firebase project থেকে replace করো
