import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/constants/app_constants.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/features/cards/card_import_repository.dart';

void main() {
  late AppDatabase database;
  late CardImportRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CardImportRepository(database: database);
  });

  tearDown(() => database.close());

  Uint8List jsonBytes(Object source, {bool withBom = false}) {
    final content = jsonEncode(source);
    final bytes = utf8.encode(content);
    return withBom
        ? Uint8List.fromList([0xEF, 0xBB, 0xBF, ...bytes])
        : Uint8List.fromList(bytes);
  }

  test('aceita formato v1, BOM e campos extras', () async {
    final result = await repository.importJson(
      deckId: 'deck-1',
      bytes: jsonBytes({
        'version': 1,
        'source': 'outra IA',
        'cards': [
          {
            'front': '  O que é ATP? ',
            'back': ' Molécula de energia. ',
            'tag': 'bio',
          },
          {'front': 'DNA', 'back': 'Material genético'},
        ],
      }, withBom: true),
    );

    expect(result.invalidCards, 0);
    expect(result.duplicateCards, 0);
    expect(result.cards.map((card) => (card.front, card.back)), [
      ('O que é ATP?', 'Molécula de energia.'),
      ('DNA', 'Material genético'),
    ]);
  });

  test('ignora itens inválidos e duplicatas preservando os válidos', () async {
    final result = await repository.importJson(
      deckId: 'deck-1',
      bytes: jsonBytes({
        'version': 1,
        'cards': [
          {'front': 'Pergunta', 'back': 'Resposta'},
          {'front': ' pergunta ', 'back': ' resposta '},
          {'front': '', 'back': 'sem frente'},
          {'front': 42, 'back': 'tipo errado'},
          {'front': 'Outra', 'back': 'Resposta válida'},
        ],
      }),
    );

    expect(result.cards, hasLength(2));
    expect(result.invalidCards, 2);
    expect(result.duplicateCards, 1);
  });

  test('ignora duplicata que já existe no deck', () async {
    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'existing-card',
        deckId: 'deck-1',
        front: 'O que é ATP?',
        back: 'Energia celular',
        dueDate: 1,
        createdAt: 1,
        updatedAt: 1,
      ),
    );

    final result = await repository.importJson(
      deckId: 'deck-1',
      bytes: jsonBytes({
        'version': 1,
        'cards': [
          {'front': ' o que é atp? ', 'back': 'ENERGIA   CELULAR'},
          {'front': 'Nova', 'back': 'Resposta'},
        ],
      }),
    );

    expect(result.cards.map((card) => card.front), ['Nova']);
    expect(result.duplicateCards, 1);
  });

  test(
    'recusa estrutura, versão, quantidade e arquivos sem cards válidos',
    () async {
      Future<void> expectImportError(Object source, String message) {
        return expectLater(
          repository.importJson(deckId: 'deck-1', bytes: jsonBytes(source)),
          throwsA(
            isA<CardImportException>().having(
              (error) => error.message,
              'message',
              contains(message),
            ),
          ),
        );
      }

      await expectImportError([], 'formato');
      await expectImportError({'version': 2, 'cards': []}, 'versão');
      await expectImportError({'version': 1, 'cards': []}, 'cards válidos');
      await expectImportError({
        'version': 1,
        'cards': List.generate(
          AppConstants.kMaxCardsPerImport + 1,
          (_) => {'front': 'F', 'back': 'V'},
        ),
      }, 'máximo');
      await expectImportError({
        'version': 1,
        'cards': [
          {'front': '', 'back': ''},
        ],
      }, 'cards válidos');
    },
  );

  test('recusa arquivo acima do tamanho permitido', () async {
    final bytes = Uint8List(
      AppConstants.kMaxCardImportSizeMb * 1024 * 1024 + 1,
    );

    await expectLater(
      repository.importJson(deckId: 'deck-1', bytes: bytes),
      throwsA(
        isA<CardImportException>().having(
          (error) => error.message,
          'message',
          contains('2 MB'),
        ),
      ),
    );
  });

  test(
    'trata UTF-8 inválido e version ausente como arquivo inválido',
    () async {
      await expectLater(
        repository.importJson(
          deckId: 'deck-1',
          bytes: Uint8List.fromList([0xFF, 0xFE]),
        ),
        throwsA(
          isA<CardImportException>().having(
            (error) => error.message,
            'message',
            contains('ler o arquivo'),
          ),
        ),
      );

      await expectLater(
        repository.importJson(
          deckId: 'deck-1',
          bytes: jsonBytes({
            'cards': [
              {'front': 'Pergunta', 'back': 'Resposta'},
            ],
          }),
        ),
        throwsA(
          isA<CardImportException>().having(
            (error) => error.message,
            'message',
            contains('formato'),
          ),
        ),
      );
    },
  );
}
