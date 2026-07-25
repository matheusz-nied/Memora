import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_provider.dart';
import '../../core/backend/contracts/auth_gateway.dart';
import '../../core/backend/models/backend_exception.dart';
import '../../core/backend/models/backend_session.dart';
import '../../core/database/app_database.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(backendClientProvider).auth,
    database: ref.watch(appDatabaseProvider),
  );
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
  const AuthRepository(this._authGateway, {required AppDatabase database})
    : _database = database;

  final AuthGateway _authGateway;
  final AppDatabase _database;

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

  /// Exclui a conta remota e apaga o banco local.
  ///
  /// A ordem importa: se o remoto falhar, o dispositivo continua com os dados
  /// e a conta intacta. O caminho inverso deixaria o usuário sem os cards por
  /// causa de um erro de rede.
  Future<void> deleteAccount() async {
    await _authGateway.deleteAccount();
    await clearLocalData();
  }

  /// Zera o cache local. Também usado no logout forçado, para a sessão
  /// seguinte não herdar decks de outro usuário no mesmo dispositivo.
  Future<void> clearLocalData() async {
    await _database.transaction(() async {
      await _database.delete(_database.reviewsTable).go();
      await _database.delete(_database.cardsTable).go();
      await _database.delete(_database.decksTable).go();
    });
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
