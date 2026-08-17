import 'package:drift/drift.dart';

/// Conversas com o agente do deck, guardadas no aparelho.
///
/// Sem ela, a conversa era o único dado do app que sumia ao fechar a tela.
///
/// Some junto com o deck, sem tombstone: uma conversa não é conteúdo que o
/// usuário recupera, e o backup não a exporta — o histórico de estudo é o que
/// não dá para reconstruir, não o bate-papo.
@DataClassName('LocalChatMessage')
class ChatMessagesTable extends Table {
  @override
  String get tableName => 'chat_messages';

  TextColumn get id => text()();
  TextColumn get deckId => text()();

  /// Nome do valor de `ChatRole`: `user` ou `assistant`.
  TextColumn get role => text()();

  TextColumn get content => text()();

  /// Epoch ms.
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
