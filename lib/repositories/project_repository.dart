/// ------------------------------------------------------------------
/// File: project_repository.dart
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
import '../utils/utils.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ProjectModel> createProject({
    required String studentId,
    required String supervisorId,
    required String title,
    String phaseType = 'generic',
  }) async {
    final ref = _firestore.collection('projects').doc();

    await ref.set({
      'studentId': studentId,
      'supervisorId': supervisorId,
      'title': title,
      'currentPhase': 1,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'phaseType': phaseType,
    });

    if (phaseType == 'generic') {
      // Create all 5 phases in a batch
      final batch = _firestore.batch();
      for (final phaseData in PhaseData.allPhases) {
        final phaseRef = _firestore.collection('phases').doc();
        batch.set(phaseRef, {
          'projectId': ref.id,
          'phaseNo': phaseData['phaseNo'],
          'title': phaseData['title'],
          'duration': phaseData['duration'],
          'requirements': phaseData['requirements'],
          'status': phaseData['phaseNo'] == 1 ? 'pending_submission' : 'locked',
          'unlocked': phaseData['phaseNo'] == 1,
          'submissionText': null,
          'fileUrl': null,
          'fileName': null,
          'submittedAt': null,
          'submittedBy': null,
          'changesRequestedAt': null,
          'changeRequestReason': null,
          'resubmittedAt': null,
          'approvedAt': null,
          'reviewedAt': null,
          'reviewedBy': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    final doc = await ref.get();
    return ProjectModel.fromFirestore(doc);
  }

  // Stream version — used by student dashboard
  Stream<ProjectModel?> getProjectByStudentId(String studentId) {
    return _firestore
        .collection('projects')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final projects = snap.docs
          .map(ProjectModel.fromFirestore)
          .where((p) => !p.isDeleted && !p.isArchived)
          .toList();
      if (projects.isEmpty) return null;
      return projects.first;
    });
  }

  // One-time fetch — used by admin before creating duplicate
  Future<ProjectModel?> getProjectByStudentIdOnce(String studentId) async {
    final snap = await _firestore
        .collection('projects')
        .where('studentId', isEqualTo: studentId)
        .get();
    if (snap.docs.isEmpty) return null;
    final projects = snap.docs
        .map(ProjectModel.fromFirestore)
        .where((p) => !p.isDeleted && !p.isArchived)
        .toList();
    if (projects.isEmpty) return null;
    return projects.first;
  }

  /// -----------------------------------------
  /// Method: getProjectsBySupervisorId
  /// Purpose: Executes logic for getProjectsBySupervisorId and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<ProjectModel>> getProjectsBySupervisorId(String supervisorId) {
    return _firestore
        .collection('projects')
        .where('supervisorId', isEqualTo: supervisorId)
        .snapshots()
        .map((snap) => snap.docs
            .map(ProjectModel.fromFirestore)
            .where((p) => !p.isDeleted && !p.isArchived)
            .toList());
  }

  /// -----------------------------------------
  /// Method: getAllProjects
  /// Purpose: Executes logic for getAllProjects and handles state or UI updates.
  /// -----------------------------------------
  Stream<List<ProjectModel>> getAllProjects() {
    return _firestore
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProjectModel.fromFirestore).toList());
  }

  /// -----------------------------------------
  /// Method: getProjectById
  /// Purpose: Executes logic for getProjectById and handles state or UI updates.
  /// -----------------------------------------
  Future<ProjectModel?> getProjectById(String id) async {
    final doc = await _firestore.collection('projects').doc(id).get();
    if (doc.exists) return ProjectModel.fromFirestore(doc);
    return null;
  }

  /// -----------------------------------------
  /// Method: updateProject
  /// Purpose: Executes logic for updateProject and handles state or UI updates.
  /// -----------------------------------------
  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    await _firestore.collection('projects').doc(id).update(data);
  }
}
