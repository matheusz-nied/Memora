import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/identity/device_user_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SharedPreferences> preferences() => SharedPreferences.getInstance();

  test('cria o id do aparelho na primeira execução', () async {
    final prefs = await preferences();

    expect(prefs.getString(DeviceUserId.storageKey), isNull);

    final id = await DeviceUserId.ensure(prefs);

    expect(id, isNotEmpty);
    expect(prefs.getString(DeviceUserId.storageKey), id);
  });

  test('o id sobrevive a novas execuções', () async {
    // O que este teste protege: um id novo a cada abertura esconderia todos os
    // decks do usuário, já que tudo é filtrado por userId.
    final prefs = await preferences();
    final first = await DeviceUserId.ensure(prefs);
    final second = await DeviceUserId.ensure(prefs);

    expect(second, first);
    expect(DeviceUserId.read(prefs), first);
  });

  test('a leitura é síncrona e responde depois do bootstrap', () async {
    final prefs = await preferences();
    final id = await DeviceUserId.ensure(prefs);

    // Os repositórios leem assim, sem `await`, para montar a query.
    expect(DeviceUserId.read(prefs), id);
  });

  test('sem bootstrap, cai num id estável em vez de quebrar', () async {
    // Um crash aqui deixaria o app inutilizável; um id fixo mantém os decks
    // acessíveis na sessão seguinte, quando o bootstrap voltar a rodar.
    final prefs = await preferences();

    expect(DeviceUserId.read(prefs), DeviceUserId.fallback);
  });
}
