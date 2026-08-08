import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/contracts/ai_gateway.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/backend/models/generated_card.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/features/cards/card_model.dart';
import 'package:memora/features/cards/card_repository.dart';
import 'package:memora/features/study/insight_repository.dart';
import 'package:memora/features/study/study_text.dart';

void main() {
  late AppDatabase database;
  late CardRepository cardRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    cardRepository = CardRepository(database: database);
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
    insight: insight,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAiGateway implements AiGateway {
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
}
