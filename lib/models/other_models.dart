/// ------------------------------------------------------------------
/// File: other_models.dart
/// Role: Data Model
/// 
/// Description:
/// Defines the data structure and schema for Firestore database synchronization. Converts raw JSON/Map NoSQL data into strongly-typed Dart objects for use throughout the application.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String projectId;
  final int phaseNo;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.projectId,
    required this.phaseNo,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      phaseNo: data['phaseNo'] ?? 1,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'phaseNo': phaseNo,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String message;
  final String type;
  final String projectId;
  final int phaseNo;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    required this.projectId,
    required this.phaseNo,
    required this.isRead,
    required this.timestamp,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      projectId: data['projectId'] ?? '',
      phaseNo: data['phaseNo'] ?? 1,
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'type': type,
      'projectId': projectId,
      'phaseNo': phaseNo,
      'isRead': isRead,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class AuditTrailModel {
  final String id;
  final String projectId;
  final int phaseNo;
  final String action;
  final String performedBy;
  final String role;
  final String message;
  final DateTime timestamp;

  AuditTrailModel({
    required this.id,
    required this.projectId,
    required this.phaseNo,
    required this.action,
    required this.performedBy,
    required this.role,
    required this.message,
    required this.timestamp,
  });

  factory AuditTrailModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditTrailModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      phaseNo: data['phaseNo'] ?? 1,
      action: data['action'] ?? '',
      performedBy: data['performedBy'] ?? '',
      role: data['role'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'phaseNo': phaseNo,
      'action': action,
      'performedBy': performedBy,
      'role': role,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
