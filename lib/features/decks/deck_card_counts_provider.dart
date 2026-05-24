import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cards/card_repository.dart';

typedef DeckCardCounts = ({int total, int due});

final deckCardCountsStreamProvider =
    StreamProvider.family<DeckCardCounts, String>((ref, deckId) {
      return ref.watch(cardRepositoryProvider).watchCards(deckId).map((cards) {
        final total = cards.length;
        final now = DateTime.now().millisecondsSinceEpoch;
        final due = cards
            .where((card) => card.dueDate.millisecondsSinceEpoch <= now)
            .length;
        return (total: total, due: due);
      });
    });
