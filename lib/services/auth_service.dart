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
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();

    if (cleanUsername == 'admin' && password == '123456') {
      _currentUser = AppUserModel(
        uid: 'user-vp',
        fullName: 'Nguyễn Thị Duyên',
        email: 'duyen@gmail.com', // Keep for model consistency
        role: UserRole.manager,
        isActive: true,
      );
      _authController.add(_currentUser);
      return;
    }

    if (cleanUsername == 'staff' && password == '123456') {
      _currentUser = AppUserModel(
        uid: 'user-guard',
        fullName: 'Nhân viên',
        email: 'baove@gmail.com', // Keep for model consistency
        role: UserRole.staff,
        isActive: true,
      );
      _authController.add(_currentUser);
      return;
    }

    throw Exception('Tên đăng nhập hoặc mật khẩu không đúng');
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
