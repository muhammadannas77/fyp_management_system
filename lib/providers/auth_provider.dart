import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _currentUser;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get error => _error;
  bool get loading => _loading;

  AuthProvider() {
    _authRepo.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
      return;
    }

    try {
      final userModel = await _authRepo.getUserById(firebaseUser.uid);
      if (userModel != null) {
        if (!userModel.isActive) {
          await _authRepo.signOut();
          _status = AuthStatus.unauthenticated;
          _currentUser = null;
        } else {
          _currentUser = userModel;
          _status = AuthStatus.authenticated;
        }
      } else {
        // Auth user exists but no Firestore doc — treat as unauthenticated
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authRepo.signIn(email, password);
      if (user != null) {
        if (!user.isActive) {
          await _authRepo.signOut();
          _error = 'Your account is deactivated. Please contact administrator.';
          _loading = false;
          notifyListeners();
          return false;
        }

        _currentUser = user;
        _status = AuthStatus.authenticated;
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = 'Login failed. Please check credentials.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'No account found for this email.';
          break;
        case 'wrong-password':
          _error = 'Incorrect password.';
          break;
        case 'invalid-email':
          _error = 'Invalid email address.';
          break;
        case 'user-disabled':
          _error = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          _error = 'Too many attempts. Try again later.';
          break;
        default:
          _error = e.message ?? 'Login failed.';
      }
    } catch (e) {
      _error = 'An unexpected error occurred.';
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final cu = _authRepo.currentUser;
    if (cu == null) return;
    try {
      final user = await _authRepo.getUserById(cu.uid);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
