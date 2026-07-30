import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase config for the "rojgari-8f69b" project. Android reads its own
/// config from android/app/google-services.json automatically, so only Web
/// needs an explicit [FirebaseOptions] object here — copied from the Web
/// app registered in the Firebase console (Project settings > General >
/// Your apps > Web app).
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions? get currentPlatform => kIsWeb ? web : null;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDBK5YWFLCAge9kVRcqru12ILSKsOP336U",
    authDomain: "rojgari-8f69b.firebaseapp.com",
    projectId: "rojgari-8f69b",
    storageBucket: "rojgari-8f69b.firebasestorage.app",
    messagingSenderId: "1056084039025",
    appId: "1:1056084039025:web:bf83c32f215964861cd2d0",
    measurementId: "G-LKX3KQXWJD",
  );
}
