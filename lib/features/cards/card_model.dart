import '../../core/database/app_database.dart';

class CardModel {
  const CardModel({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueDate,
    this.fsrsState = 1,
    this.fsrsStep,
    this.stability,
    this.difficulty,
    this.lastReview,
    this.insight,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueDate;
  final int fsrsState;
  final int? fsrsStep;
  final double? stability;
  final double? difficulty;
  final DateTime? lastReview;
  final String? insight;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CardModel.fromLocal(LocalCard card) {
    return CardModel(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      easeFactor: card.easeFactor,
      intervalDays: card.intervalDays,
      repetitions: card.repetitions,
      dueDate: DateTime.fromMillisecondsSinceEpoch(card.dueDate),
      fsrsState: card.fsrsState,
      fsrsStep: card.fsrsStep,
      stability: card.stability,
      difficulty: card.difficulty,
      lastReview: card.lastReview == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(card.lastReview!),
      insight: card.insight,
      createdAt: DateTime.fromMillisecondsSinceEpoch(card.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(card.updatedAt),
    );
  }

  CardModel copyWith({
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? dueDate,
    int? fsrsState,
    Object? fsrsStep = _copyWithUnset,
    Object? stability = _copyWithUnset,
    Object? difficulty = _copyWithUnset,
    Object? lastReview = _copyWithUnset,
    Object? insight = _copyWithUnset,
    DateTime? updatedAt,
  }) {
    return CardModel(
      id: id,
      deckId: deckId,
      front: front,
      back: back,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      fsrsState: fsrsState ?? this.fsrsState,
      fsrsStep: identical(fsrsStep, _copyWithUnset)
          ? this.fsrsStep
          : fsrsStep as int?,
      stability: identical(stability, _copyWithUnset)
          ? this.stability
          : stability as double?,
      difficulty: identical(difficulty, _copyWithUnset)
          ? this.difficulty
          : difficulty as double?,
      lastReview: identical(lastReview, _copyWithUnset)
          ? this.lastReview
          : lastReview as DateTime?,
      insight: identical(insight, _copyWithUnset)
          ? this.insight
          : insight as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// A card is new to FSRS until it has a memory state and a review time.
  /// This is intentionally not based on legacy `repetitions`: a lapsed card
  /// may have its old repetition counter reset to zero without becoming new.
  bool get isNewForScheduling =>
      repetitions == 0 && stability == null && lastReview == null;
}

const Object _copyWithUnset = Object();
