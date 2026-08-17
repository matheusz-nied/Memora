// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviews_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReviewsTableTable get reviewsTable => attachedDatabase.reviewsTable;
  ReviewsDaoManager get managers => ReviewsDaoManager(this);
}

class ReviewsDaoManager {
  final _$ReviewsDaoMixin _db;
  ReviewsDaoManager(this._db);
  $$ReviewsTableTableTableManager get reviewsTable =>
      $$ReviewsTableTableTableManager(_db.attachedDatabase, _db.reviewsTable);
}
