import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/local/local_auth_gateway.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SharedPreferences> preferences() => SharedPreferences.getInstance();

  test('cria o id do aparelho na primeira execução', () async {
    final prefs = await preferences();

    expect(prefs.getString(LocalAuthGateway.storageKey), isNull);

    final id = await LocalAuthGateway.ensureUserId(prefs);

    expect(id, isNotEmpty);
    expect(prefs.getString(LocalAuthGateway.storageKey), id);
  });

  test('o id sobrevive a novas execuções', () async {
    // O que este teste protege: um id novo a cada abertura esconderia todos os
    // decks do usuário, já que tudo é filtrado por userId.
    final prefs = await preferences();
    final first = await LocalAuthGateway.ensureUserId(prefs);
    final second = await LocalAuthGateway.ensureUserId(prefs);

    expect(second, first);
    expect(LocalAuthGateway(prefs).currentSession?.user.id, first);
  });

  test('a sessão local existe e é emitida no stream', () async {
    final prefs = await preferences();
    await LocalAuthGateway.ensureUserId(prefs);
    final gateway = LocalAuthGateway(prefs);

    // O redirect do router decide por isto: sem sessão, o app trava no login.
    expect(gateway.currentSession, isNotNull);
    expect(await gateway.authStateChanges.first, isNotNull);
  });

  test('operações de conta não existem neste modo', () async {
    final prefs = await preferences();
    await LocalAuthGateway.ensureUserId(prefs);
    final gateway = LocalAuthGateway(prefs);

    expect(
      () => gateway.signInWithEmail(email: 'a@b.c', password: 'x'),
      throwsA(
        isA<BackendException>().having(
          (error) => error.code,
          'code',
          'accounts_unsupported',
        ),
      ),
    );
    expect(() => gateway.deleteAccount(), throwsA(isA<BackendException>()));

    // Sair não quebra: o botão nem aparece, mas o contrato precisa responder.
    await expectLater(gateway.signOut(), completes);
  });
}
