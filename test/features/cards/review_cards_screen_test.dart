import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/cards/card_draft.dart';
import 'package:memora/features/generate/card_review_args.dart';
import 'package:memora/features/generate/review_cards_screen.dart';
import 'package:memora/features/legal/legal_text.dart';

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
}
