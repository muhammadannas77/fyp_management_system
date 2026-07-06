/// ------------------------------------------------------------------
/// File: other_providers.dart
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
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<ProjectModel> _archivedProjects = [];
  bool _loading = false;
  String? _error;
  bool _isListening = false;

  StreamSubscription<List<UserModel>>? _usersSub;
  StreamSubscription<List<ProjectModel>>? _projectsSub;

  List<UserModel> get students => _students;
  List<UserModel> get supervisors => _supervisors;
  List<UserModel> get allUsers => _allUsers;
  List<ProjectModel> get projects => _projects;
  List<ProjectModel> get archivedProjects => _archivedProjects;
  bool get loading => _loading;
  String? get error => _error;

  int get totalStudents => _students.length;
  int get totalSupervisors => _supervisors.length;
  int get totalProjects => _projects.length;

  /// -----------------------------------------
  /// Method: startListening
  /// Purpose: Executes logic for startListening and handles state or UI updates.
  /// -----------------------------------------
  void startListening() {
    if (_isListening) return; // prevent duplicate subscriptions
    _isListening = true;

    _usersSub = _userRepo.getAllUsers().listen(
      (users) {
        _allUsers = users.where((u) => u.isActive).toList();
        _allUsers.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        _students = _allUsers.where((u) => u.isStudent).toList();
        _supervisors = _allUsers.where((u) => u.isSupervisor).toList();
        notifyListeners();
      },
      onError: (_) {},
    );

    _projectsSub = _projectRepo.getAllProjects().listen(
      (projects) {
        _projects = projects.where((p) => !p.isDeleted && !p.isArchived).toList();
        _archivedProjects = projects.where((p) => !p.isDeleted && p.isArchived).toList();
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// -----------------------------------------
  /// Method: stopListening
  /// Purpose: Executes logic for stopListening and handles state or UI updates.
  /// -----------------------------------------
  void stopListening() {
    _usersSub?.cancel();
    _projectsSub?.cancel();
    _isListening = false;
    _students = [];
    _supervisors = [];
    _allUsers = [];
    _projects = [];
    _archivedProjects = [];
  }

  Future<String?> createUser({
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
      final existingUser = await _userRepo.getUserByEmail(email);
      if (existingUser != null) {
        if (!existingUser.isActive) {
          await _userRepo.updateUser(existingUser.id, {
            'isActive': true,
            'name': name,
            'role': role,
            'updatedAt': FieldValue.serverTimestamp(),
            'reactivatedAt': FieldValue.serverTimestamp(),
          });
          _loading = false;
          notifyListeners();
          return 'User reactivated successfully';
        } else {
          _error = 'This user is already registered.';
          _loading = false;
          notifyListeners();
          return null;
        }
      }

      await _authRepo.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        supervisorId: supervisorId,
      );
      _loading = false;
      notifyListeners();
      return 'User created successfully';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _error = 'This user is already registered.';
      } else {
        _error = _friendlyAuthError(e.code);
      }
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to create user. Please try again.';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  /// -----------------------------------------
  /// Method: _friendlyAuthError
  /// Purpose: Executes logic for _friendlyAuthError and handles state or UI updates.
  /// -----------------------------------------
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
    String phaseType = 'generic',
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
        phaseType: phaseType,
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

  /// -----------------------------------------
  /// Method: deactivateUser
  /// Purpose: Executes logic for deactivateUser and handles state or UI updates.
  /// -----------------------------------------
  Future<bool> deactivateUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _userRepo.updateUser(userId, {
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to deactivate user.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  /// Method: updateUser
  /// Purpose: Executes logic for updateUser and handles state or UI updates.
  /// -----------------------------------------
  Future<bool> updateUser(String userId, {required String name, required String role}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _userRepo.updateUser(userId, {
        'name': name,
        'role': role,
      });
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update user.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  /// Method: updateProjectCore
  /// Purpose: Executes logic for updateProjectCore and handles state or UI updates.
  /// -----------------------------------------
  Future<bool> updateProjectCore(String projectId, {required String title, required String studentId, required String supervisorId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _projectRepo.updateProject(projectId, {
        'title': title,
        'studentId': studentId,
        'supervisorId': supervisorId,
      });
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update project.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  /// Method: archiveProject
  /// Purpose: Executes logic for archiveProject and handles state or UI updates.
  /// -----------------------------------------
  Future<bool> archiveProject(String projectId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _projectRepo.updateProject(projectId, {
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      });
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to archive project.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  /// Method: restoreProject
  /// Purpose: Executes logic for restoreProject and handles state or UI updates.
  /// -----------------------------------------
  Future<bool> restoreProject(String projectId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _projectRepo.updateProject(projectId, {
        'isArchived': false,
        'archivedAt': FieldValue.delete(),
      });
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to restore project.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  /// Method: deleteProject
  /// Purpose: Executes logic for deleteProject and handles state or UI updates.
  /// -----------------------------------------
  Future<bool> deleteProject(String projectId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _projectRepo.updateProject(projectId, {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete project.';
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

  /// -----------------------------------------
  /// Method: startListening
  /// Purpose: Executes logic for startListening and handles state or UI updates.
  /// -----------------------------------------
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

  /// -----------------------------------------
  /// Method: stopListening
  /// Purpose: Executes logic for stopListening and handles state or UI updates.
  /// -----------------------------------------
  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _currentUserId = null;
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  /// -----------------------------------------
  /// Method: markAsRead
  /// Purpose: Executes logic for markAsRead and handles state or UI updates.
  /// -----------------------------------------
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

  /// -----------------------------------------
  /// Method: markAllAsRead
  /// Purpose: Executes logic for markAllAsRead and handles state or UI updates.
  /// -----------------------------------------
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
