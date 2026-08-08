import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/deepseek_key_store.dart';
import '../config/app_mode.dart';
import '../database/app_database.dart';
import '../storage/preferences_provider.dart';
import 'backend_client.dart';
import 'disabled_backend_client.dart';
import 'local/local_backend_client.dart';
import 'models/backend_exception.dart';
import 'supabase/supabase_backend_client.dart';

/// Ponto único onde o app escolhe com qual backend está falando.
///
/// A decisão é `const` (ver [kAppMode]), então o adaptador não usado nem chega
/// ao binário. Manter isso concentrado aqui é o que permite trocar de backend
/// sem tocar em nenhuma feature — a fronteira está travada por
/// `test/architecture/backend_boundary_test.dart`.
final backendClientProvider = Provider<BackendClient>((ref) {
  if (kIsLocalMode) {
    final client = LocalBackendClient(
      localDatabase: ref.watch(appDatabaseProvider),
      preferences: ref.watch(sharedPreferencesProvider),
      // Lido a cada chamada, e não capturado agora: assim trocar a chave na
      // tela de configuração vale na operação seguinte, sem recriar o cliente.
      readApiKey: () => ref.read(deepSeekKeyProvider),
    );
    ref.onDispose(client.dispose);
    return client;
  }

  try {
    return SupabaseBackendClient.instance();
  } on BackendException {
    return const DisabledBackendClient();
  }
});
