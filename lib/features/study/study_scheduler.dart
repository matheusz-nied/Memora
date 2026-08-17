// The fsrs package exposes customRandom as a test-only API, which is useful
// here to make queue/scheduler regression tests deterministic.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:math' as math;

import 'package:fsrs/fsrs.dart' as fsrs;

import '../cards/card_model.dart';
import 'card_rating_model.dart';

/// The result persisted after one scheduled answer.
class ScheduledProgress {
  const ScheduledProgress({
    required this.fsrsState,
    required this.fsrsStep,
    required this.stability,
    required this.difficulty,
    required this.lastReview,
    required this.dueDate,
    required this.intervalDays,
    required this.repetitions,
  });

  final int fsrsState;
  final int? fsrsStep;
  final double? stability;
  final double? difficulty;
  final DateTime? lastReview;
  final DateTime dueDate;

  /// Kept for old exports and UI that still displays a progress count. FSRS
  /// itself never reads this value.
  final int intervalDays;
  final int repetitions;
}

/// Thin app adapter around FSRS-6.
///
/// Learning and relearning steps are intentionally empty. The app reinforces
/// an "Again" answer in the same session using a 3–10 card queue gap, while
/// the scheduler owns the long-term interval and memory state.
class StudyScheduler {
  StudyScheduler({
    math.Random? random,
    bool enableFuzzing = true,
    double desiredRetention = 0.9,
    int maximumInterval = 36500,
  }) : _scheduler = random == null
           ? fsrs.Scheduler(
               desiredRetention: desiredRetention,
               learningSteps: const [],
               relearningSteps: const [],
               maximumInterval: maximumInterval,
               enableFuzzing: enableFuzzing,
             )
           : fsrs.Scheduler.customRandom(
               random,
               desiredRetention: desiredRetention,
               learningSteps: const [],
               relearningSteps: const [],
               maximumInterval: maximumInterval,
               enableFuzzing: enableFuzzing,
             );

  final fsrs.Scheduler _scheduler;

  fsrs.Scheduler get scheduler => _scheduler;

  ScheduledProgress schedule(
    CardModel card,
    CardRating rating, {
    DateTime? now,
    int? reviewDuration,
  }) {
    final reviewAt = (now ?? DateTime.now()).toUtc();
    final result = _scheduler.reviewCard(
      _toFsrsCard(card),
      _toFsrsRating(rating),
      reviewDateTime: reviewAt,
      reviewDuration: reviewDuration,
    );
    final nextDue = result.card.due.toLocal();
    final intervalDays = math.max(
      1,
      result.card.due.difference(reviewAt).inDays,
    );

    return ScheduledProgress(
      fsrsState: result.card.state.value,
      fsrsStep: result.card.step,
      stability: result.card.stability,
      difficulty: result.card.difficulty,
      lastReview: result.card.lastReview?.toLocal(),
      dueDate: nextDue,
      intervalDays: intervalDays,
      repetitions: rating == CardRating.again ? 0 : card.repetitions + 1,
    );
  }

  /// Predicted recall probability used to prioritize due reviews.
  double retrievability(CardModel card, {DateTime? now}) {
    if (card.stability == null || card.lastReview == null) {
      return 0;
    }
    return _scheduler.getCardRetrievability(
      _toFsrsCard(card),
      currentDateTime: (now ?? DateTime.now()).toUtc(),
    );
  }

  fsrs.Card _toFsrsCard(CardModel card) {
    final state = card.stability == null && card.lastReview == null
        ? fsrs.State.learning
        : _stateFromValue(card.fsrsState);
    return fsrs.Card(
      cardId: 0,
      state: state,
      step: card.fsrsStep,
      stability: card.stability,
      difficulty: card.difficulty,
      due: card.dueDate.toUtc(),
      lastReview: card.lastReview?.toUtc(),
    );
  }

  fsrs.State _stateFromValue(int value) {
    if (value < fsrs.State.learning.value ||
        value > fsrs.State.relearning.value) {
      return fsrs.State.learning;
    }
    return fsrs.State.fromValue(value);
  }

  fsrs.Rating _toFsrsRating(CardRating rating) {
    return fsrs.Rating.fromValue(rating.index + 1);
  }
}
