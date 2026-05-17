import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/study/card_rating_model.dart';

void main() {
  group('calculateStudyProgress', () {
    final today = DateTime(2026, 5, 17, 14);

    test('applies again rating', () {
      final result = calculateStudyProgress(
        currentEaseFactor: 2.5,
        currentIntervalDays: 5,
        rating: CardRating.again,
        now: today,
      );

      expect(result.easeFactor, 2.3);
      expect(result.intervalDays, 1);
      expect(result.dueDate, DateTime(2026, 5, 18));
    });

    test('keeps ease factor minimum at 1.3', () {
      final result = calculateStudyProgress(
        currentEaseFactor: 1.35,
        currentIntervalDays: 1,
        rating: CardRating.hard,
        now: today,
      );

      expect(result.easeFactor, 1.3);
      expect(result.intervalDays, 1);
    });

    test('multiplies interval on good rating', () {
      final result = calculateStudyProgress(
        currentEaseFactor: 2.5,
        currentIntervalDays: 4,
        rating: CardRating.good,
        now: today,
      );

      expect(result.easeFactor, 2.5);
      expect(result.intervalDays, 10);
      expect(result.dueDate, DateTime(2026, 5, 27));
    });

    test('boosts interval and ease on easy rating', () {
      final result = calculateStudyProgress(
        currentEaseFactor: 2.5,
        currentIntervalDays: 4,
        rating: CardRating.easy,
        now: today,
      );

      expect(result.easeFactor, 2.6);
      expect(result.intervalDays, 13);
      expect(result.dueDate, DateTime(2026, 5, 30));
    });
  });
}
