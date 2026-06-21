import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/storage_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _projectRepo = ProjectRepository();
  final PhaseRepository _phaseRepo = PhaseRepository();
  final AuditTrailRepository _auditRepo = AuditTrailRepository();
  final NotificationRepository _notifRepo = NotificationRepository();
  final StorageService _storageService = StorageService();

  ProjectModel? _project;
  List<PhaseModel> _phases = [];
  bool _loading = false;
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
  String? get error => _error;
  PlatformFile? get selectedFile => _selectedFile;
  List<PlatformFile> get selectedScreenshots => _selectedScreenshots;
  PlatformFile? get presentationFile => _presentationFile;
  PlatformFile? get testCasesFile => _testCasesFile;

  void listenToStudentProject(String studentId) {
    _projectSub?.cancel();
    _projectSub = _projectRepo.getProjectByStudentId(studentId).listen(
      (project) {
        _project = project;
        if (project != null) {
          _listenToPhases(project.id);
        } else {
          _phases = [];
          _phasesSub?.cancel();
          _selectedFile = null;
          _selectedScreenshots.clear();
          _presentationFile = null;
          _testCasesFile = null;
        }
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void _listenToPhases(String projectId) {
    _phasesSub?.cancel();
    _phasesSub = _phaseRepo.getPhasesByProjectId(projectId).listen(
      (phases) {
        _phases = phases;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

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

  Future<void> pickFile() async {
    final file = await _storageService.pickFile();
    if (file != null) {
      _selectedFile = file;
      notifyListeners();
    }
  }

  void clearSelectedFile() {
    _selectedFile = null;
    notifyListeners();
  }

  Future<void> pickScreenshots() async {
    final files = await _storageService.pickImages();
    if (files.isNotEmpty) {
      _selectedScreenshots.addAll(files);
      notifyListeners();
    }
  }

  void removeScreenshot(int index) {
    if (index >= 0 && index < _selectedScreenshots.length) {
      _selectedScreenshots.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> pickPresentationFile() async {
    final file = await _storageService.pickFile();
    if (file != null) {
      _presentationFile = file;
      notifyListeners();
    }
  }

  void clearPresentationFile() {
    _presentationFile = null;
    notifyListeners();
  }

  Future<void> pickTestCasesFile() async {
    final file = await _storageService.pickFile();
    if (file != null) {
      _testCasesFile = file;
      notifyListeners();
    }
  }

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
          _error = 'File upload failed. Submitting without file.';
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
