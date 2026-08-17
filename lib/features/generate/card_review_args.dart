import '../cards/card_draft.dart';

enum CardReviewSource { ai, jsonImport }

/// Dados neutros para a revisão de cards vindos de qualquer origem.
class CardReviewArgs {
  const CardReviewArgs({
    required this.deckId,
    required this.cards,
    this.source = CardReviewSource.ai,
    this.invalidCards = 0,
    this.duplicateCards = 0,
  });

  final String deckId;
  final List<CardDraft> cards;
  final CardReviewSource source;
  final int invalidCards;
  final int duplicateCards;
}
