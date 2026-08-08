import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../contracts/auth_gateway.dart';
import '../models/backend_exception.dart';
import '../models/backend_session.dart';
import '../models/backend_user.dart';

/// Identidade do aparelho, sem servidor nenhum.
///
/// Existe porque o app inteiro é chaveado por `userId`: decks, cards e o
/// redirect do router. Um UUID persistido satisfaz todos eles e mantém as
/// features sem saber em que modo estão rodando.
class LocalAuthGateway implements AuthGateway {
  LocalAuthGateway(SharedPreferences preferences)
    : _session = BackendSession(
        user: BackendUser(
          id: preferences.getString(storageKey) ?? _fallbackId,
          displayName: localDisplayName,
        ),
        accessToken: '',
      );

  static const String storageKey = 'local_user_id';
  static const String localDisplayName = 'Perfil local';

  /// Só é usado se [ensureUserId] não tiver rodado — o que significaria um
  /// bootstrap quebrado. Vale um id estável em vez de um crash.
  static const String _fallbackId = 'local-user';

  final BackendSession _session;

  /// Cria o id na primeira execução, **antes** de qualquer tela existir.
  ///
  /// Fica no bootstrap porque `currentSession` é síncrono: gerar o UUID no
  /// meio do caminho exigiria um write sem `await`, e um app fechado nesse
  /// intervalo voltaria com outro id — ou seja, sem os decks do usuário.
  static Future<String> ensureUserId(SharedPreferences preferences) async {
    final existing = preferences.getString(storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final id = const Uuid().v4();
    await preferences.setString(storageKey, id);
    return id;
  }

  @override
  BackendSession? get currentSession => _session;

  @override
  Stream<BackendSession?> get authStateChanges =>
      Stream<BackendSession?>.value(_session);

  /// Sair não faz sentido sem conta, e o botão nem é exibido neste modo.
  /// Apagar os dados é operação de sistema (desinstalar / limpar dados).
  @override
  Future<void> signOut() async {}

  @override
  Future<BackendSession> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw _noAccounts();
  }

  @override
  Future<BackendSession?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) {
    throw _noAccounts();
  }

  @override
  Future<void> resetPasswordForEmail(String email) {
    throw _noAccounts();
  }

  @override
  Future<void> deleteAccount() {
    throw _noAccounts();
  }

  BackendException _noAccounts() {
    return const BackendException(
      'Esta versão não usa contas: seus dados ficam apenas neste aparelho.',
      code: 'accounts_unsupported',
    );
  }
}
