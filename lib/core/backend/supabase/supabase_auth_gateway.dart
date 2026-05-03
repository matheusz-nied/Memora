import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/backend_constants.dart';
import '../contracts/auth_gateway.dart';
import '../models/backend_exception.dart';
import '../models/backend_session.dart';
import '../models/backend_user.dart';

class SupabaseAuthGateway implements AuthGateway {
  const SupabaseAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  Stream<BackendSession?> get authStateChanges {
    return _client.auth.onAuthStateChange.map(
      (event) => _sessionFromSupabase(event.session),
    );
  }

  @override
  BackendSession? get currentSession {
    return _sessionFromSupabase(_client.auth.currentSession);
  }

  @override
  Future<BackendSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = _sessionFromSupabase(response.session);
      if (session == null) {
        throw const BackendException('Não foi possível entrar.');
      }
      return session;
    } on AuthException catch (error) {
      throw BackendException(_readableSupabaseAuthError(error));
    }
  }

  @override
  Future<BackendSession?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final trimmedDisplayName = displayName?.trim();
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: BackendConstants.kAuthRedirectUrl,
        data: trimmedDisplayName == null || trimmedDisplayName.isEmpty
            ? null
            : {'display_name': trimmedDisplayName, 'name': trimmedDisplayName},
      );
      return _sessionFromSupabase(response.session);
    } on AuthException catch (error) {
      throw BackendException(_readableSupabaseAuthError(error));
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: BackendConstants.kAuthRedirectUrl,
      );
    } on AuthException catch (error) {
      throw BackendException(_readableSupabaseAuthError(error));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw BackendException(_readableSupabaseAuthError(error));
    }
  }

  BackendSession? _sessionFromSupabase(Session? session) {
    if (session == null) {
      return null;
    }

    final metadata = session.user.userMetadata;
    final displayName =
        metadata?['display_name']?.toString() ?? metadata?['name']?.toString();

    return BackendSession(
      accessToken: session.accessToken,
      user: BackendUser(
        id: session.user.id,
        email: session.user.email,
        displayName: displayName,
      ),
    );
  }
}

String _readableSupabaseAuthError(AuthException error) {
  final message = error.message.toLowerCase();

  if (message.contains('invalid login credentials')) {
    return 'Email ou senha inválidos.';
  }
  if (message.contains('email not confirmed') ||
      message.contains('email_not_confirmed')) {
    return 'Confirme seu email antes de entrar.';
  }
  if (message.contains('user already registered') ||
      message.contains('already registered') ||
      message.contains('already exists')) {
    return 'Este email já está cadastrado.';
  }
  if (message.contains('password') &&
      (message.contains('weak') ||
          message.contains('short') ||
          message.contains('at least'))) {
    return 'Use uma senha mais forte.';
  }
  if (message.contains('rate limit') ||
      message.contains('security purposes') ||
      message.contains('too many')) {
    return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
  }
  if (message.contains('network') || message.contains('connection')) {
    return 'Sem conexão com o backend. Verifique sua internet e tente novamente.';
  }

  return error.message;
}
