import '../cards/card_model.dart';

class StudySessionSummary {
  const StudySessionSummary({
    required this.totalCards,
    required this.reviewedCards,
    required this.needsReview,
    required this.knownCards,
  });

  final int totalCards;
  final int reviewedCards;
  final int needsReview;
  final int knownCards;

  factory StudySessionSummary.fromRatings({
    required int totalCards,
    required Iterable<String> reviewedCardIds,
    required Set<String> needsReviewCardIds,
  }) {
    final reviewedCards = reviewedCardIds.length;
    return StudySessionSummary(
      totalCards: totalCards,
      reviewedCards: reviewedCards,
      needsReview: needsReviewCardIds.length,
      knownCards: reviewedCards - needsReviewCardIds.length,
    );
  }
}

class StudySession {
  const StudySession({
    required this.cards,
    required this.currentIndex,
    required this.reviewedCardIds,
    required this.needsReviewCardIds,
  });

  final List<CardModel> cards;
  final int currentIndex;
  final Set<String> reviewedCardIds;
  final Set<String> needsReviewCardIds;

  CardModel? get currentCard {
    if (currentIndex >= cards.length) {
      return null;
    }
    return cards[currentIndex];
  }

  bool get isComplete => currentIndex >= cards.length;

  StudySessionSummary get summary {
    return StudySessionSummary.fromRatings(
      totalCards: cards.length,
      reviewedCardIds: reviewedCardIds,
      needsReviewCardIds: needsReviewCardIds,
    );
  }
}
