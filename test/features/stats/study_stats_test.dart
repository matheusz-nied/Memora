import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/features/stats/study_stats.dart';
import 'package:memora/features/study/card_rating_model.dart';

void main() {
  final now = DateTime(2026, 8, 7, 14, 30);
  final today = startOfDay(now);

  LocalReview review({
    required DateTime at,
    CardRating rating = CardRating.good,
  }) {
    return LocalReview(
      id: 'r-${at.microsecondsSinceEpoch}-${rating.index}',
      cardId: 'card-1',
      deckId: 'deck-1',
      rating: rating.index,
      easeBefore: 2.5,
      easeAfter: 2.6,
      intervalBefore: 1,
      intervalAfter: 6,
      reviewedAt: at.millisecondsSinceEpoch,
    );
  }

  group('computeStreak', () {
    test('sem revisão nenhuma a sequência é zero', () {
      expect(computeStreak(const [], now: now), 0);
    });

    test('conta os dias seguidos terminando hoje', () {
      final days = [
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ];

      expect(computeStreak(days, now: now), 3);
    });

    test('quem estudou ontem e ainda não hoje mantém a sequência', () {
      // O dia ainda não acabou: zerar agora puniria quem vai estudar à noite.
      final days = [
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ];

      expect(computeStreak(days, now: now), 2);
    });

    test('uma lacuna quebra a sequência', () {
      final days = [
        today,
        today.subtract(const Duration(days: 1)),
        // Falta o dia 2.
        today.subtract(const Duration(days: 3)),
        today.subtract(const Duration(days: 4)),
      ];

      expect(computeStreak(days, now: now), 2);
    });

    test('parar há dois dias zera a sequência', () {
      final days = [today.subtract(const Duration(days: 2))];

      expect(computeStreak(days, now: now), 0);
    });

    test('várias revisões no mesmo dia contam como um dia', () {
      final days = [today, today, today];

      expect(computeStreak(days, now: now), 1);
    });
  });

  group('buildStudyStats', () {
    test('sem dado nenhum devolve o retrato vazio', () {
      final stats = buildStudyStats(
        reviews: const [],
        upcomingDueDates: const [],
        now: now,
      );

      expect(stats.hasHistory, isFalse);
      expect(stats.accuracy, isNull);
      expect(stats.streakDays, 0);
    });

    test('taxa de acerto conta good e easy', () {
      final stats = buildStudyStats(
        reviews: [
          review(at: now, rating: CardRating.again),
          review(at: now, rating: CardRating.hard),
          review(at: now, rating: CardRating.good),
          review(at: now, rating: CardRating.easy),
        ],
        upcomingDueDates: const [],
        now: now,
      );

      // Hard means the answer was recalled with effort, so only Again is a
      // failed retrieval.
      expect(stats.accuracy, 0.75);
      expect(stats.reviewsToday, 4);
      expect(stats.totalReviews, 4);
    });

    test('a série diária cobre a janela inteira, inclusive dias vazios', () {
      final stats = buildStudyStats(
        reviews: [
          review(at: now),
          review(at: now),
        ],
        upcomingDueDates: const [],
        now: now,
      );

      expect(stats.daily, hasLength(kStatsWindowDays));
      expect(stats.daily.last.day, today);
      expect(stats.daily.last.count, 2);
      // Ontem sem revisão precisa aparecer como zero, não sumir da série.
      expect(stats.daily[stats.daily.length - 2].count, 0);
    });

    test('a carga futura cobre os próximos dias', () {
      final stats = buildStudyStats(
        reviews: const [],
        upcomingDueDates: [
          today.millisecondsSinceEpoch,
          today.add(const Duration(days: 2)).millisecondsSinceEpoch,
          today.add(const Duration(days: 2)).millisecondsSinceEpoch,
        ],
        now: now,
      );

      expect(stats.upcoming, hasLength(kUpcomingDays));
      expect(stats.upcoming.first.count, 1);
      expect(stats.upcoming[2].count, 2);
    });

    test('card vencido no passado entra na carga de hoje', () {
      // É o que o usuário encontra ao abrir uma sessão agora: atrasado é
      // trabalho de hoje, não de um dia que já passou.
      final stats = buildStudyStats(
        reviews: const [],
        upcomingDueDates: [
          today.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
        ],
        now: now,
      );

      expect(stats.upcoming.first.day, today);
      expect(stats.upcoming.first.count, 1);
    });
  });
}
