// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_messages_dao.dart';

// ignore_for_file: type=lint
mixin _$ChatMessagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChatMessagesTableTable get chatMessagesTable =>
      attachedDatabase.chatMessagesTable;
  ChatMessagesDaoManager get managers => ChatMessagesDaoManager(this);
}

class ChatMessagesDaoManager {
  final _$ChatMessagesDaoMixin _db;
  ChatMessagesDaoManager(this._db);
  $$ChatMessagesTableTableTableManager get chatMessagesTable =>
      $$ChatMessagesTableTableTableManager(
        _db.attachedDatabase,
        _db.chatMessagesTable,
      );
}
