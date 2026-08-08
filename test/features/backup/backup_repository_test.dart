import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/features/backup/backup_data.dart';
import 'package:memora/features/backup/backup_repository.dart';

void main() {
  // Dois bancos ao mesmo tempo é o ponto do teste: um exporta, o outro
  // importa, simulando dois aparelhos. Cada um tem o próprio executor em
  // memória, então não existe a corrida que o aviso do Drift previne.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  late AppDatabase source;
  late AppDatabase target;

  const sourceUser = 'user-origem';
  const targetUser = 'user-destino';

  final createdAt = DateTime(2026, 8, 1).millisecondsSinceEpoch;

  BackupRepository repositoryFor(AppDatabase database, String userId) {
    return BackupRepository(database: database, currentUserId: () => userId);
  }

  Future<void> seedDeck(
    AppDatabase database, {
    required String deckId,
    required String userId,
    required String title,
    int? updatedAt,
  }) async {
    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: deckId,
        userId: userId,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? createdAt,
      ),
    );
  }

  Future<void> seedCard(
    AppDatabase database, {
    required String cardId,
    required String deckId,
    required String front,
    int? updatedAt,
  }) async {
    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: cardId,
        deckId: deckId,
        front: front,
        back: 'verso',
        repetitions: const Value(2),
        dueDate: createdAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? createdAt,
      ),
    );
  }

  Future<void> seedReview(
    AppDatabase database, {
    required String id,
    required String deckId,
    required String cardId,
  }) async {
    await database.reviewsDao.insertReview(
      ReviewsTableCompanion.insert(
        id: id,
        cardId: cardId,
        deckId: deckId,
        rating: 2,
        easeBefore: 2.5,
        easeAfter: 2.6,
        intervalBefore: 1,
        intervalAfter: 6,
        reviewedAt: createdAt,
      ),
    );
  }

  setUp(() async {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());

    await seedDeck(
      source,
      deckId: 'deck-1',
      userId: sourceUser,
      title: 'Biologia',
    );
    await seedCard(
      source,
      cardId: 'card-1',
      deckId: 'deck-1',
      front: 'O que é ATP?',
    );
    await seedReview(
      source,
      id: 'review-1',
      deckId: 'deck-1',
      cardId: 'card-1',
    );
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('exportar e importar num aparelho novo devolve tudo', () async {
    // É o cenário que justifica a feature: trocar de celular sem perder meses
    // de histórico.
    final content = await repositoryFor(source, sourceUser).buildExport();
    final summary = await repositoryFor(
      target,
      targetUser,
    ).applyImport(content);

    expect(summary.decks, 1);
    expect(summary.cards, 1);
    expect(summary.reviews, 1);

    final decks = await target.decksDao.getAllDecks(userId: targetUser);
    expect(decks.single.title, 'Biologia');
    // O deck precisa passar a pertencer a quem importou: com o userId antigo
    // ele existiria no banco e não apareceria em tela nenhuma.
    expect(decks.single.userId, targetUser);

    final cards = await target.cardsDao.getCardsForDeck('deck-1');
    expect(cards.single.front, 'O que é ATP?');
    expect(cards.single.repetitions, 2);

    expect(
      await target.reviewsDao.getReviewsForDecks(['deck-1']),
      hasLength(1),
    );
  });

  test('importar duas vezes não duplica nada', () async {
    final repository = repositoryFor(target, targetUser);
    final content = await repositoryFor(source, sourceUser).buildExport();

    await repository.applyImport(content);
    final second = await repository.applyImport(content);

    expect(second.isEmpty, isTrue);
    expect(await target.decksDao.getAllDecks(userId: targetUser), hasLength(1));
    expect(
      await target.reviewsDao.getReviewsForDecks(['deck-1']),
      hasLength(1),
    );
  });

  test('backup antigo não desfaz o que foi estudado depois', () async {
    // A regra que mais importa: reimportar um arquivo velho não pode reverter
    // progresso mais recente.
    final content = await repositoryFor(source, sourceUser).buildExport();

    await seedDeck(
      target,
      deckId: 'deck-1',
      userId: targetUser,
      title: 'Biologia revisada',
      updatedAt: createdAt + 5000,
    );
    await seedCard(
      target,
      cardId: 'card-1',
      deckId: 'deck-1',
      front: 'Pergunta mais nova',
      updatedAt: createdAt + 5000,
    );

    final summary = await repositoryFor(
      target,
      targetUser,
    ).applyImport(content);

    expect(summary.decks, 0);
    expect(summary.cards, 0);
    final decks = await target.decksDao.getAllDecks(userId: targetUser);
    expect(decks.single.title, 'Biologia revisada');
  });

  test('backup mais recente atualiza o que está velho aqui', () async {
    await seedDeck(
      target,
      deckId: 'deck-1',
      userId: targetUser,
      title: 'Versão antiga',
      updatedAt: createdAt - 5000,
    );

    final content = await repositoryFor(source, sourceUser).buildExport();
    final summary = await repositoryFor(
      target,
      targetUser,
    ).applyImport(content);

    expect(summary.decks, 1);
    final decks = await target.decksDao.getAllDecks(userId: targetUser);
    expect(decks.single.title, 'Biologia');
  });

  test('backup antigo não ressuscita o que foi apagado depois', () async {
    // Apagar é uma edição como outra qualquer: se a tombstone for mais nova
    // que o arquivo, ela vence. Sem enxergar o que foi apagado, o `id` some da
    // busca, parece inédito e o deck volta à vida.
    final content = await repositoryFor(source, sourceUser).buildExport();

    await seedDeck(
      target,
      deckId: 'deck-1',
      userId: targetUser,
      title: 'Biologia',
    );
    await seedCard(
      target,
      cardId: 'card-1',
      deckId: 'deck-1',
      front: 'Pergunta',
    );
    await target.decksDao.markDeckDeleted('deck-1', createdAt + 5000);
    await target.cardsDao.markCardDeleted('card-1', createdAt + 5000);

    final summary = await repositoryFor(
      target,
      targetUser,
    ).applyImport(content);

    expect(summary.decks, 0);
    expect(summary.cards, 0);
    expect(await target.decksDao.getAllDecks(userId: targetUser), isEmpty);
    expect(await target.cardsDao.getCardsForDeck('deck-1'), isEmpty);
  });

  test('importar nunca apaga o que já existia', () async {
    await seedDeck(
      target,
      deckId: 'deck-proprio',
      userId: targetUser,
      title: 'Feito aqui',
    );

    final content = await repositoryFor(source, sourceUser).buildExport();
    await repositoryFor(target, targetUser).applyImport(content);

    final decks = await target.decksDao.getAllDecks(userId: targetUser);
    expect(
      decks.map((deck) => deck.id),
      containsAll(['deck-1', 'deck-proprio']),
    );
  });

  test('recusa arquivo de outro app', () async {
    await expectLater(
      repositoryFor(target, targetUser).applyImport('{"app":"outro"}'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('não parece ser um backup do Memora'),
        ),
      ),
    );
  });

  test(
    'recusa backup de uma versão futura em vez de importar pela metade',
    () async {
      final content = jsonEncode({
        'app': kBackupApp,
        'schema': AppDatabase.latestSchemaVersion + 1,
        'exportedAt': DateTime(2026).toIso8601String(),
        'decks': const [],
        'cards': const [],
        'reviews': const [],
      });

      await expectLater(
        repositoryFor(target, targetUser).applyImport(content),
        throwsA(
          isA<BackupException>().having(
            (error) => error.message,
            'message',
            contains('versão mais nova'),
          ),
        ),
      );
    },
  );

  test('arquivo que não é JSON dá mensagem legível', () async {
    await expectLater(
      repositoryFor(target, targetUser).applyImport('isto não é json'),
      throwsA(isA<BackupException>()),
    );
  });
}
