import '../models/ai_chat_message.dart';
import '../models/ai_quota_status.dart';
import '../models/generated_card.dart';

abstract interface class AiGateway {
  /// Consumo de IA do usuário no período corrente.
  Future<AiQuotaStatus> fetchQuotaStatus();

  /// Gera um lote de cards a partir de um trecho de material.
  ///
  /// Pedidos maiores que um lote são quebrados por quem chama: [avoidFronts]
  /// carrega as frentes já geradas para o lote seguinte não repeti-las, e
  /// [fromPdf] avisa que o texto é uma fatia de documento, não o material
  /// completo.
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
    List<String> avoidFronts,
    bool fromPdf,
  });

  Future<String> chat({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  });

  Future<String> generateCardInsight({
    required String deckId,
    required String front,
    required String back,
  });
}
