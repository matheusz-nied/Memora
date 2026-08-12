import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../cards/card_repository.dart';

typedef DeckCardCounts = ({int total, int due});

final deckCardCountsStreamProvider =
    StreamProvider.family<DeckCardCounts, String>((ref, deckId) {
      return ref.watch(cardRepositoryProvider).watchCards(deckId).map((cards) {
        final total = cards.length;
        final dueBefore = endOfDay(DateTime.now()).millisecondsSinceEpoch;
        final dueCards = cards
            .where((card) => card.dueDate.millisecondsSinceEpoch <= dueBefore)
            .toList();
        var newCards = 0;
        var due = 0;
        for (final card in dueCards) {
          if (card.isNewForScheduling) {
            if (newCards >= AppConstants.kNewCardsPerSession) {
              continue;
            }
            newCards += 1;
          }
          due += 1;
        }
        return (total: total, due: due);
      });
    });
