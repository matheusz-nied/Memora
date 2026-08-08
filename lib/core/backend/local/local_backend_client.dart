import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../backend_client.dart';
import '../contracts/ai_gateway.dart';
import '../contracts/auth_gateway.dart';
import '../contracts/pdf_text_gateway.dart';
import '../contracts/remote_database_gateway.dart';
import '../contracts/storage_gateway.dart';
import 'deepseek_ai_gateway.dart';
import 'local_auth_gateway.dart';
import 'local_pdf_text_gateway.dart';
import 'local_remote_database_gateway.dart';
import 'local_storage_gateway.dart';

/// Backend do modo local: nada sai do aparelho, exceto as chamadas de IA que
/// o usuário paga com a própria chave da DeepSeek.
///
/// Implementa o mesmo [BackendClient] do adaptador Supabase, então nenhuma
/// tela ou repositório precisa saber qual dos dois está ativo.
class LocalBackendClient implements BackendClient {
  LocalBackendClient({
    required AppDatabase localDatabase,
    required SharedPreferences preferences,
    required String? Function() readApiKey,
  }) : auth = LocalAuthGateway(preferences),
       database = LocalRemoteDatabaseGateway(localDatabase),
       storage = const LocalStorageGateway(),
       ai = DeepSeekAiGateway(database: localDatabase, readApiKey: readApiKey),
       pdfText = const LocalPdfTextGateway();

  /// Prepara o que precisa existir antes da primeira tela.
  ///
  /// Par do `SupabaseBackendClient.initializeFromEnvironment()`: é o ponto do
  /// bootstrap onde o modo local resolve a identidade do aparelho.
  static Future<void> initialize(SharedPreferences preferences) async {
    await LocalAuthGateway.ensureUserId(preferences);
  }

  @override
  final AuthGateway auth;

  @override
  final RemoteDatabaseGateway database;

  @override
  final StorageGateway storage;

  /// Tipado concreto de propósito: o contrato pede um [AiGateway], mas o
  /// descarte precisa do `close()`, que só existe aqui.
  @override
  final DeepSeekAiGateway ai;

  @override
  final PdfTextGateway pdfText;

  /// Libera o que este cliente abriu. Chamado pelo `backendClientProvider`.
  void dispose() => ai.close();
}
