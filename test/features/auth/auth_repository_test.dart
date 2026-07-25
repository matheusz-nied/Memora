import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/contracts/auth_gateway.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/backend/models/backend_session.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/features/auth/auth_repository.dart';

void main() {
  late AppDatabase database;
  late _FakeAuthGateway gateway;
  late AuthRepository repository;

  final now = DateTime(2026, 5, 20).millisecondsSinceEpoch;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    gateway = _FakeAuthGateway();
    repository = AuthRepository(gateway, database: database);

    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'deck-1',
        userId: 'user-1',
        title: 'Biologia',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'front',
        back: 'back',
        dueDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.reviewsDao.insertReview(
      ReviewsTableCompanion.insert(
        id: 'review-1',
        cardId: 'card-1',
        deckId: 'deck-1',
        rating: 2,
        easeBefore: 2.5,
        easeAfter: 2.5,
        intervalBefore: 1,
        intervalAfter: 3,
        reviewedAt: now,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> localRowCount() async {
    final decks = await database.decksDao.getAllDecks();
    final cards = await database.cardsDao.getCardsForDeck('deck-1');
    final reviews = await database.reviewsDao.getReviewsSince(0);
    return decks.length + cards.length + reviews.length;
  }

  test('deleteAccount apaga o remoto e depois o banco local', () async {
    expect(await localRowCount(), 3);

    await repository.deleteAccount();

    expect(gateway.deleteAccountCount, 1);
    expect(await localRowCount(), 0);
  });

  test('deleteAccount preserva os dados locais se o remoto falhar', () async {
    // Um erro de rede não pode custar os cards do usuário numa conta que
    // continua existindo.
    gateway.failDelete = true;

    await expectLater(
      repository.deleteAccount(),
      throwsA(isA<BackendException>()),
    );

    expect(await localRowCount(), 3);
  });

  test('clearLocalData zera as três tabelas', () async {
    await repository.clearLocalData();

    expect(await localRowCount(), 0);
  });
}

class _FakeAuthGateway implements AuthGateway {
  int deleteAccountCount = 0;
  bool failDelete = false;

  @override
  Future<void> deleteAccount() async {
    if (failDelete) {
      throw const BackendException('Falha de rede.');
    }
    deleteAccountCount += 1;
  }

  @override
  Stream<BackendSession?> get authStateChanges => const Stream.empty();

  @override
  BackendSession? get currentSession => null;

  @override
  Future<BackendSession> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<BackendSession?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> resetPasswordForEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}
