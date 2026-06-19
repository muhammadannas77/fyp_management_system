import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map(
      (snap) => snap.docs.map(UserModel.fromFirestore).toList(),
    );
  }

  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(id).update(data);
  }

  Future<void> deleteUser(String id) async {
    await _firestore.collection('users').doc(id).delete();
  }

  Future<void> assignSupervisor(String studentId, String supervisorId) async {
    await _firestore.collection('users').doc(studentId).update({
      'supervisorId': supervisorId,
    });
  }
}
