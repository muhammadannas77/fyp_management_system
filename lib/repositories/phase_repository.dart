import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class PhaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PhaseModel>> getPhasesByProjectId(String projectId) {
    return _firestore
        .collection('phases')
        .where('projectId', isEqualTo: projectId)
        .orderBy('phaseNo')
        .snapshots()
        .map((snap) => snap.docs.map(PhaseModel.fromFirestore).toList());
  }

  Future<PhaseModel?> getPhaseByProjectAndNumber(String projectId, int phaseNo) async {
    final snap = await _firestore
        .collection('phases')
        .where('projectId', isEqualTo: projectId)
        .where('phaseNo', isEqualTo: phaseNo)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PhaseModel.fromFirestore(snap.docs.first);
  }

  Future<PhaseModel?> getPhaseById(String id) async {
    final doc = await _firestore.collection('phases').doc(id).get();
    if (doc.exists) return PhaseModel.fromFirestore(doc);
    return null;
  }

  Future<void> submitPhase({
    required String phaseId,
    required String submissionText,
    String? fileUrl,
    String? fileName,
    String? githubUrl,
    List<String>? screenshots,
    String? presentationUrl,
    String? presentationName,
    String? testCasesUrl,
    String? testCasesName,
    String? demoVideoUrl,
    String? finalProjectLink,
    required String submittedBy,
    required bool isResubmission,
  }) async {
    final data = <String, dynamic>{
      'submissionText': submissionText,
      'fileUrl': fileUrl,
      'fileName': fileName,
      if (githubUrl != null) 'githubUrl': githubUrl,
      if (screenshots != null) 'screenshots': screenshots,
      if (presentationUrl != null) 'presentationUrl': presentationUrl,
      if (presentationName != null) 'presentationName': presentationName,
      if (testCasesUrl != null) 'testCasesUrl': testCasesUrl,
      if (testCasesName != null) 'testCasesName': testCasesName,
      if (demoVideoUrl != null) 'demoVideoUrl': demoVideoUrl,
      if (finalProjectLink != null) 'finalProjectLink': finalProjectLink,
      'submittedBy': submittedBy,
      'status': 'submitted',
    };
    if (isResubmission) {
      data['resubmittedAt'] = FieldValue.serverTimestamp();
    } else {
      data['submittedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('phases').doc(phaseId).update(data);
  }

  Future<void> approvePhase({
    required String phaseId,
    required String reviewedBy,
  }) async {
    await _firestore.collection('phases').doc(phaseId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
    });
  }

  Future<void> requestChanges({
    required String phaseId,
    required String reason,
    required String reviewedBy,
  }) async {
    await _firestore.collection('phases').doc(phaseId).update({
      'status': 'changes_requested',
      'changeRequestReason': reason,
      'changesRequestedAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
    });
  }

  Future<void> unlockNextPhase({
    required String projectId,
    required int nextPhaseNo,
  }) async {
    final snap = await _firestore
        .collection('phases')
        .where('projectId', isEqualTo: projectId)
        .where('phaseNo', isEqualTo: nextPhaseNo)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.update({
      'status': 'pending_submission',
      'unlocked': true,
    });
  }

  Future<void> updatePhase(String id, Map<String, dynamic> data) async {
    await _firestore.collection('phases').doc(id).update(data);
  }
}
