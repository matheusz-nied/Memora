import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/study/card_rating_model.dart';

void main() {
  final today = DateTime(2026, 5, 17, 14);

  StudyProgressResult rate(
    CardRating rating, {
    double ease = 2.5,
    int interval = 1,
    int repetitions = 0,
  }) {
    return calculateStudyProgress(
      currentEaseFactor: ease,
      currentIntervalDays: interval,
      repetitions: repetitions,
      rating: rating,
      now: today,
    );
  }

  group('learning steps', () {
    test('card novo acertado vai para 1 dia, não para o ciclo longo', () {
      final result = rate(CardRating.good);

      expect(result.intervalDays, 1);
      expect(result.repetitions, 1);
      expect(result.dueDate, DateTime(2026, 5, 18));
    });

    test('segunda repetição vai para 3 dias', () {
      final result = rate(CardRating.good, interval: 1, repetitions: 1);

      expect(result.intervalDays, 3);
      expect(result.repetitions, 2);
    });

    test('terceira repetição entra no ciclo multiplicativo', () {
      final result = rate(CardRating.good, interval: 3, repetitions: 2);

      // 3 * 2.5 = 7.5 -> 8
      expect(result.intervalDays, 8);
      expect(result.repetitions, 3);
    });

    test('fácil gradua o card na hora durante o aprendizado', () {
      final result = rate(CardRating.easy, repetitions: 0);

      expect(result.intervalDays, 4);
      expect(result.repetitions, 3);
      expect(result.easeFactor, closeTo(2.65, 0.0001));
    });
  });

  group('difícil', () {
    test('cresce devagar em vez de subtrair um dia', () {
      // Regressão: antes 30 dias viravam 29, então "Difícil" num card maduro
      // praticamente não mudava nada.
      final result = rate(
        CardRating.hard,
        ease: 2.5,
        interval: 30,
        repetitions: 6,
      );

      expect(result.intervalDays, 36);
      expect(result.easeFactor, closeTo(2.35, 0.0001));
    });

    test('difícil repetido derruba o ease até o piso', () {
      var ease = 2.5;
      var interval = 30;
      var repetitions = 6;

      for (var i = 0; i < 20; i++) {
        final result = rate(
          CardRating.hard,
          ease: ease,
          interval: interval,
          repetitions: repetitions,
        );
        ease = result.easeFactor;
        interval = result.intervalDays;
        repetitions = result.repetitions;
      }

      expect(ease, 1.3);
      expect(interval, lessThanOrEqualTo(365));
    });
  });

  group('errei', () {
    test('reseta intervalo e repetições em um card maduro', () {
      final result = rate(
        CardRating.again,
        ease: 2.5,
        interval: 90,
        repetitions: 8,
      );

      expect(result.intervalDays, 1);
      expect(result.repetitions, 0);
      expect(result.easeFactor, closeTo(2.3, 0.0001));
      expect(result.dueDate, DateTime(2026, 5, 18));
    });

    test('depois de errar o card volta a passar pelos learning steps', () {
      final missed = rate(CardRating.again, interval: 90, repetitions: 8);
      final next = rate(
        CardRating.good,
        ease: missed.easeFactor,
        interval: missed.intervalDays,
        repetitions: missed.repetitions,
      );

      expect(next.intervalDays, 1);
      expect(next.repetitions, 1);
    });
  });

  group('ease', () {
    test('bom não altera o ease', () {
      expect(rate(CardRating.good, ease: 2.5).easeFactor, 2.5);
    });

    test('respeita o piso de 1.3', () {
      expect(rate(CardRating.hard, ease: 1.35).easeFactor, 1.3);
      expect(rate(CardRating.again, ease: 1.4).easeFactor, 1.3);
    });

    test('respeita o teto de 3.0', () {
      var ease = 2.5;
      for (var i = 0; i < 10; i++) {
        ease = rate(CardRating.easy, ease: ease, repetitions: 5).easeFactor;
      }

      expect(ease, 3.0);
    });
  });

  group('sequência good', () {
    test('cinco acertos seguidos crescem de forma monotônica e com teto', () {
      var ease = 2.5;
      var interval = 1;
      var repetitions = 0;
      final intervals = <int>[];

      for (var i = 0; i < 5; i++) {
        final result = rate(
          CardRating.good,
          ease: ease,
          interval: interval,
          repetitions: repetitions,
        );
        ease = result.easeFactor;
        interval = result.intervalDays;
        repetitions = result.repetitions;
        intervals.add(interval);
      }

      expect(intervals, [1, 3, 8, 20, 50]);
      expect(repetitions, 5);
    });

    test('o intervalo nunca passa de 365 dias', () {
      var ease = 2.5;
      var interval = 300;
      var repetitions = 10;

      for (var i = 0; i < 10; i++) {
        final result = rate(
          CardRating.easy,
          ease: ease,
          interval: interval,
          repetitions: repetitions,
        );
        ease = result.easeFactor;
        interval = result.intervalDays;
        repetitions = result.repetitions;
      }

      expect(interval, 365);
    });
  });

  test('dueDate é normalizado para o início do dia', () {
    final result = calculateStudyProgress(
      currentEaseFactor: 2.5,
      currentIntervalDays: 3,
      repetitions: 2,
      rating: CardRating.good,
      now: DateTime(2026, 5, 17, 23, 59, 59),
    );

    expect(result.dueDate, DateTime(2026, 5, 25));
  });

  test('índices de CardRating são estáveis: são persistidos em reviews', () {
    expect(CardRating.again.index, 0);
    expect(CardRating.hard.index, 1);
    expect(CardRating.good.index, 2);
    expect(CardRating.easy.index, 3);
  });
}
