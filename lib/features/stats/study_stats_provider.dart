import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../decks/deck_repository.dart';
import 'study_stats.dart';

/// Estatísticas de estudo do usuário atual.
///
/// Reativo: sai da mesma stream do Drift que a UI de estudo usa, então
/// terminar uma sessão atualiza o dashboard sem nenhum refresh manual.
final studyStatsProvider = StreamProvider<StudyStats>((ref) async* {
  // Os decks vêm de [decksStreamProvider] — a mesma lista que a home mostra —
  // e não de uma leitura direta no banco, por dois motivos: "os decks do
  // usuário" precisa significar a mesma coisa na tela e nos números (deck
  // apagado fora dos dois), e a lista precisa ser acompanhada. Lida uma vez
  // só, quem acabasse de criar o primeiro deck ficaria preso no "sem
  // histórico" até reabrir o app.
  //
  // O preço é reconstruir isto a cada escrita em `decks`; a stream de revisões
  // abaixo é barata de refazer, e edição de deck não acontece em rajada.
  final decks = await ref.watch(decksStreamProvider.future);
  final deckIds = decks.map((deck) => deck.id).toList();
  if (deckIds.isEmpty) {
    yield const StudyStats.empty();
    return;
  }

  final database = ref.watch(appDatabaseProvider);

  // O recorte da consulta é mais largo que a janela exibida: ele é fixado ao
  // assinar, e a janela anda junto com o relógio. A folga cobre um app deixado
  // aberto por dias sem que a virada de meia-noite corte o gráfico; o recorte
  // exato de 30 dias é aplicado a cada emissão, com o `now` de agora.
  final queryFrom = startOfDay(DateTime.now())
      .subtract(const Duration(days: kStatsWindowDays * 2))
      .millisecondsSinceEpoch;

  await for (final reviews in database.reviewsDao.watchReviewsSince(
    queryFrom,
    deckIds: deckIds,
  )) {
    final now = DateTime.now();
    final today = startOfDay(now);
    final windowStart = today
        .subtract(const Duration(days: kStatsWindowDays - 1))
        .millisecondsSinceEpoch;

    final upcoming = await database.cardsDao.getUpcomingDueDates(
      deckIds: deckIds,
      untilEpochMs: today
          .add(const Duration(days: kUpcomingDays))
          .millisecondsSinceEpoch,
    );

    yield buildStudyStats(
      reviews: reviews
          .where((review) => review.reviewedAt >= windowStart)
          .toList(),
      upcomingDueDates: upcoming,
      now: now,
    );
  }
});
