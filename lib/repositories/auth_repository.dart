/// ------------------------------------------------------------------
/// File: auth_repository.dart
/// Role: Database Access Layer (Repository)
/// 
/// Description:
/// Abstracts all direct interactions with Firebase Firestore. Handles CRUD (Create, Read, Update, Delete) operations and provides continuous data streams to the Providers.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../firebase_options.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// -----------------------------------------
  /// Method: signIn
  /// Purpose: Executes logic for signIn and handles state or UI updates.
  /// -----------------------------------------
  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      return getUserById(credential.user!.uid);
    }
    return null;
  }

  /// -----------------------------------------
  /// Method: signOut
  /// Purpose: Executes logic for signOut and handles state or UI updates.
  /// -----------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// -----------------------------------------
  /// Method: getUserById
  /// Purpose: Executes logic for getUserById and handles state or UI updates.
  /// -----------------------------------------
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  /// Creates a new Firebase Auth user WITHOUT signing out the current admin.
  /// Uses a secondary FirebaseApp instance so admin session is preserved.
  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? supervisorId,
  }) async {
    // Initialize a temporary secondary Firebase app
    const secondaryAppName = 'fyp_secondary_auth';

    // Delete if it already exists from a previous call
    try {
      final existing = Firebase.app(secondaryAppName);
      await existing.delete();
    } catch (_) {
      // Does not exist — fine
    }

    final secondaryApp = await Firebase.initializeApp(
      name: secondaryAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      // Create user in secondary auth (does NOT affect primary auth session)
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Store user document in Firestore
      final userModel = UserModel(
        id: uid,
        name: name,
        email: email,
        role: role,
        supervisorId: supervisorId,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      // Clean up secondary auth + app
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      return userModel;
    } catch (e) {
      // Always clean up even on error
      try {
        await secondaryAuth.signOut();
        await secondaryApp.delete();
      } catch (_) {}
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
}
