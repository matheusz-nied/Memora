// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decks_dao.dart';

// ignore_for_file: type=lint
mixin _$DecksDaoMixin on DatabaseAccessor<AppDatabase> {
  $DecksTableTable get decksTable => attachedDatabase.decksTable;
  DecksDaoManager get managers => DecksDaoManager(this);
}

class DecksDaoManager {
  final _$DecksDaoMixin _db;
  DecksDaoManager(this._db);
  $$DecksTableTableTableManager get decksTable =>
      $$DecksTableTableTableManager(_db.attachedDatabase, _db.decksTable);
}
