// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cards_dao.dart';

// ignore_for_file: type=lint
mixin _$CardsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CardsTableTable get cardsTable => attachedDatabase.cardsTable;
  CardsDaoManager get managers => CardsDaoManager(this);
}

class CardsDaoManager {
  final _$CardsDaoMixin _db;
  CardsDaoManager(this._db);
  $$CardsTableTableTableManager get cardsTable =>
      $$CardsTableTableTableManager(_db.attachedDatabase, _db.cardsTable);
}
