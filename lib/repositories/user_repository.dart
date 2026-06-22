/// ------------------------------------------------------------------
/// File: user_repository.dart
/// Role: Database Access Layer (Repository)
/// 
/// Description:
/// Abstracts all direct interactions with Firebase Firestore. Handles CRUD (Create, Read, Update, Delete) operations and provides continuous data streams to the Providers.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -----------------------------------------
  /// Method: getAllUsers
  /// Purpose: Executes logic for getAllUsers and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map(
      (snap) => snap.docs.map(UserModel.fromFirestore).toList(),
    );
  }

  /// -----------------------------------------
  /// Method: getUsersByRole
  /// Purpose: Executes logic for getUsersByRole and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  /// -----------------------------------------
  /// Method: getUserById
  /// Purpose: Executes logic for getUserById and handles state or UI updates.
  /// -----------------------------------------
  Future<UserModel?> getUserById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  /// -----------------------------------------
  /// Method: getUserByEmail
  /// Purpose: Executes logic for getUserByEmail and handles state or UI updates.
  /// -----------------------------------------
  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromFirestore(query.docs.first);
    }
    return null;
  }

  /// -----------------------------------------
  /// Method: updateUser
  /// Purpose: Executes logic for updateUser and handles state or UI updates.
  /// -----------------------------------------
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(id).update(data);
  }

  /// -----------------------------------------
  /// Method: deleteUser
  /// Purpose: Executes logic for deleteUser and handles state or UI updates.
  /// -----------------------------------------
  Future<void> deleteUser(String id) async {
    await _firestore.collection('users').doc(id).delete();
  }

  /// -----------------------------------------
  /// Method: assignSupervisor
  /// Purpose: Executes logic for assignSupervisor and handles state or UI updates.
  /// -----------------------------------------
  Future<void> assignSupervisor(String studentId, String supervisorId) async {
    await _firestore.collection('users').doc(studentId).update({
      'supervisorId': supervisorId,
    });
  }
}
