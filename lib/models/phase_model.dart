/// ------------------------------------------------------------------
/// File: phase_model.dart
/// Role: Data Model
/// 
/// Description:
/// Defines the data structure and schema for Firestore database synchronization. Converts raw JSON/Map NoSQL data into strongly-typed Dart objects for use throughout the application.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

/// ------------------------------------------------------------------
/// PhaseModel (Data Structure)
/// ------------------------------------------------------------------
/// Represents a single developmental phase of a student's final year project.
/// 
/// Data Representation features:
/// 1. Lifecycle Tracking: Stores all critical timestamps (`submittedAt`, `approvedAt`, `reviewedAt`) 
///    to measure student progress and supervisor response times.
/// 2. Extensible Attachments: Explicitly handles diverse attachment types like `githubUrl`, 
///    `screenshots`, `demoVideoUrl`, and `presentationUrl` to support the unique requirements of Phase 4 and 5.
/// 3. Serialization: Contains robust `fromFirestore` and `toMap` methods to seamlessly map 
///    raw NoSQL documents into typed Dart objects.
/// ------------------------------------------------------------------
class PhaseModel {
  final String id;
  final String projectId;
  final int phaseNo;
  final String title;
  final String duration;
  final List<String> requirements;
  final String status;
  final String? submissionText;
  final String? fileUrl;
  final String? fileName;
  final String? githubUrl;
  final List<String>? screenshots;
  final String? presentationUrl;
  final String? presentationName;
  final String? testCasesUrl;
  final String? testCasesName;
  final String? demoVideoUrl;
  final String? finalProjectLink;
  final DateTime? submittedAt;
  final String? submittedBy;
  final DateTime? changesRequestedAt;
  final String? changeRequestReason;
  final DateTime? resubmittedAt;
  final DateTime? approvedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final bool unlocked;

  PhaseModel({
    required this.id,
    required this.projectId,
    required this.phaseNo,
    required this.title,
    required this.duration,
    required this.requirements,
    required this.status,
    this.submissionText,
    this.fileUrl,
    this.fileName,
    this.githubUrl,
    this.screenshots,
    this.presentationUrl,
    this.presentationName,
    this.testCasesUrl,
    this.testCasesName,
    this.demoVideoUrl,
    this.finalProjectLink,
    this.submittedAt,
    this.submittedBy,
    this.changesRequestedAt,
    this.changeRequestReason,
    this.resubmittedAt,
    this.approvedAt,
    this.reviewedAt,
    this.reviewedBy,
    required this.unlocked,
  });

  factory PhaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhaseModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      phaseNo: data['phaseNo'] ?? 1,
      title: data['title'] ?? '',
      duration: data['duration'] ?? '',
      requirements: List<String>.from(data['requirements'] ?? []),
      status: data['status'] ?? 'locked',
      submissionText: data['submissionText'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      githubUrl: data['githubUrl'],
      screenshots: data['screenshots'] != null ? List<String>.from(data['screenshots']) : null,
      presentationUrl: data['presentationUrl'],
      presentationName: data['presentationName'],
      testCasesUrl: data['testCasesUrl'],
      testCasesName: data['testCasesName'],
      demoVideoUrl: data['demoVideoUrl'],
      finalProjectLink: data['finalProjectLink'],
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      submittedBy: data['submittedBy'],
      changesRequestedAt: (data['changesRequestedAt'] as Timestamp?)?.toDate(),
      changeRequestReason: data['changeRequestReason'],
      resubmittedAt: (data['resubmittedAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      unlocked: data['unlocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'phaseNo': phaseNo,
      'title': title,
      'duration': duration,
      'requirements': requirements,
      'status': status,
      'submissionText': submissionText,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'githubUrl': githubUrl,
      'screenshots': screenshots,
      'presentationUrl': presentationUrl,
      'presentationName': presentationName,
      'testCasesUrl': testCasesUrl,
      'testCasesName': testCasesName,
      'demoVideoUrl': demoVideoUrl,
      'finalProjectLink': finalProjectLink,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'submittedBy': submittedBy,
      'changesRequestedAt': changesRequestedAt != null ? Timestamp.fromDate(changesRequestedAt!) : null,
      'changeRequestReason': changeRequestReason,
      'resubmittedAt': resubmittedAt != null ? Timestamp.fromDate(resubmittedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'unlocked': unlocked,
    };
  }

  PhaseModel copyWith({
    String? id,
    String? projectId,
    int? phaseNo,
    String? title,
    String? duration,
    List<String>? requirements,
    String? status,
    String? submissionText,
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
    DateTime? submittedAt,
    String? submittedBy,
    DateTime? changesRequestedAt,
    String? changeRequestReason,
    DateTime? resubmittedAt,
    DateTime? approvedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    bool? unlocked,
  }) {
    return PhaseModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      phaseNo: phaseNo ?? this.phaseNo,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      requirements: requirements ?? this.requirements,
      status: status ?? this.status,
      submissionText: submissionText ?? this.submissionText,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      githubUrl: githubUrl ?? this.githubUrl,
      screenshots: screenshots ?? this.screenshots,
      presentationUrl: presentationUrl ?? this.presentationUrl,
      presentationName: presentationName ?? this.presentationName,
      testCasesUrl: testCasesUrl ?? this.testCasesUrl,
      testCasesName: testCasesName ?? this.testCasesName,
      demoVideoUrl: demoVideoUrl ?? this.demoVideoUrl,
      finalProjectLink: finalProjectLink ?? this.finalProjectLink,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      changesRequestedAt: changesRequestedAt ?? this.changesRequestedAt,
      changeRequestReason: changeRequestReason ?? this.changeRequestReason,
      resubmittedAt: resubmittedAt ?? this.resubmittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  bool get isLocked => status == 'locked';
  bool get isPendingSubmission => status == 'pending_submission';
  bool get isSubmitted => status == 'submitted';
  bool get isChangesRequested => status == 'changes_requested';
  bool get isApproved => status == 'approved';

  Duration? get reviewDuration {
    if (submittedAt == null) return null;
    final endDate = approvedAt ?? changesRequestedAt;
    if (endDate == null) return null;
    return endDate.difference(submittedAt!);
  }
}
