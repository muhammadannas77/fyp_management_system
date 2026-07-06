/// ------------------------------------------------------------------
/// File: project_provider.dart
/// Role: State Management (ViewModel)
/// 
/// Description:
/// Handles business logic and state management. Listens to Repository data streams and updates the UI (Screens) using the ChangeNotifier pattern. Prevents the UI from accessing the database directly.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/storage_service.dart';

/// ------------------------------------------------------------------
/// ProjectProvider (ViewModel / Controller)
/// ------------------------------------------------------------------
/// This class acts as the core "brain" for the Student and Supervisor dashboards.
/// It uses the `ChangeNotifier` to update the UI whenever data changes.
/// 
/// Key Responsibilities:
/// 1. Listening to real-time project and phase data from Firestore.
/// 2. Managing the UI state (loading indicators, error messages).
/// 3. Handling file selections and coordinating Cloudinary uploads.
/// 4. Orchestrating the complex submission and approval workflows, 
///    ensuring that Notifications and Audit Trails are generated automatically.
/// ------------------------------------------------------------------
class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _projectRepo = ProjectRepository();
  final PhaseRepository _phaseRepo = PhaseRepository();
  final AuditTrailRepository _auditRepo = AuditTrailRepository();
  final NotificationRepository _notifRepo = NotificationRepository();
  final StorageService _storageService = StorageService();

  ProjectModel? _project;
  List<PhaseModel> _phases = [];
  bool _loading = false;
  bool _phasesLoaded = false;
  String? _error;
  PlatformFile? _selectedFile;
  final List<PlatformFile> _selectedScreenshots = [];
  PlatformFile? _presentationFile;
  PlatformFile? _testCasesFile;

  StreamSubscription<ProjectModel?>? _projectSub;
  StreamSubscription<List<PhaseModel>>? _phasesSub;

  ProjectModel? get project => _project;
  List<PhaseModel> get phases => _phases;
  bool get loading => _loading;
  bool get phasesLoaded => _phasesLoaded;
  String? get error => _error;
  PlatformFile? get selectedFile => _selectedFile;
  List<PlatformFile> get selectedScreenshots => _selectedScreenshots;
  PlatformFile? get presentationFile => _presentationFile;
  PlatformFile? get testCasesFile => _testCasesFile;

  /// -----------------------------------------
  /// Method: listenToStudentProject
  /// Purpose: Executes logic for listenToStudentProject and handles state or UI updates.
  /// -----------------------------------------
  void listenToStudentProject(String studentId) {
    _projectSub?.cancel();
    _projectSub = _projectRepo.getProjectByStudentId(studentId).listen(
      (project) {
        _project = project;
        if (project != null) {
          _phasesLoaded = false; // Reset when project changes
          _listenToPhases(project.id);
        } else {
          _phases = [];
          _phasesLoaded = true;
          _phasesSub?.cancel();
          _selectedFile = null;
          _selectedScreenshots.clear();
          _presentationFile = null;
          _testCasesFile = null;
        }
        notifyListeners();
      },
      onError: (_) {
        _phasesLoaded = true;
        notifyListeners();
      },
    );
  }

  /// -----------------------------------------
  /// Method: _listenToPhases
  /// Purpose: Executes logic for _listenToPhases and handles state or UI updates.
  /// -----------------------------------------
  void _listenToPhases(String projectId) {
    _phasesSub?.cancel();
    _phasesSub = _phaseRepo.getPhasesByProjectId(projectId).listen(
      (phases) {
        _phases = phases;
        _phasesLoaded = true;
        notifyListeners();
      },
      onError: (_) {
        _phasesLoaded = true;
        notifyListeners();
      },
    );
  }

  /// -----------------------------------------
  /// Method: stopListening
  /// Purpose: Executes logic for stopListening and handles state or UI updates.
  /// -----------------------------------------
  void stopListening() {
    _projectSub?.cancel();
    _phasesSub?.cancel();
    _project = null;
    _phases = [];
    _selectedFile = null;
    _selectedScreenshots.clear();
    _presentationFile = null;
    _testCasesFile = null;
  }

  /// -----------------------------------------
  /// Method: pickFile
  /// Purpose: Executes logic for pickFile and handles state or UI updates.
  /// -----------------------------------------
  Future<void> pickFile() async {
    final file = await _storageService.pickFile();
    if (file != null) {
      _selectedFile = file;
      notifyListeners();
    }
  }

  /// -----------------------------------------
  /// Method: clearSelectedFile
  /// Purpose: Executes logic for clearSelectedFile and handles state or UI updates.
  /// -----------------------------------------
  void clearSelectedFile() {
    _selectedFile = null;
    notifyListeners();
  }

  /// -----------------------------------------
  /// Method: pickScreenshots
  /// Purpose: Executes logic for pickScreenshots and handles state or UI updates.
  /// -----------------------------------------
  Future<void> pickScreenshots() async {
    final files = await _storageService.pickImages();
    if (files.isNotEmpty) {
      _selectedScreenshots.addAll(files);
      notifyListeners();
    }
  }

  /// -----------------------------------------
  /// Method: removeScreenshot
  /// Purpose: Executes logic for removeScreenshot and handles state or UI updates.
  /// -----------------------------------------
  void removeScreenshot(int index) {
    if (index >= 0 && index < _selectedScreenshots.length) {
      _selectedScreenshots.removeAt(index);
      notifyListeners();
    }
  }

  /// -----------------------------------------
  /// Method: pickPresentationFile
  /// Purpose: Executes logic for pickPresentationFile and handles state or UI updates.
  /// -----------------------------------------
  Future<void> pickPresentationFile() async {
    final file = await _storageService.pickFile();
    if (file != null) {
      _presentationFile = file;
      notifyListeners();
    }
  }

  /// -----------------------------------------
  /// Method: clearPresentationFile
  /// Purpose: Executes logic for clearPresentationFile and handles state or UI updates.
  /// -----------------------------------------
  void clearPresentationFile() {
    _presentationFile = null;
    notifyListeners();
  }

  /// -----------------------------------------
  /// Method: pickTestCasesFile
  /// Purpose: Executes logic for pickTestCasesFile and handles state or UI updates.
  /// -----------------------------------------
  Future<void> pickTestCasesFile() async {
    final file = await _storageService.pickFile();
    if (file != null) {
      _testCasesFile = file;
      notifyListeners();
    }
  }

  /// -----------------------------------------
  /// Method: clearTestCasesFile
  /// Purpose: Executes logic for clearTestCasesFile and handles state or UI updates.
  /// -----------------------------------------
  void clearTestCasesFile() {
    _testCasesFile = null;
    notifyListeners();
  }

  Future<bool> submitPhase({
    required String phaseId,
    required String projectId,
    required int phaseNo,
    required String submissionText,
    required String studentId,
    required String supervisorId,
    required String studentName,
    required bool isResubmission,
    String? githubUrl,
    List<String>? existingScreenshots,
    String? demoVideoUrl,
    String? finalProjectLink,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      String? fileUrl;
      String? fileName;

      if (_selectedFile != null) {
        fileUrl = await _storageService.uploadFile(
          file: _selectedFile!,
          projectId: projectId,
          phaseNo: phaseNo,
        );
        fileName = _selectedFile!.name;
        if (fileUrl == null) {
          _error = 'Main file upload failed. Please try again.';
          _loading = false;
          notifyListeners();
          return false;
        }
      }

      List<String> finalScreenshots = List.from(existingScreenshots ?? []);
      for (final file in _selectedScreenshots) {
        final url = await _storageService.uploadFile(
          file: file,
          projectId: projectId,
          phaseNo: phaseNo,
        );
        if (url != null) {
          finalScreenshots.add(url);
        } else {
          _error = 'Screenshot upload failed. Please try again.';
          _loading = false;
          notifyListeners();
          return false;
        }
      }

      String? presentationUrl;
      String? presentationName;
      if (_presentationFile != null) {
        presentationUrl = await _storageService.uploadFile(
          file: _presentationFile!,
          projectId: projectId,
          phaseNo: phaseNo,
        );
        presentationName = _presentationFile!.name;
        if (presentationUrl == null) {
          _error = 'Presentation upload failed. Please try again.';
          _loading = false;
          notifyListeners();
          return false;
        }
      }

      String? testCasesUrl;
      String? testCasesName;
      if (_testCasesFile != null) {
        testCasesUrl = await _storageService.uploadFile(
          file: _testCasesFile!,
          projectId: projectId,
          phaseNo: phaseNo,
        );
        testCasesName = _testCasesFile!.name;
        if (testCasesUrl == null) {
          _error = 'Test cases upload failed. Please try again.';
          _loading = false;
          notifyListeners();
          return false;
        }
      }

      await _phaseRepo.submitPhase(
        phaseId: phaseId,
        submissionText: submissionText,
        fileUrl: fileUrl,
        fileName: fileName,
        githubUrl: githubUrl,
        screenshots: finalScreenshots.isNotEmpty ? finalScreenshots : null,
        presentationUrl: presentationUrl,
        presentationName: presentationName,
        testCasesUrl: testCasesUrl,
        testCasesName: testCasesName,
        demoVideoUrl: demoVideoUrl,
        finalProjectLink: finalProjectLink,
        submittedBy: studentId,
        isResubmission: isResubmission,
      );

      final action = isResubmission ? 'phase_resubmitted' : 'phase_submitted';
      final msg = isResubmission
          ? '$studentName resubmitted Phase $phaseNo'
          : '$studentName submitted Phase $phaseNo';

      await Future.wait([
        _auditRepo.addAuditEntry(
          projectId: projectId,
          phaseNo: phaseNo,
          action: action,
          performedBy: studentId,
          role: 'student',
          message: msg,
        ),
        _notifRepo.sendNotification(
          userId: supervisorId,
          message: msg,
          type: action,
          projectId: projectId,
          phaseNo: phaseNo,
        ),
      ]);

      _selectedFile = null;
      _selectedScreenshots.clear();
      _presentationFile = null;
      _testCasesFile = null;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Submission failed: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> approvePhase({
    required PhaseModel phase,
    required String projectId,
    required String supervisorId,
    required String supervisorName,
    required String studentId,
    required int totalPhases,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _phaseRepo.approvePhase(
          phaseId: phase.id, reviewedBy: supervisorId);

      final futures = <Future>[
        _auditRepo.addAuditEntry(
          projectId: projectId,
          phaseNo: phase.phaseNo,
          action: 'phase_approved',
          performedBy: supervisorId,
          role: 'supervisor',
          message: '$supervisorName approved Phase ${phase.phaseNo}',
        ),
        _notifRepo.sendNotification(
          userId: studentId,
          message: 'Phase ${phase.phaseNo} approved by $supervisorName',
          type: 'phase_approved',
          projectId: projectId,
          phaseNo: phase.phaseNo,
        ),
      ];

      final isCustomized = _project?.phaseType == 'customized';

      if (isCustomized) {
        final unlocked = await _phaseRepo.unlockNextPhase(
            projectId: projectId, nextPhaseNo: phase.phaseNo + 1);
        if (unlocked) {
          futures.addAll([
            _projectRepo
                .updateProject(projectId, {'currentPhase': phase.phaseNo + 1}),
            _auditRepo.addAuditEntry(
              projectId: projectId,
              phaseNo: phase.phaseNo + 1,
              action: 'phase_unlocked',
              performedBy: supervisorId,
              role: 'supervisor',
              message: 'Phase ${phase.phaseNo + 1} unlocked',
            ),
            _notifRepo.sendNotification(
              userId: studentId,
              message: 'Phase ${phase.phaseNo + 1} is now unlocked!',
              type: 'phase_unlocked',
              projectId: projectId,
              phaseNo: phase.phaseNo + 1,
            ),
          ]);
        }
      } else {
        if (phase.phaseNo < totalPhases) {
          futures.addAll([
            _phaseRepo.unlockNextPhase(
                projectId: projectId, nextPhaseNo: phase.phaseNo + 1),
            _projectRepo
                .updateProject(projectId, {'currentPhase': phase.phaseNo + 1}),
            _auditRepo.addAuditEntry(
              projectId: projectId,
              phaseNo: phase.phaseNo + 1,
              action: 'phase_unlocked',
              performedBy: supervisorId,
              role: 'supervisor',
              message: 'Phase ${phase.phaseNo + 1} unlocked',
            ),
            _notifRepo.sendNotification(
              userId: studentId,
              message: 'Phase ${phase.phaseNo + 1} is now unlocked!',
              type: 'phase_unlocked',
              projectId: projectId,
              phaseNo: phase.phaseNo + 1,
            ),
          ]);
        } else {
          futures.add(_projectRepo
              .updateProject(projectId, {'status': 'completed'}));
        }
      }

      await Future.wait(futures);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Approval failed: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestChanges({
    required PhaseModel phase,
    required String projectId,
    required String supervisorId,
    required String supervisorName,
    required String studentId,
    required String reason,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _phaseRepo.requestChanges(
          phaseId: phase.id, reason: reason, reviewedBy: supervisorId);

      await Future.wait([
        _auditRepo.addAuditEntry(
          projectId: projectId,
          phaseNo: phase.phaseNo,
          action: 'changes_requested',
          performedBy: supervisorId,
          role: 'supervisor',
          message:
              '$supervisorName requested changes on Phase ${phase.phaseNo}: $reason',
        ),
        _notifRepo.sendNotification(
          userId: studentId,
          message:
              'Changes requested for Phase ${phase.phaseNo} by $supervisorName',
          type: 'changes_requested',
          projectId: projectId,
          phaseNo: phase.phaseNo,
        ),
      ]);

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Request failed: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  /// Method: clearError
  /// Purpose: Executes logic for clearError and handles state or UI updates.
  /// -----------------------------------------
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _projectSub?.cancel();
    _phasesSub?.cancel();
    super.dispose();
  }
}
