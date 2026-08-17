import 'dart:math' as math;

import '../cards/card_model.dart';
import 'card_rating_model.dart';
import 'study_scheduler.dart';

const int kMinimumRetryGap = 3;
const int kMaximumRetryGap = 10;

/// Pure queue/state controller for a study session.
///
/// The queue stores ids, not card snapshots. The mutable map lets a stream
/// update an insight or a newly scheduled card without resurrecting the stale
/// object that was present when the session started.
class StudySessionController {
  StudySessionController({
    required List<CardModel> cards,
    this.freeStudy = false,
    DateTime? now,
    math.Random? random,
    StudyScheduler? scheduler,
  }) : _random = random ?? math.Random(),
       _scheduler = scheduler ?? StudyScheduler(random: random),
       _now = now ?? DateTime.now() {
    _cardsById.addAll({for (final card in cards) card.id: card});
    _initialIds.addAll(_cardsById.keys);
    _queueIds.addAll(_orderedIds(cards));
  }

  final bool freeStudy;
  final math.Random _random;
  final StudyScheduler _scheduler;
  final DateTime _now;
  final Map<String, CardModel> _cardsById = {};
  final List<String> _initialIds = [];
  final List<String> _queueIds = [];
  final Set<String> _reviewedIds = {};
  final Set<String> _needsReviewIds = {};
  var _currentIndex = 0;

  List<String> get queueIds => List.unmodifiable(_queueIds);
  Set<String> get reviewedIds => Set.unmodifiable(_reviewedIds);
  Set<String> get needsReviewIds => Set.unmodifiable(_needsReviewIds);
  int get currentIndex => _currentIndex;
  int get totalCards => _initialIds.length;
  bool get isComplete => _currentIndex >= _queueIds.length;

  CardModel? get currentCard {
    if (isComplete) {
      return null;
    }
    return _cardsById[_queueIds[_currentIndex]];
  }

  List<CardModel> get cards => [
    for (final id in _queueIds)
      if (_cardsById[id] case final card?) card,
  ];

  /// Reconciles the latest stream values without changing queue order.
  void replaceLatestCards(Iterable<CardModel> cards) {
    for (final card in cards) {
      final current = _cardsById[card.id];
      if (current != null &&
          card.updatedAt.millisecondsSinceEpoch >=
              current.updatedAt.millisecondsSinceEpoch) {
        _cardsById[card.id] = card;
      }
    }
  }

  /// Records one answer and advances to the next presentation.
  ///
  /// Only Again is a failure and only Again can add a same-session retry. A
  /// retry is inserted after a random inclusive gap of 3–10 other cards; if
  /// fewer than three remain it is deferred to a future scheduled session.
  void recordAnswer({
    required CardModel updatedCard,
    required CardRating rating,
  }) {
    if (isComplete || currentCard?.id != updatedCard.id) {
      return;
    }

    final cardId = updatedCard.id;
    _cardsById[cardId] = updatedCard;
    _reviewedIds.add(cardId);
    _currentIndex += 1;

    // A previous Again may have left a pending occurrence. Remove it before
    // deciding whether this answer deserves another one.
    _removePendingOccurrences(cardId);

    if (rating != CardRating.again) {
      _needsReviewIds.remove(cardId);
      return;
    }

    _needsReviewIds.add(cardId);
    if (freeStudy) {
      return;
    }

    final remaining = _queueIds.length - _currentIndex;
    if (remaining < kMinimumRetryGap) {
      return;
    }

    final gap =
        kMinimumRetryGap +
        _random.nextInt(kMaximumRetryGap - kMinimumRetryGap + 1);
    final insertionIndex = math.min(_queueIds.length, _currentIndex + gap);
    _queueIds.insert(insertionIndex, cardId);
  }

  /// Rebuilds a free-practice session. Scheduled sessions intentionally do not
  /// restart in the UI because doing so would immediately repeat the same due
  /// workload after the summary.
  void restart(Iterable<CardModel> cards, {DateTime? now}) {
    _cardsById
      ..clear()
      ..addEntries(cards.map((card) => MapEntry(card.id, card)));
    _initialIds
      ..clear()
      ..addAll(_cardsById.keys);
    _queueIds
      ..clear()
      ..addAll(_orderedIds(_cardsById.values, now: now ?? DateTime.now()));
    _reviewedIds.clear();
    _needsReviewIds.clear();
    _currentIndex = 0;
  }

  void _removePendingOccurrences(String cardId) {
    for (var index = _queueIds.length - 1; index >= _currentIndex; index--) {
      if (_queueIds[index] == cardId) {
        _queueIds.removeAt(index);
      }
    }
  }

  static const minimumRetryGap = kMinimumRetryGap;
  static const maximumRetryGap = kMaximumRetryGap;

  List<String> _orderedIds(Iterable<CardModel> cards, {DateTime? now}) {
    final values = cards.toList();
    if (freeStudy) {
      values.shuffle(_random);
      return values.map((card) => card.id).toList();
    }

    final scheduled = <CardModel>[];
    final newCards = <CardModel>[];
    for (final card in values) {
      (card.isNewForScheduling ? newCards : scheduled).add(card);
    }

    // Five-percent retrievability buckets prevent a deterministic sorted list
    // while still putting the least retrievable due cards first.
    final buckets = <int, List<CardModel>>{};
    for (final card in scheduled) {
      final retention = _scheduler.retrievability(card, now: now ?? _now);
      final bucket = (retention.clamp(0.0, 1.0) * 20).floor();
      (buckets[bucket] ??= []).add(card);
    }
    final ordered = <CardModel>[];
    for (final bucket in buckets.keys.toList()..sort()) {
      final cardsInBucket = buckets[bucket]!;
      cardsInBucket.shuffle(_random);
      ordered.addAll(cardsInBucket);
    }
    newCards.shuffle(_random);
    ordered.addAll(newCards);
    return ordered.map((card) => card.id).toList();
  }
}
