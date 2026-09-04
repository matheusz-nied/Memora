import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/constants/app_constants.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/features/cards/card_import_repository.dart';
import 'package:memora/features/decks/deck_import_repository.dart';

void main() {
  late AppDatabase database;
  late DeckImportRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DeckImportRepository(
      database: database,
      userId: 'local-user',
      cardImportRepository: CardImportRepository(database: database),
    );
  });

  tearDown(() => database.close());

  Uint8List deckJson(List<Object?> cards) {
    return Uint8List.fromList(
      utf8.encode(jsonEncode({'version': 1, 'cards': cards})),
    );
  }

  test('cria um deck por arquivo usando o nome e importa os cards', () async {
    final summary = await repository.importFiles([
      DeckImportFile(
        name: 'Biologia.json',
        bytes: deckJson([
          {'front': 'Célula', 'back': 'Unidade da vida'},
          {'front': 'DNA', 'back': 'Material genético'},
        ]),
      ),
      DeckImportFile(
        name: 'História.JSON',
        bytes: deckJson([
          {'front': 'Brasil', 'back': 'Brasília'},
        ]),
      ),
    ]);

    expect(summary.imported.map((item) => item.deckTitle), [
      'Biologia',
      'História',
    ]);
    expect(summary.totalCards, 3);
    expect(summary.failures, isEmpty);

    final decks = await database.decksDao.getAllDecks(userId: 'local-user');
    expect(decks, hasLength(2));
    final cardCounts = await Future.wait(
      decks.map((deck) => database.cardsDao.countCardsForDeck(deck.id)),
    );
    expect(cardCounts.fold(0, (total, count) => total + count), 3);
  });

  test('gera nomes únicos para arquivos e decks com o mesmo nome', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'existing',
        userId: 'local-user',
        title: 'biologia',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final bytes = deckJson([
      {'front': 'Frente', 'back': 'Verso'},
    ]);

    final summary = await repository.importFiles([
      DeckImportFile(name: 'Biologia.json', bytes: bytes),
      DeckImportFile(name: 'Biologia.json', bytes: bytes),
    ]);

    expect(summary.imported.map((item) => item.deckTitle), [
      'Biologia (2)',
      'Biologia (3)',
    ]);
  });

  test('limita nomes longos preservando espaço para o sufixo', () async {
    final longName = '${List.filled(80, 'A').join()}.json';
    final bytes = deckJson([
      {'front': 'Frente', 'back': 'Verso'},
    ]);

    final summary = await repository.importFiles([
      DeckImportFile(name: longName, bytes: bytes),
      DeckImportFile(name: longName, bytes: bytes),
    ]);

    expect(summary.imported, hasLength(2));
    expect(
      summary.imported.every(
        (item) => item.deckTitle.length <= AppConstants.kMaxDeckTitle,
      ),
      isTrue,
    );
    expect(summary.imported.last.deckTitle, endsWith(' (2)'));
  });

  test('continua após arquivo inválido e não cria deck vazio', () async {
    final summary = await repository.importFiles([
      DeckImportFile(
        name: 'inválido.json',
        bytes: Uint8List.fromList(utf8.encode('{inválido')),
      ),
      const DeckImportFile(name: 'ilegível.json', bytes: null),
      DeckImportFile(
        name: 'válido.json',
        bytes: deckJson([
          {'front': 'Frente', 'back': 'Verso'},
          {'front': ' frente ', 'back': ' verso '},
          {'front': '', 'back': 'Inválido'},
        ]),
      ),
    ]);

    expect(summary.imported, hasLength(1));
    expect(summary.imported.single.deckTitle, 'válido');
    expect(summary.imported.single.ignoredCards, 2);
    expect(summary.failures, hasLength(2));
    expect(
      await database.decksDao.getAllDecks(userId: 'local-user'),
      hasLength(1),
    );
  });
}
