import 'package:supabase_flutter/supabase_flutter.dart';

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
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final session = _sessionFromSupabase(response.session);
    if (session == null) {
      throw const BackendException('Unable to sign in.');
    }
    return session;
  }

  @override
  Future<BackendSession?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return _sessionFromSupabase(response.session);
  }

  @override
  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  BackendSession? _sessionFromSupabase(Session? session) {
    if (session == null) {
      return null;
    }

    return BackendSession(
      accessToken: session.accessToken,
      user: BackendUser(id: session.user.id, email: session.user.email),
    );
  }
}
