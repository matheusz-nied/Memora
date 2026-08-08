import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/features/agent/data/agent_repository.dart';

import '../../helpers/fake_ai_gateway.dart';

void main() {
  late AppDatabase database;
  late AgentRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = AgentRepository(
      database: database,
      aiGateway: FakeAiGateway(),
    );
  });

  tearDown(() async => database.close());

  test('a conversa sobrevive a fechar a tela', () async {
    // O que este teste protege: antes da tabela, sair do chat apagava tudo.
    expect(await repository.fetchChatHistory('deck-1'), isEmpty);

    await repository.saveChatMessage(
      deckId: 'deck-1',
      role: ChatRole.user,
      content: 'o que é ATP?',
    );
    await repository.saveChatMessage(
      deckId: 'deck-1',
      role: ChatRole.assistant,
      content: 'É a moeda energética da célula.',
    );

    final history = await repository.fetchChatHistory('deck-1');

    expect(history, hasLength(2));
    expect(history.first.role, ChatRole.user);
    expect(history.last.content, 'É a moeda energética da célula.');
  });

  test('devolve na ordem cronológica, não na de inserção', () async {
    await database.chatMessagesDao.insertMessage(
      ChatMessagesTableCompanion.insert(
        id: 'nova',
        deckId: 'deck-1',
        role: ChatRole.user.name,
        content: 'segunda',
        createdAt: DateTime(2026, 8, 1, 11).millisecondsSinceEpoch,
      ),
    );
    await database.chatMessagesDao.insertMessage(
      ChatMessagesTableCompanion.insert(
        id: 'antiga',
        deckId: 'deck-1',
        role: ChatRole.user.name,
        content: 'primeira',
        createdAt: DateTime(2026, 8, 1, 9).millisecondsSinceEpoch,
      ),
    );

    final history = await repository.fetchChatHistory('deck-1');

    expect(history.map((message) => message.content), ['primeira', 'segunda']);
  });

  test('cada deck tem a própria conversa', () async {
    await repository.saveChatMessage(
      deckId: 'deck-1',
      role: ChatRole.user,
      content: 'do deck 1',
    );
    await repository.saveChatMessage(
      deckId: 'deck-2',
      role: ChatRole.user,
      content: 'do deck 2',
    );

    expect(
      (await repository.fetchChatHistory('deck-1')).single.content,
      'do deck 1',
    );
    expect(
      (await repository.fetchChatHistory('deck-2')).single.content,
      'do deck 2',
    );
  });

  test('apagar as mensagens do deck limpa só aquele deck', () async {
    for (final deckId in ['deck-1', 'deck-2']) {
      await repository.saveChatMessage(
        deckId: deckId,
        role: ChatRole.user,
        content: 'oi',
      );
    }

    await database.chatMessagesDao.deleteMessagesForDeck('deck-1');

    expect(await repository.fetchChatHistory('deck-1'), isEmpty);
    expect(await repository.fetchChatHistory('deck-2'), hasLength(1));
  });

  test('papel desconhecido no banco não derruba o histórico', () async {
    // Uma linha gravada por uma versão futura com outro papel deve virar uma
    // bolha a mais na tela, não um chat que não abre.
    await database.chatMessagesDao.insertMessage(
      ChatMessagesTableCompanion.insert(
        id: 'estranha',
        deckId: 'deck-1',
        role: 'system',
        content: 'de outra versão',
        createdAt: DateTime(2026, 8, 1).millisecondsSinceEpoch,
      ),
    );

    final history = await repository.fetchChatHistory('deck-1');

    expect(history.single.role, ChatRole.assistant);
  });
}
