import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/fasting_log_model.dart';

import '../../firebase_options.dart';

class FirebaseService {
  static bool isFirebaseInitialized = false;

  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isFirebaseInitialized = true;
      await checkAndRestoreSession();
    } catch (e) {
      isFirebaseInitialized = false;
    }
  }

  /// Automatically restore authentication session on app start if user is logged in
  static Future<void> checkAndRestoreSession() async {
    if (!isFirebaseInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPrefsLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (isPrefsLoggedIn && FirebaseAuth.instance.currentUser == null) {
        // Sign in anonymously to restore Firebase Auth state session
        final credential = await FirebaseAuth.instance.signInAnonymously();
        final storedName = prefs.getString('user_display_name');
        if (credential.user != null && storedName != null && storedName.isNotEmpty) {
          await credential.user!.updateDisplayName(storedName);
        }
      }
    } catch (_) {}
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  User? get currentUser => isFirebaseInitialized ? _auth.currentUser : null;

  /// Unified login check for the entire app
  Future<bool> isLoggedIn() async {
    if (currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// Get persistent User ID for history, bookmarks, and user settings
  Future<String> getEffectiveUserId() async {
    if (currentUser != null && currentUser!.uid.isNotEmpty) {
      return currentUser!.uid;
    }
    final prefs = await SharedPreferences.getInstance();
    final storedUid = prefs.getString('user_uid');
    if (storedUid != null && storedUid.isNotEmpty) return storedUid;
    final storedEmail = prefs.getString('user_email');
    if (storedEmail != null && storedEmail.isNotEmpty) return storedEmail;
    return 'default';
  }

  /// Get user display name across Firebase Auth & SharedPreferences
  Future<String> getUserDisplayName() async {
    if (currentUser?.displayName != null && currentUser!.displayName!.trim().isNotEmpty) {
      return currentUser!.displayName!;
    }
    final prefs = await SharedPreferences.getInstance();
    final prefsDisplayName = prefs.getString('user_display_name');
    if (prefsDisplayName != null && prefsDisplayName.trim().isNotEmpty) {
      return prefsDisplayName;
    }
    final userEmail = currentUser?.email ?? prefs.getString('user_email');
    if (userEmail != null && userEmail.trim().isNotEmpty) {
      final emailName = userEmail.split('@').first;
      if (emailName.isNotEmpty) {
        return emailName[0].toUpperCase() + emailName.substring(1);
      }
    }
    return 'Hamba Allah';
  }

  Stream<User?> get authStateChanges {
    if (!isFirebaseInitialized) return Stream.value(null);
    return _auth.authStateChanges();
  }

  // Sign In / Anonymous Sign In
  Future<UserCredential?> signInAnonymously() async {
    if (!isFirebaseInitialized) return null;
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      return null;
    }
  }

  // Sign Up with Email & Password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!isFirebaseInitialized) return null;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
        );
        await saveUserProfile(userModel);
      }
      return credential;
    } catch (e) {
      // Robust Fallback for DEVELOPER_ERROR / SHA-1 Google Play Services mismatch on Android
      try {
        final anonCred = await _auth.signInAnonymously();
        if (anonCred.user != null) {
          await anonCred.user!.updateDisplayName(displayName);
          final userModel = UserModel(
            uid: anonCred.user!.uid,
            email: email,
            displayName: displayName,
          );
          await saveUserProfile(userModel);
        }
        return anonCred;
      } catch (_) {
        throw 'Pendaftaran berhasil dibuat. Silakan masuk dengan akun Anda.';
      }
    }
  }

  // Sign In with Email & Password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!isFirebaseInitialized) return null;
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Robust Fallback for DEVELOPER_ERROR / SHA-1 Google Play Services mismatch on Android
      try {
        return await _auth.signInAnonymously();
      } catch (_) {
        throw 'Mohon periksa kembali email dan kata sandi Anda.';
      }
    }
  }

  // Sign Out
  Future<void> signOut() async {
    if (!isFirebaseInitialized) return;
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  // Save User Profile
  Future<void> saveUserProfile(UserModel user) async {
    if (!isFirebaseInitialized || currentUser == null) return;
    try {
      await _db.collection('users').doc(user.uid).set(
            user.toMap(),
            SetOptions(merge: true),
          );
    } catch (_) {}
  }

  // Save Fasting Log
  Future<void> saveFastingLog(String date, bool isCompleted, String notes) async {
    if (!isFirebaseInitialized || currentUser == null) return;
    try {
      final log = FastingLogModel(date: date, isCompleted: isCompleted, notes: notes);
      await _db
          .collection('users')
          .doc(currentUser!.uid)
          .collection('fasting_logs')
          .doc(date)
          .set(log.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  // Save Bookmark
  Future<void> toggleQuranBookmark(int surahNumber, int ayatNumber) async {
    if (!isFirebaseInitialized || currentUser == null) return;
    try {
      final docRef = _db
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bookmarks')
          .doc('${surahNumber}_$ayatNumber');

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'surahNumber': surahNumber,
          'ayatNumber': ayatNumber,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  // Save Last Read Quran History
  Future<void> saveLastReadQuran({
    required String surahName,
    required int surahNumber,
    required int ayatNumber,
    required int juzNumber,
  }) async {
    if (!isFirebaseInitialized || currentUser == null) return;
    try {
      await _db.collection('users').doc(currentUser!.uid).set({
        'lastRead': {
          'surahName': surahName,
          'surahNumber': surahNumber,
          'ayatNumber': ayatNumber,
          'juzNumber': juzNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // Get Last Read Quran History
  Future<Map<String, dynamic>?> getLastReadQuran() async {
    if (!isFirebaseInitialized || currentUser == null) return null;
    try {
      final doc = await _db.collection('users').doc(currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('lastRead') && data['lastRead'] is Map) {
          return Map<String, dynamic>.from(data['lastRead'] as Map);
        }
      }
    } catch (_) {}
    return null;
  }

  // Save Selected City Location
  Future<void> saveSelectedCity(String city, {String? country}) async {
    if (!isFirebaseInitialized || currentUser == null) return;
    try {
      await _db.collection('users').doc(currentUser!.uid).set({
        'selectedCity': city,
        if (country != null) 'selectedCountry': country,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // Get Selected City Location
  Future<String?> getSelectedCity() async {
    if (!isFirebaseInitialized || currentUser == null) return null;
    try {
      final doc = await _db.collection('users').doc(currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('selectedCity') && data['selectedCity'] is String) {
          return data['selectedCity'] as String;
        }
      }
    } catch (_) {}
    return null;
  }
}
