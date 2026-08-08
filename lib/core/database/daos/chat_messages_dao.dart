import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/chat_messages_table.dart';

part 'chat_messages_dao.g.dart';

@DriftAccessor(tables: [ChatMessagesTable])
class ChatMessagesDao extends DatabaseAccessor<AppDatabase>
    with _$ChatMessagesDaoMixin {
  ChatMessagesDao(super.db);

  /// Histórico do deck, do mais antigo para o mais novo — a ordem em que a
  /// conversa é exibida e em que ela vai para o prompt.
  Future<List<LocalChatMessage>> getMessagesForDeck(String deckId) {
    return (select(chatMessagesTable)
          ..where((table) => table.deckId.equals(deckId))
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .get();
  }

  Stream<List<LocalChatMessage>> watchMessagesForDeck(String deckId) {
    return (select(chatMessagesTable)
          ..where((table) => table.deckId.equals(deckId))
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .watch();
  }

  Future<void> insertMessage(ChatMessagesTableCompanion message) {
    return into(chatMessagesTable).insertOnConflictUpdate(message);
  }

  Future<void> deleteMessagesForDeck(String deckId) {
    return (delete(
      chatMessagesTable,
    )..where((table) => table.deckId.equals(deckId))).go();
  }
}
