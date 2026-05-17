import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_provider.dart';
import '../../core/backend/contracts/auth_gateway.dart';
import '../../core/backend/models/backend_exception.dart';
import '../../core/backend/models/backend_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(backendClientProvider).auth);
});

final authStateProvider = StreamProvider<BackendSession?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return Stream<BackendSession?>.multi((controller) {
    controller.add(auth.currentSession);
    final subscription = auth.authStateChanges.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });
});

class AuthRepository {
  const AuthRepository(this._authGateway);

  final AuthGateway _authGateway;

  Stream<BackendSession?> get authStateChanges => _authGateway.authStateChanges;

  BackendSession? get currentSession => _authGateway.currentSession;

  Future<BackendSession> signIn({
    required String email,
    required String password,
  }) {
    return _authGateway.signInWithEmail(
      email: email.trim(),
      password: password,
    );
  }

  Future<BackendSession?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _authGateway.signUpWithEmail(
      email: email.trim(),
      password: password,
      displayName: displayName?.trim(),
    );
  }

  Future<void> resetPassword(String email) {
    return _authGateway.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() {
    return _authGateway.signOut();
  }
}

String readableAuthError(Object error) {
  if (error is BackendException) {
    return error.message;
  }

  final message = error.toString();
  if (message.trim().isEmpty) {
    return 'Não foi possível concluir a ação. Tente novamente.';
  }

  return message.replaceFirst('Exception: ', '');
}
