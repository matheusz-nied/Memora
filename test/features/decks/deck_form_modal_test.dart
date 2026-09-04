import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/decks/deck_text.dart';
import 'package:memora/features/decks/widgets/deck_form_modal.dart';

void main() {
  testWidgets('importação JSON não exige criar ou nomear um deck antes', (
    tester,
  ) async {
    var importCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) => DeckFormModal(
                  onSubmit: (_, __) async => null,
                  onImportJson: () async => importCalled = true,
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text(DeckText.importDecksJson), findsOneWidget);

    await tester.tap(find.text(DeckText.importDecksJson));
    await tester.pumpAndSettle();

    expect(importCalled, isTrue);
    expect(find.text(DeckText.importDecksJson), findsNothing);
  });
}
