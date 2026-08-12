import '../../core/database/app_database.dart';
import '../../core/database/review_kind.dart';
import '../study/card_rating_model.dart';

/// Quantidade de cards num dia — usado tanto para o que já foi revisado
/// quanto para o que vence adiante.
class DailyCount {
  const DailyCount({required this.day, required this.count});

  /// Meia-noite local do dia.
  final DateTime day;
  final int count;
}

/// Retrato do estudo, montado a partir da tabela `reviews`.
///
/// A tabela é append-only e grava desde a primeira revisão, então isto é
/// histórico real — não uma estimativa a partir do estado atual dos cards.
class StudyStats {
  const StudyStats({
    required this.reviewsToday,
    required this.totalReviews,
    required this.streakDays,
    required this.accuracy,
    required this.daily,
    required this.upcoming,
  });

  const StudyStats.empty()
    : reviewsToday = 0,
      totalReviews = 0,
      streakDays = 0,
      accuracy = null,
      daily = const [],
      upcoming = const [];

  final int reviewsToday;

  /// Revisões dentro da janela analisada, não desde sempre.
  final int totalReviews;

  final int streakDays;

  /// Fração de acertos na janela, ou `null` quando ainda não houve revisão —
  /// mostrar "0%" para quem nunca estudou seria mentira desanimadora.
  final double? accuracy;

  /// Revisões por dia, do mais antigo para o mais recente.
  final List<DailyCount> daily;

  /// Cards que vencem nos próximos dias, do mais próximo ao mais distante.
  final List<DailyCount> upcoming;

  bool get hasHistory => totalReviews > 0;
}

/// Janela analisada pelo dashboard.
const int kStatsWindowDays = 30;

/// Dias de vencimento futuro mostrados.
const int kUpcomingDays = 7;

DateTime startOfDay(DateTime moment) {
  return DateTime(moment.year, moment.month, moment.day);
}

/// Monta as estatísticas a partir das revisões e dos vencimentos.
///
/// Função pura: recebe `now` em vez de ler o relógio, para o teste conseguir
/// exercitar streak e virada de dia sem depender de quando roda.
StudyStats buildStudyStats({
  required List<LocalReview> reviews,
  required List<int> upcomingDueDates,
  required DateTime now,
}) {
  final scheduledReviews = reviews
      .where(
        (review) =>
            ReviewKind.fromValue(review.reviewKind ?? 0) ==
            ReviewKind.scheduled,
      )
      .toList(growable: false);

  if (scheduledReviews.isEmpty && reviews.isEmpty && upcomingDueDates.isEmpty) {
    return const StudyStats.empty();
  }

  final today = startOfDay(now);

  final perDay = <DateTime, int>{};
  var correct = 0;
  for (final review in scheduledReviews) {
    final day = startOfDay(
      DateTime.fromMillisecondsSinceEpoch(review.reviewedAt),
    );
    perDay[day] = (perDay[day] ?? 0) + 1;
    // Hard means the learner recalled the answer with effort; it is a
    // successful retrieval, unlike Again.
    if (review.rating != CardRating.again.index) {
      correct += 1;
    }
  }

  final daily = List<DailyCount>.generate(kStatsWindowDays, (index) {
    final day = today.subtract(Duration(days: kStatsWindowDays - 1 - index));
    return DailyCount(day: day, count: perDay[day] ?? 0);
  });

  final upcomingPerDay = <DateTime, int>{};
  for (final dueDate in upcomingDueDates) {
    final day = startOfDay(DateTime.fromMillisecondsSinceEpoch(dueDate));
    // Vencido no passado conta como carga de hoje: é o que o usuário vê ao
    // abrir uma sessão agora.
    final bucket = day.isBefore(today) ? today : day;
    upcomingPerDay[bucket] = (upcomingPerDay[bucket] ?? 0) + 1;
  }

  final upcoming = List<DailyCount>.generate(kUpcomingDays, (index) {
    final day = today.add(Duration(days: index));
    return DailyCount(day: day, count: upcomingPerDay[day] ?? 0);
  });

  return StudyStats(
    reviewsToday: perDay[today] ?? 0,
    totalReviews: scheduledReviews.length,
    // Free practice is useful for maintaining a habit, but never changes the
    // scheduled-review accuracy or count shown by the dashboard.
    streakDays: computeStreak(
      reviews.map(
        (review) =>
            startOfDay(DateTime.fromMillisecondsSinceEpoch(review.reviewedAt)),
      ),
      now: now,
    ),
    accuracy: scheduledReviews.isEmpty
        ? null
        : correct / scheduledReviews.length,
    daily: daily,
    upcoming: upcoming,
  );
}

/// Dias seguidos de estudo.
///
/// Um dia sem revisar só quebra a sequência quando ele acaba: se o usuário
/// estudou ontem e ainda não estudou hoje, a sequência continua de pé — ele
/// tem o resto do dia para manter. Zerar às 00:01 puniria quem ainda vai
/// estudar.
int computeStreak(Iterable<DateTime> daysWithReviews, {required DateTime now}) {
  final days = daysWithReviews.map(startOfDay).toSet();
  if (days.isEmpty) {
    return 0;
  }

  final today = startOfDay(now);
  var cursor = days.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));

  if (!days.contains(cursor)) {
    return 0;
  }

  var streak = 0;
  while (days.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
