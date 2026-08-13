import 'dart:async';

import '../core/constants/user_role.dart';
import '../models/app_user_model.dart';

class AuthService {
  final StreamController<AppUserModel?> _authController =
      StreamController<AppUserModel?>.broadcast();

  AppUserModel? _currentUser;

  Stream<AppUserModel?> get authStateChanges => _authController.stream;

  Future<AppUserModel?> getCurrentAppUser() async => _currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // Version 1 uses mock login so the UI can run before Firebase Auth setup.
    // Later: replace this with FirebaseAuth.instance.signInWithEmailAndPassword.
    _currentUser = AppUserModel(
      uid: 'mock-staff-user',
      fullName: 'Nhân viên trực',
      email: email.trim().isEmpty ? 'staff@example.com' : email.trim(),
      role: UserRole.manager,
      isActive: true,
    );
    _authController.add(_currentUser);
  }

  Future<void> signOut() async {
    // Later: call FirebaseAuth.instance.signOut().
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}
