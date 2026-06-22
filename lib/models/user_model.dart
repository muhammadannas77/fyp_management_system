/// ------------------------------------------------------------------
/// File: user_model.dart
/// Role: Data Model
/// 
/// Description:
/// Defines the data structure and schema for Firestore database synchronization. Converts raw JSON/Map NoSQL data into strongly-typed Dart objects for use throughout the application.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? supervisorId;
  final DateTime? createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.supervisorId,
    this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      supervisorId: data['supervisorId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'supervisorId': supervisorId,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? supervisorId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      supervisorId: supervisorId ?? this.supervisorId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isStudent => role == 'student';
  bool get isSupervisor => role == 'supervisor';
  bool get isAdmin => role == 'admin';
}
