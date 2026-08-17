import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../storage/preferences_provider.dart';

/// A identidade do aparelho — o único "usuário" que existe.
///
/// Não há contas nem servidor, mas `userId` continua tendo função: `decks`
/// carrega o dono, e é essa coluna que impede um backup vindo de outra
/// instalação de aparecer misturado com os decks de quem importou. Um UUID
/// persistido cumpre o papel sem nada em volta.
class DeviceUserId {
  const DeviceUserId._();

  static const String storageKey = 'local_user_id';

  /// Nome exibido no perfil. Sem conta não há o que buscar em lugar nenhum.
  static const String displayName = 'Perfil local';

  /// Só aparece se [ensure] não tiver rodado, o que significaria um bootstrap
  /// quebrado. Um id estável vale mais que um crash: os decks continuam
  /// acessíveis na sessão seguinte.
  static const String fallback = 'local-user';

  /// Cria o id na primeira execução, **antes** de qualquer tela existir.
  ///
  /// Fica no bootstrap porque a leitura ([read]) é síncrona: gerar o UUID no
  /// meio do caminho exigiria um write sem `await`, e um app fechado nesse
  /// intervalo voltaria com outro id — ou seja, sem os decks do usuário.
  static Future<String> ensure(SharedPreferences preferences) async {
    final existing = preferences.getString(storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final id = const Uuid().v4();
    await preferences.setString(storageKey, id);
    return id;
  }

  static String read(SharedPreferences preferences) {
    final stored = preferences.getString(storageKey);
    return stored == null || stored.isEmpty ? fallback : stored;
  }
}

/// O id do aparelho, já resolvido pelo bootstrap.
///
/// Síncrono de propósito: os repositórios precisam dele para montar a query, e
/// um `AsyncValue` aqui obrigaria toda tela a tratar um estado de carga que
/// nunca acontece.
final deviceUserIdProvider = Provider<String>((ref) {
  return DeviceUserId.read(ref.watch(sharedPreferencesProvider));
});
