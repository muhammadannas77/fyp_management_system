/// ------------------------------------------------------------------
/// File: other_repositories.dart
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

class CommentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -----------------------------------------
  /// Method: getComments
  /// Purpose: Executes logic for getComments and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<CommentModel>> getComments(String projectId, int phaseNo) {
    return _firestore
        .collection('comments')
        .where('projectId', isEqualTo: projectId)
        .where('phaseNo', isEqualTo: phaseNo)
        .snapshots()
        .map((snap) {
      final comments = snap.docs.map(CommentModel.fromFirestore).toList();
      comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return comments;
    });
  }

  Future<void> addComment({
    required String projectId,
    required int phaseNo,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String message,
  }) async {
    await _firestore.collection('comments').add({
      'projectId': projectId,
      'phaseNo': phaseNo,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -----------------------------------------
  /// Method: getNotifications
  /// Purpose: Executes logic for getNotifications and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  /// -----------------------------------------
  /// Method: getUnreadCount
  /// Purpose: Executes logic for getUnreadCount and handles state or UI updates.
  /// -----------------------------------------
  Future<int> getUnreadCount(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return snap.docs.length;
  }

  Future<void> sendNotification({
    required String userId,
    required String message,
    required String type,
    required String projectId,
    required int phaseNo,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'message': message,
      'type': type,
      'projectId': projectId,
      'phaseNo': phaseNo,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// -----------------------------------------
  /// Method: markAsRead
  /// Purpose: Executes logic for markAsRead and handles state or UI updates.
  /// -----------------------------------------
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// -----------------------------------------
  /// Method: markAllAsRead
  /// Purpose: Executes logic for markAllAsRead and handles state or UI updates.
  /// -----------------------------------------
  Future<void> markAllAsRead(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

class AuditTrailRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -----------------------------------------
  /// Method: getAuditTrail
  /// Purpose: Executes logic for getAuditTrail and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<AuditTrailModel>> getAuditTrail(String projectId) {
    return _firestore
        .collection('audit_trails')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AuditTrailModel.fromFirestore).toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  /// -----------------------------------------
  /// Method: getAuditTrailByPhase
  /// Purpose: Executes logic for getAuditTrailByPhase and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<AuditTrailModel>> getAuditTrailByPhase(String projectId, int phaseNo) {
    return _firestore
        .collection('audit_trails')
        .where('projectId', isEqualTo: projectId)
        .where('phaseNo', isEqualTo: phaseNo)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AuditTrailModel.fromFirestore).toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  Future<void> addAuditEntry({
    required String projectId,
    required int phaseNo,
    required String action,
    required String performedBy,
    required String role,
    required String message,
  }) async {
    await _firestore.collection('audit_trails').add({
      'projectId': projectId,
      'phaseNo': phaseNo,
      'action': action,
      'performedBy': performedBy,
      'role': role,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
