import '../models/ai_chat_message.dart';
import '../models/ai_quota_status.dart';
import '../models/generated_card.dart';

abstract interface class AiGateway {
  /// Consumo de IA do usuário no período corrente.
  Future<AiQuotaStatus> fetchQuotaStatus();

  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
  });

  Future<List<GeneratedCard>> generateCardsFromPdf({
    required String pdfPath,
    required int quantity,
    required String deckId,
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
