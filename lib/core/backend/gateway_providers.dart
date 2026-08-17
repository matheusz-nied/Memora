import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/deepseek_key_store.dart';
import '../database/app_database.dart';
import 'contracts/ai_gateway.dart';
import 'contracts/pdf_text_gateway.dart';
import 'local/deepseek_ai_gateway.dart';
import 'local/local_pdf_text_gateway.dart';

/// Ponto único onde o app escolhe a implementação de cada serviço externo.
///
/// Sobrou pouco: o app é todo local, e a IA é a única coisa que sai do
/// aparelho. Os contratos continuam existindo porque trocar a DeepSeek por
/// outro provedor — ou o extrator de PDF por outro — deve significar mexer
/// aqui e em feature nenhuma. `test/architecture/backend_boundary_test.dart`
/// trava essa fronteira.
final aiGatewayProvider = Provider<AiGateway>((ref) {
  final gateway = DeepSeekAiGateway(
    database: ref.watch(appDatabaseProvider),
    // Lida a cada chamada, e não capturada agora: assim trocar a chave na tela
    // de configuração vale na operação seguinte, sem recriar o gateway.
    readApiKey: () => ref.read(deepSeekKeyProvider),
  );
  ref.onDispose(gateway.close);
  return gateway;
});

/// Extração de texto de PDF, no próprio aparelho.
final pdfTextGatewayProvider = Provider<PdfTextGateway>((ref) {
  return const LocalPdfTextGateway();
});
