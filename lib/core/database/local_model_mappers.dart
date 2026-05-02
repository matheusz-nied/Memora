import 'package:drift/drift.dart';

import '../backend/models/backend_card.dart';
import '../backend/models/backend_deck.dart';
import 'app_database.dart';

extension LocalDeckMapper on LocalDeck {
  BackendDeck toBackendDeck() {
    return BackendDeck(
      id: id,
      userId: userId,
      title: title,
      description: description,
      agentName: agentName,
      agentPrompt: agentPrompt,
      agentTemplate: agentTemplate,
      agentLanguage: agentLanguage,
      agentLevel: agentLevel,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}

extension BackendDeckMapper on BackendDeck {
  DecksTableCompanion toLocalDeckCompanion({
    bool syncPending = false,
    int? deletedAt,
  }) {
    return DecksTableCompanion.insert(
      id: id,
      userId: userId,
      title: title,
      description: Value(description),
      agentName: Value(agentName),
      agentPrompt: Value(agentPrompt),
      agentTemplate: Value(agentTemplate),
      agentLanguage: Value(agentLanguage),
      agentLevel: Value(agentLevel),
      syncPending: Value(syncPending),
      deletedAt: Value(deletedAt),
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: updatedAt.millisecondsSinceEpoch,
    );
  }
}

extension LocalCardMapper on LocalCard {
  BackendCard toBackendCard() {
    return BackendCard(
      id: id,
      deckId: deckId,
      front: front,
      back: back,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      dueDate: DateTime.fromMillisecondsSinceEpoch(dueDate),
      insight: insight,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}

extension BackendCardMapper on BackendCard {
  CardsTableCompanion toLocalCardCompanion({
    bool syncPending = false,
    int? deletedAt,
  }) {
    return CardsTableCompanion.insert(
      id: id,
      deckId: deckId,
      front: front,
      back: back,
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      dueDate: dueDate.millisecondsSinceEpoch,
      syncPending: Value(syncPending),
      insight: Value(insight),
      deletedAt: Value(deletedAt),
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: updatedAt.millisecondsSinceEpoch,
    );
  }
}
