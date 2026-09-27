import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    _authSubscription = _authService.authStateChanges.listen((_) {
      loadCurrentUser();
    });
    loadCurrentUser();
  }

  final AuthService _authService;
  StreamSubscription<dynamic>? _authSubscription;

  AppUserModel? currentUser;
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadCurrentUser() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.getCurrentAppUser();
    } catch (error) {
      errorMessage = error.toString();
      currentUser = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(username: username, password: password);
      await loadCurrentUser();
      return currentUser != null;
    } catch (error) {
      errorMessage = error.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authService.dispose();
    super.dispose();
  }
}
