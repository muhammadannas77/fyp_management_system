import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

// ─── AdminProvider ────────────────────────────────────────────────────────────
class AdminProvider extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  final ProjectRepository _projectRepo = ProjectRepository();
  final AuthRepository _authRepo = AuthRepository();
  final AuditTrailRepository _auditRepo = AuditTrailRepository();
  final NotificationRepository _notifRepo = NotificationRepository();

  List<UserModel> _students = [];
  List<UserModel> _supervisors = [];
  List<UserModel> _allUsers = [];
  List<ProjectModel> _projects = [];
  bool _loading = false;
  String? _error;
  bool _isListening = false;

  StreamSubscription<List<UserModel>>? _usersSub;
  StreamSubscription<List<ProjectModel>>? _projectsSub;

  List<UserModel> get students => _students;
  List<UserModel> get supervisors => _supervisors;
  List<UserModel> get allUsers => _allUsers;
  List<ProjectModel> get projects => _projects;
  bool get loading => _loading;
  String? get error => _error;

  int get totalStudents => _students.length;
  int get totalSupervisors => _supervisors.length;
  int get totalProjects => _projects.length;

  void startListening() {
    if (_isListening) return; // prevent duplicate subscriptions
    _isListening = true;

    _usersSub = _userRepo.getAllUsers().listen(
      (users) {
        _allUsers = users;
        _students = users.where((u) => u.isStudent).toList();
        _supervisors = users.where((u) => u.isSupervisor).toList();
        notifyListeners();
      },
      onError: (_) {},
    );

    _projectsSub = _projectRepo.getAllProjects().listen(
      (projects) {
        _projects = projects;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void stopListening() {
    _usersSub?.cancel();
    _projectsSub?.cancel();
    _isListening = false;
    _students = [];
    _supervisors = [];
    _allUsers = [];
    _projects = [];
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? supervisorId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authRepo.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        supervisorId: supervisorId,
      );
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e.code);
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to create user. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'User creation failed. Try again.';
    }
  }

  Future<bool> createProject({
    required String studentId,
    required String supervisorId,
    required String title,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Check student doesn't already have a project
      final existingProject =
          await _projectRepo.getProjectByStudentIdOnce(studentId);
      if (existingProject != null) {
        _error = 'This student already has an assigned project.';
        _loading = false;
        notifyListeners();
        return false;
      }

      final project = await _projectRepo.createProject(
        studentId: studentId,
        supervisorId: supervisorId,
        title: title,
      );

      final student = _students.cast<UserModel?>().firstWhere(
            (s) => s?.id == studentId,
            orElse: () => null,
          );

      await Future.wait([
        _auditRepo.addAuditEntry(
          projectId: project.id,
          phaseNo: 0,
          action: 'project_created',
          performedBy: 'admin',
          role: 'admin',
          message:
              'Project "$title" created for ${student?.name ?? 'student'}',
        ),
        _notifRepo.sendNotification(
          userId: studentId,
          message: 'Your FYP project "$title" has been created. Phase 1 is ready.',
          type: 'project_created',
          projectId: project.id,
          phaseNo: 1,
        ),
        _notifRepo.sendNotification(
          userId: supervisorId,
          message: 'You have been assigned as supervisor for "$title".',
          type: 'supervisor_assigned',
          projectId: project.id,
          phaseNo: 1,
        ),
      ]);

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create project. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignSupervisor({
    required String studentId,
    required String supervisorId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _userRepo.assignSupervisor(studentId, supervisorId);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to assign supervisor.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _userRepo.deleteUser(userId);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete user.';
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
    _usersSub?.cancel();
    _projectsSub?.cancel();
    super.dispose();
  }
}

// ─── NotificationProvider ─────────────────────────────────────────────────────
class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notifRepo = NotificationRepository();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<List<NotificationModel>>? _sub;
  String? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void startListening(String userId) {
    // Don't restart if already listening to same user
    if (_currentUserId == userId && _sub != null) return;
    _currentUserId = userId;
    _sub?.cancel();

    _sub = _notifRepo.getNotifications(userId).listen(
      (notifs) {
        _notifications = notifs;
        _unreadCount = notifs.where((n) => !n.isRead).length;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _currentUserId = null;
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          message: _notifications[index].message,
          type: _notifications[index].type,
          projectId: _notifications[index].projectId,
          phaseNo: _notifications[index].phaseNo,
          isRead: true,
          timestamp: _notifications[index].timestamp,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
      await _notifRepo.markAsRead(notificationId);
    } catch (_) {}
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      _notifications = _notifications.map((n) {
        if (!n.isRead) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            message: n.message,
            type: n.type,
            projectId: n.projectId,
            phaseNo: n.phaseNo,
            isRead: true,
            timestamp: n.timestamp,
          );
        }
        return n;
      }).toList();
      _unreadCount = 0;
      notifyListeners();

      await _notifRepo.markAllAsRead(userId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
