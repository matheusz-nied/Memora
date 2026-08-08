import 'package:drift/drift.dart';

/// Conversas com o agente do deck, guardadas no aparelho.
///
/// Existe para o modo local: sem nuvem, era o único dado do app que sumia ao
/// fechar a tela. No modo nuvem o histórico continua no Postgres — quem decide
/// onde ler e gravar é o `RemoteDatabaseGateway` ativo.
///
/// Sem `syncPending`: esta tabela não participa do sync. Misturar as duas
/// origens exigiria resolver conflito de conversa, que não paga o custo.
@DataClassName('LocalChatMessage')
class ChatMessagesTable extends Table {
  @override
  String get tableName => 'chat_messages';

  TextColumn get id => text()();
  TextColumn get deckId => text()();

  /// Nome do valor de `BackendChatRole`: `user` ou `assistant`.
  TextColumn get role => text()();

  TextColumn get content => text()();

  /// Epoch ms.
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
