import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/features/cards/card_draft.dart';
import 'package:memora/features/cards/card_repository.dart';

void main() {
  test('createCards grava todos os rascunhos com progresso inicial', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CardRepository(database: database);

    await repository.createCards(
      deckId: 'deck-1',
      cards: const [
        CardDraft(front: 'Primeira', back: 'Resposta 1'),
        CardDraft(front: 'Segunda', back: 'Resposta 2'),
      ],
    );

    final cards = await database.cardsDao.getCardsForDeck('deck-1');
    expect(cards.map((card) => card.front), ['Primeira', 'Segunda']);
    expect(cards.every((card) => card.repetitions == 0), isTrue);
    expect(cards.every((card) => card.intervalDays == 1), isTrue);
    expect(cards.every((card) => card.easeFactor == 2.5), isTrue);
  });

  test('detecta duplicatas entre os rascunhos e o deck', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CardRepository(database: database);

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-existente',
        deckId: 'deck-1',
        front: 'O que é ATP?',
        back: 'Energia celular',
        dueDate: 1,
        createdAt: 1,
        updatedAt: 1,
      ),
    );

    expect(
      await repository.hasDuplicateCards(
        deckId: 'deck-1',
        cards: const [
          CardDraft(front: ' o que é atp? ', back: 'ENERGIA  CELULAR'),
        ],
      ),
      isTrue,
    );
    expect(
      await repository.hasDuplicateCards(
        deckId: 'deck-1',
        cards: const [
          CardDraft(front: 'Nova', back: 'Resposta'),
          CardDraft(front: ' nova ', back: ' resposta '),
        ],
      ),
      isTrue,
    );
  });

  test('createCards recusa lista vazia', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CardRepository(database: database);

    await expectLater(
      repository.createCards(deckId: 'deck-1', cards: const []),
      throwsArgumentError,
    );
  });
}
