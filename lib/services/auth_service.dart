import 'package:administradores_diaz_ph/models/user_role.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      await _saveUserSession(userCredential.user?.uid);
      return userCredential.user;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _clearUserSession();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> _saveUserSession(String? userId) async {
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
    }
  }

  Future<void> _clearUserSession() async {
    await _sharedPreferencesService.clearPrefs();
  }

  Future<String?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<UserRole?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? roleString = prefs.getString('rol');
    if (roleString != null) {
      switch (roleString) {
        case 'ADMINISTRADOR':
          return UserRole.admin;
        case 'SUPERADMINISTRADOR':
          return UserRole.superadmin;
        case 'CLIENTE':
          return UserRole.user;
      }
    }
    return null;
  }

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  String getCurrentUserId() {
    final currentUser = _firebaseAuth.currentUser;
    return currentUser?.uid ?? '';
  }
}
