import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/local/local_remote_database_gateway.dart';
import 'package:memora/core/backend/models/backend_chat_message.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/database/app_database.dart';

void main() {
  late AppDatabase database;
  late LocalRemoteDatabaseGateway gateway;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    gateway = LocalRemoteDatabaseGateway(database);
  });

  tearDown(() async => database.close());

  BackendChatMessage message({
    required String id,
    required BackendChatRole role,
    required String content,
    required DateTime createdAt,
    String deckId = 'deck-1',
  }) {
    return BackendChatMessage(
      id: id,
      deckId: deckId,
      userId: '',
      role: role,
      content: content,
      createdAt: createdAt,
    );
  }

  test('a conversa sobrevive a fechar a tela', () async {
    // O que este teste protege: antes da tabela, sair do chat apagava tudo.
    expect(await gateway.fetchChatMessages('deck-1'), isEmpty);

    await gateway.insertChatMessage(
      message(
        id: 'm1',
        role: BackendChatRole.user,
        content: 'o que é ATP?',
        createdAt: DateTime(2026, 8, 1, 10),
      ),
    );
    await gateway.insertChatMessage(
      message(
        id: 'm2',
        role: BackendChatRole.assistant,
        content: 'É a moeda energética da célula.',
        createdAt: DateTime(2026, 8, 1, 10, 1),
      ),
    );

    final history = await gateway.fetchChatMessages('deck-1');

    expect(history, hasLength(2));
    expect(history.first.role, BackendChatRole.user);
    expect(history.last.content, 'É a moeda energética da célula.');
  });

  test('devolve na ordem cronológica, não na de inserção', () async {
    await gateway.insertChatMessage(
      message(
        id: 'nova',
        role: BackendChatRole.user,
        content: 'segunda',
        createdAt: DateTime(2026, 8, 1, 11),
      ),
    );
    await gateway.insertChatMessage(
      message(
        id: 'antiga',
        role: BackendChatRole.user,
        content: 'primeira',
        createdAt: DateTime(2026, 8, 1, 9),
      ),
    );

    final history = await gateway.fetchChatMessages('deck-1');

    expect(history.map((m) => m.content), ['primeira', 'segunda']);
  });

  test('cada deck tem a própria conversa', () async {
    await gateway.insertChatMessage(
      message(
        id: 'm1',
        role: BackendChatRole.user,
        content: 'do deck 1',
        createdAt: DateTime(2026, 8, 1),
      ),
    );
    await gateway.insertChatMessage(
      message(
        id: 'm2',
        deckId: 'deck-2',
        role: BackendChatRole.user,
        content: 'do deck 2',
        createdAt: DateTime(2026, 8, 1),
      ),
    );

    expect(
      (await gateway.fetchChatMessages('deck-1')).single.content,
      'do deck 1',
    );
    expect(
      (await gateway.fetchChatMessages('deck-2')).single.content,
      'do deck 2',
    );
  });

  test('apagar as mensagens do deck limpa só aquele deck', () async {
    for (final deckId in ['deck-1', 'deck-2']) {
      await gateway.insertChatMessage(
        message(
          id: 'm-$deckId',
          deckId: deckId,
          role: BackendChatRole.user,
          content: 'oi',
          createdAt: DateTime(2026, 8, 1),
        ),
      );
    }

    await database.chatMessagesDao.deleteMessagesForDeck('deck-1');

    expect(await gateway.fetchChatMessages('deck-1'), isEmpty);
    expect(await gateway.fetchChatMessages('deck-2'), hasLength(1));
  });

  test('o resto do gateway recusa: não existe remoto neste modo', () async {
    expect(
      () => gateway.fetchDecks(),
      throwsA(
        isA<BackendException>().having(
          (error) => error.code,
          'code',
          'remote_unsupported',
        ),
      ),
    );
  });
}
