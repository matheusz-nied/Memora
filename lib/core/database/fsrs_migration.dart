import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import 'app_database.dart';

/// Fills the FSRS columns when a database is upgraded from the SM-2 schema.
///
/// Historical reviews are replayed in timestamp order so the new state has
/// the same memory trajectory as a card that had always used FSRS. The old
/// `due_date` is deliberately restored afterwards: opening the app must not
/// suddenly move a learner's existing workload. Cards without review history
/// use the official SM-2 → FSRS approximation from fsrs-rs.
Future<void> migrateLegacyCardsToFsrs({required AppDatabase database}) async {
  final cards = await database.select(database.cardsTable).get();
  final reviews = await database.select(database.reviewsTable).get();
  final reviewsByCard = <String, List<dynamic>>{};
  for (final review in reviews) {
    if (review.reviewKind == 1) {
      continue;
    }
    (reviewsByCard[review.cardId] ??= []).add(review);
  }
  for (final history in reviewsByCard.values) {
    history.sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
  }

  // Fuzzing is for future scheduling, not a migration: deterministic replay
  // makes an upgrade reproducible and leaves due_date as the source of truth.
  final scheduler = fsrs.Scheduler(
    learningSteps: const [],
    relearningSteps: const [],
    enableFuzzing: false,
  );

  for (final card in cards) {
    final history = reviewsByCard[card.id] ?? const <dynamic>[];
    var fsrsCard = fsrs.Card(
      cardId: 0,
      state: fsrs.State.learning,
      step: 0,
      due: DateTime.fromMillisecondsSinceEpoch(card.dueDate).toUtc(),
    );

    if (history.isNotEmpty) {
      for (final review in history) {
        final rating = fsrs.Rating.fromValue(
          (review.rating.clamp(0, 3) as int) + 1,
        );
        final result = scheduler.reviewCard(
          fsrsCard,
          rating,
          reviewDateTime: DateTime.fromMillisecondsSinceEpoch(
            review.reviewedAt,
          ).toUtc(),
        );
        fsrsCard = result.card;
      }
    } else if (card.repetitions > 0) {
      fsrsCard = _approximateLegacyCard(card);
    }

    await (database.update(
      database.cardsTable,
    )..where((t) => t.id.equals(card.id))).write(
      CardsTableCompanion(
        fsrsState: Value(fsrsCard.state.value),
        fsrsStep: Value(fsrsCard.step),
        stability: Value(fsrsCard.stability),
        difficulty: Value(fsrsCard.difficulty),
        // Preserve the pre-migration due date exactly.
        lastReview: Value(fsrsCard.lastReview?.millisecondsSinceEpoch),
      ),
    );
  }
}

fsrs.Card _approximateLegacyCard(dynamic card) {
  final interval = math.max(1, card.intervalDays).toDouble();
  final ease = card.easeFactor.clamp(1.3, 3.0).toDouble();
  final decay = -fsrs.defaultParameters[20];
  final factor = math.pow(0.9, 1 / decay).toDouble() - 1;
  final retention = 0.9;
  final stability =
      (interval * factor / (math.pow(retention, 1 / decay).toDouble() - 1))
          .clamp(fsrs.stabilityMin, double.infinity)
          .toDouble();
  final weights = fsrs.defaultParameters;
  final denominator =
      math.exp(weights[8]) *
      math.pow(stability, -weights[9]).toDouble() *
      (math.exp((1 - retention) * weights[10]) - 1);
  final difficulty = (11 - (ease - 1) / denominator)
      .clamp(1.0, 10.0)
      .toDouble();
  final due = DateTime.fromMillisecondsSinceEpoch(card.dueDate).toUtc();
  final lastReview = due.subtract(Duration(days: interval.round()));

  return fsrs.Card(
    cardId: 0,
    state: fsrs.State.review,
    stability: stability,
    difficulty: difficulty,
    due: due,
    lastReview: lastReview,
  );
}
