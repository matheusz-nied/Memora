import '../../core/backend/models/generated_card.dart';

class GeneratedCardsReviewArgs {
  const GeneratedCardsReviewArgs({required this.deckId, required this.cards});

  final String deckId;
  final List<GeneratedCard> cards;
}
