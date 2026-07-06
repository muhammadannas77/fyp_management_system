/// ------------------------------------------------------------------
/// File: phase_repository.dart
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

class PhaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -----------------------------------------
  /// Method: getPhasesByProjectId
  /// Purpose: Executes logic for getPhasesByProjectId and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<PhaseModel>> getPhasesByProjectId(String projectId) {
    return _firestore
        .collection('phases')
        .where('projectId', isEqualTo: projectId)
        .orderBy('phaseNo')
        .snapshots()
        .map((snap) => snap.docs.map(PhaseModel.fromFirestore).toList());
  }

  /// -----------------------------------------
  /// Method: getPhaseByProjectAndNumber
  /// Purpose: Executes logic for getPhaseByProjectAndNumber and handles state or UI updates.
  /// -----------------------------------------
  Future<PhaseModel?> getPhaseByProjectAndNumber(
      String projectId, int phaseNo) async {
    final snap = await _firestore
        .collection('phases')
        .where('projectId', isEqualTo: projectId)
        .where('phaseNo', isEqualTo: phaseNo)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PhaseModel.fromFirestore(snap.docs.first);
  }

  /// -----------------------------------------
  /// Method: getPhaseById
  /// Purpose: Executes logic for getPhaseById and handles state or UI updates.
  /// -----------------------------------------
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

  Future<bool> unlockNextPhase({
    required String projectId,
    required int nextPhaseNo,
  }) async {
    final snap = await _firestore
        .collection('phases')
        .where('projectId', isEqualTo: projectId)
        .where('phaseNo', isEqualTo: nextPhaseNo)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return false;
    await snap.docs.first.reference.update({
      'status': 'pending_submission',
      'unlocked': true,
    });
    return true;
  }

  /// -----------------------------------------
  /// Method: updatePhase
  /// Purpose: Executes logic for updatePhase and handles state or UI updates.
  /// -----------------------------------------
  Future<void> updatePhase(String id, Map<String, dynamic> data) async {
    await _firestore.collection('phases').doc(id).update(data);
  }

  Future<void> saveCustomPhases({
    required String projectId,
    required List<PhaseModel> phases,
    required List<String> deletedPhaseIds,
    required int currentPhase,
  }) async {
    final existingPhases = await _firestore
        .collection('phases')
        .where('projectId', isEqualTo: projectId)
        .get();

    bool isFirstPhaseEver = existingPhases.docs.isEmpty;
    final hasActivePhase = existingPhases.docs.any((doc) {
      final status = doc.data()['status'] as String? ?? 'locked';
      return status != 'locked';
    });
    if (hasActivePhase) isFirstPhaseEver = false;

    final batch = _firestore.batch();

    // Delete removed phases
    for (final id in deletedPhaseIds) {
      if (id.isNotEmpty) {
        batch.delete(_firestore.collection('phases').doc(id));
      }
    }

    // Add or update phases
    for (int i = 0; i < phases.length; i++) {
      final phase = phases[i];
      final docRef = phase.id.isEmpty
          ? _firestore.collection('phases').doc()
          : _firestore.collection('phases').doc(phase.id);

      final data = phase.toMap();
      data['projectId'] = projectId;
      data['phaseNo'] = i + 1;

      // If new, add creation fields
      if (phase.id.isEmpty) {
        data['status'] = isFirstPhaseEver ? 'pending_submission' : 'locked';
        data['unlocked'] = isFirstPhaseEver;
        data['createdAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, data);
        isFirstPhaseEver = false;
      } else {
        // Only update editable fields to prevent overwriting submissions, status, or timestamps
        final updateData = <String, dynamic>{
          'phaseNo': i + 1,
          'title': phase.title,
          'duration': phase.duration,
          'description': phase.description,
          'requirements': phase.requirements,
          'deadline': phase.deadline != null
              ? Timestamp.fromDate(phase.deadline!)
              : null,
          'requireText': phase.requireText,
          'requireFile': phase.requireFile,
          'requireImage': phase.requireImage,
          'requireLink': phase.requireLink,
        };
        batch.update(docRef, updateData);
      }
    }

    await batch.commit();
  }
}
