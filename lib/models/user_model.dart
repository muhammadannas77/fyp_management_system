import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? supervisorId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.supervisorId,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      supervisorId: data['supervisorId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'supervisorId': supervisorId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? supervisorId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      supervisorId: supervisorId ?? this.supervisorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isStudent => role == 'student';
  bool get isSupervisor => role == 'supervisor';
  bool get isAdmin => role == 'admin';
}
