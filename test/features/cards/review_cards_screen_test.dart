import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/app.dart';
import 'package:memora/core/backend/gateway_providers.dart';
import 'package:memora/core/constants/app_constants.dart';
import 'package:memora/core/constants/route_constants.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/core/identity/device_user_id.dart';
import 'package:memora/core/storage/preferences_provider.dart';
import 'package:memora/features/cards/card_draft.dart';
import 'package:memora/features/decks/deck_repository.dart';
import 'package:memora/features/decks/deck_text.dart';
import 'package:memora/features/generate/card_review_args.dart';
import 'package:memora/features/generate/review_cards_screen.dart';
import 'package:memora/features/generate/review_text.dart';
import 'package:memora/features/legal/legal_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_ai_gateway.dart';

void main() {
  Widget buildReview(CardReviewSource source) {
    return ProviderScope(
      child: MaterialApp(
        home: ReviewCardsScreen(
          args: CardReviewArgs(
            deckId: 'deck-1',
            source: source,
            cards: const [CardDraft(front: 'Pergunta', back: 'Resposta')],
          ),
        ),
      ),
    );
  }

  testWidgets('importação JSON usa copy neutra e não mostra disclaimer de IA', (
    tester,
  ) async {
    await tester.pumpWidget(buildReview(CardReviewSource.jsonImport));

    expect(find.text('Revise os cards importados'), findsWidgets);
    expect(
      find.text('Edite ou remova os cards antes de salvar.'),
      findsOneWidget,
    );
    expect(find.text(LegalText.aiDisclaimer), findsNothing);
  });

  testWidgets('revisão de IA mantém o disclaimer de conteúdo gerado', (
    tester,
  ) async {
    await tester.pumpWidget(buildReview(CardReviewSource.ai));

    expect(find.text('Revise os cards gerados'), findsWidgets);
    expect(find.text(LegalText.aiDisclaimer), findsOneWidget);
  });

  testWidgets('salvar a revisão volta ao deck sem limpar a stack', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.kOnboardingKey: true,
      // O bootstrap real grava isto antes da primeira tela.
      DeviceUserId.storageKey: 'device-user-1',
    });
    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        // Nenhum teste de widget deve tocar a rede.
        aiGatewayProvider.overrideWithValue(FakeAiGateway()),
        pdfTextGatewayProvider.overrideWithValue(FakePdfTextGateway()),
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);

    final deckId = await DeckRepository(
      database: database,
      userId: 'device-user-1',
    ).createDeck(title: 'Deck');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MemoraApp(),
      ),
    );
    await tester.pumpAndSettle();

    // home → deck → import → review, como o app faz.
    final router = container.read(appRouterProvider);
    router.push(RouteConstants.deckPath(deckId));
    await tester.pumpAndSettle();
    router.push(RouteConstants.cardImportPath(deckId));
    await tester.pumpAndSettle();
    router.push(
      RouteConstants.reviewPath(deckId),
      extra: CardReviewArgs(
        deckId: deckId,
        source: CardReviewSource.jsonImport,
        cards: const [CardDraft(front: 'Pergunta', back: 'Resposta')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(ReviewText.saveCards));
    await tester.pumpAndSettle();

    // Volta ao deck...
    expect(router.state.uri.path, RouteConstants.deckPath(deckId));
    expect(find.text('Deck'), findsWidgets);
    // ...com a stack intacta: o voltar chega na home, sem reiniciar o app.
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text(DeckText.title), findsOneWidget);
  });
}
