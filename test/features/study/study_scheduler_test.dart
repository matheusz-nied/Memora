import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/cards/card_model.dart';
import 'package:memora/features/study/card_rating_model.dart';
import 'package:memora/features/study/study_scheduler.dart';
import 'package:memora/features/study/study_session_controller.dart';

CardModel card(
  String id, {
  int repetitions = 0,
  double? stability,
  double? difficulty,
  int fsrsState = 1,
  DateTime? lastReview,
}) {
  final now = DateTime(2026, 8, 11, 12);
  return CardModel(
    id: id,
    deckId: 'deck',
    front: id,
    back: 'answer',
    easeFactor: 2.5,
    intervalDays: 1,
    repetitions: repetitions,
    dueDate: now,
    fsrsState: fsrsState,
    stability: stability,
    difficulty: difficulty,
    lastReview: lastReview,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('FSRS creates memory state and never uses the old ease formula', () {
    final scheduler = StudyScheduler(enableFuzzing: false);
    final now = DateTime(2026, 8, 11, 12);
    final result = scheduler.schedule(card('new'), CardRating.good, now: now);

    expect(result.fsrsState, 2);
    expect(result.fsrsStep, isNull);
    expect(result.stability, isNotNull);
    expect(result.difficulty, isNotNull);
    expect(result.lastReview, isNotNull);
    expect(result.dueDate.isAfter(now), isTrue);
  });

  test('Again is retried only after a 3–10 card gap', () {
    final cards = [for (var i = 0; i < 15; i++) card('card-$i')];
    final controller = StudySessionController(
      cards: cards,
      random: Random(3),
      scheduler: StudyScheduler(enableFuzzing: false),
    );
    final first = controller.currentCard!;
    controller.recordAnswer(updatedCard: first, rating: CardRating.again);

    final retryIndex = controller.queueIds.indexOf(first.id, 1);
    expect(retryIndex, inInclusiveRange(4, 11));
    expect(
      controller.queueIds
          .skip(controller.currentIndex)
          .where((id) => id == first.id),
      hasLength(1),
    );
    expect(controller.needsReviewIds, contains(first.id));
  });

  test('Hard and Easy do not reappear and Hard is not a failure', () {
    final cards = [for (var i = 0; i < 12; i++) card('card-$i')];
    final controller = StudySessionController(cards: cards, random: Random(7));

    final first = controller.currentCard!;
    controller.recordAnswer(updatedCard: first, rating: CardRating.hard);
    expect(
      controller.queueIds
          .skip(controller.currentIndex)
          .where((id) => id == first.id),
      isEmpty,
    );
    expect(controller.needsReviewIds, isNot(contains(first.id)));

    final second = controller.currentCard!;
    controller.recordAnswer(updatedCard: second, rating: CardRating.easy);
    expect(
      controller.queueIds
          .skip(controller.currentIndex)
          .where((id) => id == second.id),
      isEmpty,
    );
  });

  test('Again at the tail is deferred instead of an immediate repeat', () {
    final cards = [card('a'), card('b'), card('c')];
    final controller = StudySessionController(cards: cards, random: Random(1));
    final first = controller.currentCard!;
    controller.recordAnswer(updatedCard: first, rating: CardRating.again);

    expect(
      controller.queueIds
          .skip(controller.currentIndex)
          .where((id) => id == first.id),
      isEmpty,
    );
    expect(controller.currentIndex, 1);
    expect(controller.isComplete, isFalse);
  });

  test('latest card data replaces a stale snapshot without reordering ids', () {
    final initial = card('a');
    final controller = StudySessionController(cards: [initial]);
    final newer = initial.copyWith(
      insight: 'updated',
      updatedAt: DateTime(2026, 8, 12),
    );

    controller.replaceLatestCards([newer]);

    expect(controller.currentCard!.insight, 'updated');
    expect(controller.queueIds, ['a']);
  });
}
