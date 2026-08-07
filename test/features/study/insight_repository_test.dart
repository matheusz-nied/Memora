import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/models/ai_quota_status.dart';
import 'package:memora/core/backend/contracts/ai_gateway.dart';
import 'package:memora/core/backend/contracts/remote_database_gateway.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/backend/models/backend_card.dart';
import 'package:memora/core/backend/models/backend_chat_message.dart';
import 'package:memora/core/backend/models/backend_deck.dart';
import 'package:memora/core/backend/models/backend_review.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/backend/models/generated_card.dart';
import 'package:memora/core/backend/models/pdf_extraction_result.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/core/sync/app_sync_service.dart';
import 'package:memora/features/cards/card_model.dart';
import 'package:memora/features/cards/card_repository.dart';
import 'package:memora/features/study/insight_repository.dart';
import 'package:memora/features/study/study_text.dart';

void main() {
  late AppDatabase database;
  late CardRepository cardRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    cardRepository = CardRepository(
      database: database,
      syncService: AppSyncService(
        database: database,
        remoteDatabase: _FakeRemoteDatabaseGateway(),
        isOnline: () async => false,
        canSync: () async => true,
        currentUserId: () => 'user-1',
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('returns existing insight without calling ai gateway', () async {
    final ai = _FakeAiGateway();
    final repository = _repositoryFor(
      cardRepository: cardRepository,
      ai: ai,
      isOnline: false,
    );
    final card = _card(insight: 'Saved insight.');

    final insight = await repository.generateInsight(
      deckId: 'deck-1',
      card: card,
    );

    expect(insight, 'Saved insight.');
    expect(ai.generateInsightCalls, 0);
  });

  test('blocks new insight when offline', () async {
    final repository = _repositoryFor(
      cardRepository: cardRepository,
      isOnline: false,
    );

    await expectLater(
      repository.generateInsight(deckId: 'deck-1', card: _card()),
      throwsA(
        isA<BackendException>().having(
          (error) => error.message,
          'message',
          StudyText.insightOffline,
        ),
      ),
    );
  });

  test('generates and persists new insight locally', () async {
    final now = DateTime(2026, 5, 22).millisecondsSinceEpoch;
    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'What is a closure?',
        back: 'A function that captures variables.',
        dueDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final ai = _FakeAiGateway(insight: 'Closures keep access to outer scope.');
    final repository = _repositoryFor(cardRepository: cardRepository, ai: ai);

    final insight = await repository.generateInsight(
      deckId: 'deck-1',
      card: _card(),
    );

    final saved = await database.cardsDao.getCardById('card-1');
    expect(insight, 'Closures keep access to outer scope.');
    expect(ai.generateInsightCalls, 1);
    expect(ai.lastDeckId, 'deck-1');
    expect(ai.lastFront, 'What is a closure?');
    expect(saved!.insight, 'Closures keep access to outer scope.');
    expect(saved.syncPending, isTrue);
  });
}

InsightRepository _repositoryFor({
  required CardRepository cardRepository,
  _FakeAiGateway? ai,
  bool isOnline = true,
}) {
  return InsightRepository(
    aiGateway: ai ?? _FakeAiGateway(),
    cardRepository: cardRepository,
    isOnline: () async => isOnline,
  );
}

CardModel _card({String? insight}) {
  final now = DateTime(2026, 5, 22);
  return CardModel(
    id: 'card-1',
    deckId: 'deck-1',
    front: 'What is a closure?',
    back: 'A function that captures variables.',
    easeFactor: 2.5,
    intervalDays: 1,
    repetitions: 0,
    dueDate: now,
    syncPending: false,
    insight: insight,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAiGateway implements AiGateway {
  @override
  Future<AiQuotaStatus> fetchQuotaStatus() async {
    return AiQuotaStatus(
      used: 0,
      quota: 30,
      tier: 'free',
      periodEnd: DateTime(2026, 8),
    );
  }

  _FakeAiGateway({this.insight = 'Generated insight.'});

  final String insight;
  int generateInsightCalls = 0;
  String? lastDeckId;
  String? lastFront;

  @override
  Future<String> generateCardInsight({
    required String deckId,
    required String front,
    required String back,
  }) async {
    generateInsightCalls += 1;
    lastDeckId = deckId;
    lastFront = front;
    return insight;
  }

  @override
  Future<String> chat({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
    List<String> avoidFronts = const [],
    bool fromPdf = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PdfExtractionResult> extractPdfText({required String pdfPath}) {
    throw UnimplementedError();
  }
}

class _FakeRemoteDatabaseGateway implements RemoteDatabaseGateway {
  @override
  Future<void> insertReviews(List<BackendReview> reviews) async {
    insertedReviews.addAll(reviews);
  }

  final List<BackendReview> insertedReviews = [];

  @override
  Future<void> deleteCard(String cardId) async {}

  @override
  Future<void> deleteDeck(String deckId) async {}

  @override
  Future<List<BackendCard>> fetchCards(String deckId) async => [];

  @override
  Future<List<BackendChatMessage>> fetchChatMessages(String deckId) async => [];

  @override
  Future<List<BackendDeck>> fetchDecks() async => [];

  @override
  Future<BackendChatMessage> insertChatMessage(
    BackendChatMessage message,
  ) async {
    return message;
  }

  @override
  Future<BackendCard> updateCardInsight({
    required String cardId,
    required String insight,
    required DateTime updatedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BackendCard> updateCardProgress({
    required String cardId,
    required double easeFactor,
    required int intervalDays,
    required DateTime dueDate,
    required DateTime updatedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BackendCard> upsertCard(BackendCard card) async => card;

  @override
  Future<BackendDeck> upsertDeck(BackendDeck deck) async => deck;
}
