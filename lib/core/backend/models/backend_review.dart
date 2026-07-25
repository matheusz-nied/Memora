/// Uma revisão de card, neutra em relação ao backend.
///
/// Append-only: uma revisão nunca é editada nem apagada, o que torna o sync
/// um push puro, sem resolução de conflito.
class BackendReview {
  const BackendReview({
    required this.id,
    required this.cardId,
    required this.userId,
    required this.rating,
    required this.easeBefore,
    required this.easeAfter,
    required this.intervalBefore,
    required this.intervalAfter,
    required this.reviewedAt,
  });

  final String id;
  final String cardId;
  final String userId;

  /// Índice de `CardRating`: 0 = again, 1 = hard, 2 = good, 3 = easy.
  final int rating;

  final double easeBefore;
  final double easeAfter;
  final int intervalBefore;
  final int intervalAfter;
  final DateTime reviewedAt;
}
