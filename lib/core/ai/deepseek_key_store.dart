import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_provider.dart';

/// Guarda a chave da DeepSeek que o próprio usuário cadastra no modo local.
///
/// Fica em `SharedPreferences`, ou seja, no armazenamento privado do app: em
/// texto plano, legível só com root ou por um backup do aparelho. É a chave
/// dele, usada contra a conta dele, e o custo de um cofre nativo não se paga
/// aqui.
class DeepSeekKeyNotifier extends Notifier<String?> {
  static const String storageKey = 'deepseek_api_key';

  @override
  String? build() =>
      _normalize(ref.watch(sharedPreferencesProvider).getString(storageKey));

  Future<void> save(String apiKey) async {
    final normalized = _normalize(apiKey);
    final preferences = ref.read(sharedPreferencesProvider);

    if (normalized == null) {
      await preferences.remove(storageKey);
    } else {
      await preferences.setString(storageKey, normalized);
    }

    state = normalized;
  }

  Future<void> clear() async {
    await ref.read(sharedPreferencesProvider).remove(storageKey);
    state = null;
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final deepSeekKeyProvider = NotifierProvider<DeepSeekKeyNotifier, String?>(
  DeepSeekKeyNotifier.new,
);

/// Mostra só o suficiente para o usuário reconhecer qual chave está salva.
String maskApiKey(String apiKey) {
  if (apiKey.length <= 8) {
    return '••••';
  }
  return '${apiKey.substring(0, 4)}••••${apiKey.substring(apiKey.length - 4)}';
}
