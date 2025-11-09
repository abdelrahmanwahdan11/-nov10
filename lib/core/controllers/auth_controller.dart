import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isGuest = false;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  String? get email => _email;

  Future<void> signIn({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _email = email;
    _isGuest = false;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> signUp({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _email = email;
    _isGuest = false;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> signInAsGuest() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _email = null;
    _isGuest = true;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    _email = null;
    _isGuest = false;
    _isAuthenticated = false;
    notifyListeners();
  }
}
