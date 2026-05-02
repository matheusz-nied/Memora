import '../models/backend_session.dart';

abstract interface class AuthGateway {
  Stream<BackendSession?> get authStateChanges;

  BackendSession? get currentSession;

  Future<BackendSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<BackendSession?> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> resetPasswordForEmail(String email);

  Future<void> signOut();
}
