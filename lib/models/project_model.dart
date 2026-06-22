/// ------------------------------------------------------------------
/// File: project_model.dart
/// Role: Data Model
/// 
/// Description:
/// Defines the data structure and schema for Firestore database synchronization. Converts raw JSON/Map NoSQL data into strongly-typed Dart objects for use throughout the application.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String studentId;
  final String supervisorId;
  final String title;
  final int currentPhase;
  final String status;
  final DateTime createdAt;
  final bool isArchived;
  final bool isDeleted;
  final DateTime? archivedAt;

  ProjectModel({
    required this.id,
    required this.studentId,
    required this.supervisorId,
    required this.title,
    required this.currentPhase,
    required this.status,
    required this.createdAt,
    this.isArchived = false,
    this.isDeleted = false,
    this.archivedAt,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      supervisorId: data['supervisorId'] ?? '',
      title: data['title'] ?? '',
      currentPhase: data['currentPhase'] ?? 1,
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isArchived: data['isArchived'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'supervisorId': supervisorId,
      'title': title,
      'currentPhase': currentPhase,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      if (archivedAt != null) 'archivedAt': Timestamp.fromDate(archivedAt!),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? studentId,
    String? supervisorId,
    String? title,
    int? currentPhase,
    String? status,
    DateTime? createdAt,
    bool? isArchived,
    bool? isDeleted,
    DateTime? archivedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      supervisorId: supervisorId ?? this.supervisorId,
      title: title ?? this.title,
      currentPhase: currentPhase ?? this.currentPhase,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
