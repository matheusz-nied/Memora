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
    String? displayName,
  });

  Future<void> resetPasswordForEmail(String email);

  Future<void> signOut();

  /// Exclui a conta e todos os dados remotos do usuário, de forma permanente.
  ///
  /// Exigido pela App Store para qualquer app que crie conta. Ao voltar, a
  /// sessão já está encerrada.
  Future<void> deleteAccount();
}
