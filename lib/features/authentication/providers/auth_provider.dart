import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Un estado básico para la autenticación real con Firebase
class AuthState {
  final bool isAuthenticated;
  final bool isAdmin; // Nuevo campo
  final String? userId; // Agregamos el UID de Firebase
  final String? userName;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isAdmin = false,
    this.userId,
    this.userName,
    this.error,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthNotifier() : super(const AuthState()) {
    // Escuchar cambios en el estado de autenticación de forma reactiva
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        final adminEmailsStr = dotenv.env['ADMIN_EMAIL'] ?? '';
        final adminEmailsList = adminEmailsStr
            .split(',')
            .map((e) => e.trim())
            .toList();
        final bool isAdmin =
            user.email != null && adminEmailsList.contains(user.email);

        state = AuthState(
          isAuthenticated: true,
          isAdmin: isAdmin,
          userId: user.uid,
          userName: user.isAnonymous ? 'Invitado' : (user.email ?? 'Usuario'),
        );
      } else {
        state = const AuthState(isAuthenticated: false);
      }
    });
  }

  // Login real con Firebase
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await FirebaseAnalytics.instance.logLogin(loginMethod: 'email');
    } on FirebaseAuthException catch (e) {
      state = AuthState(isAuthenticated: false, error: e.message);
      rethrow;
    }
  }

  // Login con Google
  Future<void> loginWithGoogle() async {
    try {
      final String? clientId =
          kIsWeb ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null;
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn(clientId: clientId).signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await FirebaseAnalytics.instance.logLogin(loginMethod: 'google');
    } catch (e) {
      state = AuthState(isAuthenticated: false, error: e.toString());
      rethrow;
    }
  }

  // Acceso como invitado real con Firebase
  Future<void> loginAsGuest() async {
    try {
      await _auth.signInAnonymously();
      await FirebaseAnalytics.instance.logLogin(loginMethod: 'anonymous');
    } on FirebaseAuthException catch (e) {
      state = AuthState(isAuthenticated: false, error: e.message);
      rethrow;
    }
  }

  // Registro real con Firebase
  Future<void> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
    } on FirebaseAuthException catch (e) {
      state = AuthState(isAuthenticated: false, error: e.message);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await FirebaseAnalytics.instance.logEvent(name: 'logout');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
