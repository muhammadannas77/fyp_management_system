import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class CommentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

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

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

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

  Stream<List<AuditTrailModel>> getAuditTrail(String projectId) {
    return _firestore
        .collection('audit_trails')
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AuditTrailModel.fromFirestore).toList());
  }

  Stream<List<AuditTrailModel>> getAuditTrailByPhase(String projectId, int phaseNo) {
    return _firestore
        .collection('audit_trails')
        .where('projectId', isEqualTo: projectId)
        .where('phaseNo', isEqualTo: phaseNo)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AuditTrailModel.fromFirestore).toList());
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
