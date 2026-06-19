import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String studentId;
  final String supervisorId;
  final String title;
  final int currentPhase;
  final String status;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.studentId,
    required this.supervisorId,
    required this.title,
    required this.currentPhase,
    required this.status,
    required this.createdAt,
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
  }) {
    return ProjectModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      supervisorId: supervisorId ?? this.supervisorId,
      title: title ?? this.title,
      currentPhase: currentPhase ?? this.currentPhase,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
