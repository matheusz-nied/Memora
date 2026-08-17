import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/app.dart';
import 'package:memora/core/backend/gateway_providers.dart';
import 'package:memora/core/constants/app_constants.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/core/identity/device_user_id.dart';
import 'package:memora/core/storage/preferences_provider.dart';
import 'package:memora/features/decks/deck_model.dart';
import 'package:memora/features/decks/deck_repository.dart';
import 'package:memora/features/decks/deck_text.dart';
import 'package:memora/features/legal/legal_text.dart';
import 'package:memora/features/legal/privacy_consent.dart';
import 'package:memora/features/onboarding/onboarding_page_model.dart';
import 'package:memora/features/settings/api_key_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_ai_gateway.dart';

void main() {
  testWidgets('o primeiro acesso abre o onboarding', (tester) async {
    final preferences = await _preferences(onboardingCompleted: false);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingText.pages.first.title), findsOneWidget);
  });

  testWidgets(
    'concluir o onboarding registra o aceite da política e abre o app',
    (tester) async {
      final preferences = await _preferences(onboardingCompleted: false);

      await tester.pumpWidget(_app(preferences: preferences));
      await tester.pumpAndSettle();

      await tester.tap(find.text(OnboardingText.skip));
      await tester.pumpAndSettle();

      expect(preferences.getBool(AppConstants.kOnboardingKey), isTrue);
      // O aceite é registrado, não só exibido: é o que as lojas cobram e o
      // que permite reapresentar o aviso quando a política mudar.
      expect(
        preferences.getInt(PrivacyConsentNotifier.storageKey),
        LegalText.acceptedVersion,
      );
      // Não há login no caminho: a identidade nasce no bootstrap.
      expect(find.text(DeckText.title), findsOneWidget);
    },
  );

  testWidgets('com o onboarding feito, o app abre direto na biblioteca', (
    tester,
  ) async {
    final preferences = await _preferences(onboardingCompleted: true);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text(DeckText.title), findsOneWidget);
  });

  testWidgets('o ícone de perfil abre a aba de perfil', (tester) async {
    final preferences = await _preferences(onboardingCompleted: true);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();

    // Sem conta, o perfil é o aparelho.
    expect(find.text(DeviceUserId.displayName), findsWidgets);
  });

  testWidgets('o perfil oferece a chave da IA, e não logout nem conta', (
    tester,
  ) async {
    final preferences = await _preferences(onboardingCompleted: true);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();

    // O que o usuário precisa gerenciar aqui é a chave que ele mesmo paga.
    expect(find.text(ApiKeyText.title), findsOneWidget);
    expect(find.text('Sair'), findsNothing);
    expect(find.text('Excluir minha conta'), findsNothing);
  });
}

Widget _app({required SharedPreferences preferences}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      // Nenhum teste de widget deve tocar a rede: o contrato existe para isto.
      aiGatewayProvider.overrideWithValue(FakeAiGateway()),
      pdfTextGatewayProvider.overrideWithValue(FakePdfTextGateway()),
      decksStreamProvider.overrideWith(
        (ref) => Stream<List<DeckModel>>.value([]),
      ),
      decksPageProvider.overrideWith(
        (ref, limit) => Stream<List<DeckModel>>.value([]),
      ),
      appDatabaseProvider.overrideWith((ref) {
        final database = AppDatabase(NativeDatabase.memory());
        ref.onDispose(database.close);
        return database;
      }),
    ],
    child: const MemoraApp(),
  );
}

Future<SharedPreferences> _preferences({
  required bool onboardingCompleted,
}) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.kOnboardingKey: onboardingCompleted,
    // O bootstrap real grava isto antes da primeira tela.
    DeviceUserId.storageKey: 'device-user-1',
  });
  return SharedPreferences.getInstance();
}
