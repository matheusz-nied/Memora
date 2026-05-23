import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_provider.dart';
import '../../core/backend/contracts/ai_gateway.dart';
import '../../core/backend/models/backend_exception.dart';
import '../../core/utils/connectivity_service.dart';
import '../cards/card_model.dart';
import '../cards/card_repository.dart';
import 'study_text.dart';

final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  return InsightRepository(
    aiGateway: ref.watch(backendClientProvider).ai,
    cardRepository: ref.watch(cardRepositoryProvider),
    isOnline: ref.watch(connectivityServiceProvider).isOnline,
  );
});

class InsightRepository {
  const InsightRepository({
    required AiGateway aiGateway,
    required CardRepository cardRepository,
    required Future<bool> Function() isOnline,
  }) : _aiGateway = aiGateway,
       _cardRepository = cardRepository,
       _isOnline = isOnline;

  final AiGateway _aiGateway;
  final CardRepository _cardRepository;
  final Future<bool> Function() _isOnline;

  Future<String> generateInsight({
    required String deckId,
    required CardModel card,
  }) async {
    final existingInsight = card.insight?.trim();
    if (existingInsight != null && existingInsight.isNotEmpty) {
      return existingInsight;
    }

    if (!await _isOnline()) {
      throw const BackendException(StudyText.insightOffline);
    }

    final insight = (await _aiGateway.generateCardInsight(
      deckId: deckId,
      front: card.front,
      back: card.back,
    )).trim();

    if (insight.isEmpty) {
      throw const BackendException(StudyText.insightEmpty);
    }

    await _cardRepository.updateInsight(card: card, insight: insight);
    return insight;
  }
}
