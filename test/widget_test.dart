import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/app.dart';
import 'package:memora/core/backend/backend_client.dart';
import 'package:memora/core/backend/backend_provider.dart';
import 'package:memora/core/backend/contracts/ai_gateway.dart';
import 'package:memora/core/backend/contracts/auth_gateway.dart';
import 'package:memora/core/backend/contracts/remote_database_gateway.dart';
import 'package:memora/core/backend/contracts/storage_gateway.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/backend/models/backend_card.dart';
import 'package:memora/core/backend/models/backend_chat_message.dart';
import 'package:memora/core/backend/models/backend_deck.dart';
import 'package:memora/core/backend/models/backend_session.dart';
import 'package:memora/core/backend/models/backend_user.dart';
import 'package:memora/core/backend/models/generated_card.dart';
import 'package:memora/core/backend/models/storage_upload_result.dart';
import 'package:memora/core/constants/app_constants.dart';
import 'package:memora/core/constants/route_constants.dart';
import 'package:memora/core/sync/app_sync_service.dart';
import 'package:memora/features/auth/auth_text.dart';
import 'package:memora/features/onboarding/onboarding_page_model.dart';
import 'package:memora/features/onboarding/onboarding_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first access opens onboarding', (tester) async {
    final preferences = await _preferences(onboardingCompleted: false);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingText.pages.first.title), findsOneWidget);
  });

  testWidgets('completing onboarding stores flag and opens login', (
    tester,
  ) async {
    final preferences = await _preferences(onboardingCompleted: false);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    await tester.tap(find.text(OnboardingText.skip));
    await tester.pumpAndSettle();

    expect(preferences.getBool(AppConstants.kOnboardingKey), isTrue);
    expect(find.text(AuthText.loginTitle), findsOneWidget);
  });

  testWidgets('unauthenticated protected route redirects to login', (
    tester,
  ) async {
    final preferences = await _preferences(onboardingCompleted: true);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text(AuthText.loginTitle), findsOneWidget);
  });

  testWidgets('authenticated user starts on home', (tester) async {
    final preferences = await _preferences(onboardingCompleted: true);
    final backend = _FakeBackendClient(initialSession: _session);

    await tester.pumpWidget(_app(preferences: preferences, backend: backend));
    await tester.pumpAndSettle();

    expect(find.text(RouteConstants.kRouteHome), findsOneWidget);
  });

  testWidgets('forgot password is available without session after onboarding', (
    tester,
  ) async {
    final preferences = await _preferences(onboardingCompleted: true);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AuthText.forgotPassword));
    await tester.pumpAndSettle();

    expect(find.text(AuthText.forgotTitle), findsOneWidget);
  });

  testWidgets('login form signs in and navigates to home', (tester) async {
    final preferences = await _preferences(onboardingCompleted: true);
    final backend = _FakeBackendClient();

    await tester.pumpWidget(_app(preferences: preferences, backend: backend));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text(AuthText.loginAction));
    await tester.pumpAndSettle();

    expect(backend.auth.signInCount, 1);
    expect(find.text(RouteConstants.kRouteHome), findsOneWidget);
  });

  testWidgets('register form sends display name and navigates to home', (
    tester,
  ) async {
    final preferences = await _preferences(onboardingCompleted: true);
    final backend = _FakeBackendClient();

    await tester.pumpWidget(_app(preferences: preferences, backend: backend));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AuthText.createAccount));
    await tester.tap(find.text(AuthText.createAccount));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'jane@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.enterText(find.byType(TextFormField).at(3), '123456');
    await tester.ensureVisible(find.text(AuthText.registerAction));
    await tester.tap(find.text(AuthText.registerAction));
    await tester.pumpAndSettle();

    expect(backend.auth.signUpCount, 1);
    expect(backend.auth.lastDisplayName, 'Jane Doe');
    expect(find.text(RouteConstants.kRouteHome), findsOneWidget);
  });

  testWidgets('social login buttons are visible but disabled', (tester) async {
    final preferences = await _preferences(onboardingCompleted: true);

    await tester.pumpWidget(_app(preferences: preferences));
    await tester.pumpAndSettle();

    final googleButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, AuthText.google),
    );
    final appleButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, AuthText.apple),
    );

    expect(googleButton.onPressed, isNull);
    expect(appleButton.onPressed, isNull);
  });
}

Widget _app({
  required SharedPreferences preferences,
  _FakeBackendClient? backend,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      backendClientProvider.overrideWithValue(backend ?? _FakeBackendClient()),
      appAutoSyncProvider.overrideWith((ref) {}),
    ],
    child: const MemoraApp(),
  );
}

Future<SharedPreferences> _preferences({
  required bool onboardingCompleted,
}) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.kOnboardingKey: onboardingCompleted,
  });
  return SharedPreferences.getInstance();
}

final _session = BackendSession(
  accessToken: 'token',
  user: BackendUser(id: 'user-id', email: 'user@example.com'),
);

class _FakeBackendClient implements BackendClient {
  _FakeBackendClient({BackendSession? initialSession})
    : auth = _FakeAuthGateway(initialSession);

  @override
  final _FakeAuthGateway auth;

  @override
  final RemoteDatabaseGateway database = _FakeRemoteDatabaseGateway();

  @override
  final StorageGateway storage = _FakeStorageGateway();

  @override
  final AiGateway ai = _FakeAiGateway();
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway(this._session);

  final _controller = StreamController<BackendSession?>.broadcast();
  BackendSession? _session;
  int signInCount = 0;
  int signUpCount = 0;
  String? lastDisplayName;

  @override
  Stream<BackendSession?> get authStateChanges => _controller.stream;

  @override
  BackendSession? get currentSession => _session;

  @override
  Future<BackendSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCount += 1;
    _session = _session ?? _sessionFor(email);
    _controller.add(_session);
    return _session!;
  }

  @override
  Future<BackendSession?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    signUpCount += 1;
    lastDisplayName = displayName;
    _session = _sessionFor(email, displayName: displayName);
    _controller.add(_session);
    return _session;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {}

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(null);
  }
}

BackendSession _sessionFor(String email, {String? displayName}) {
  return BackendSession(
    accessToken: 'token',
    user: BackendUser(id: 'user-id', email: email, displayName: displayName),
  );
}

class _FakeRemoteDatabaseGateway implements RemoteDatabaseGateway {
  @override
  Future<void> deleteCard(String cardId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDeck(String deckId) {
    throw UnimplementedError();
  }

  @override
  Future<List<BackendCard>> fetchCards(String deckId) {
    throw UnimplementedError();
  }

  @override
  Future<List<BackendChatMessage>> fetchChatMessages(String deckId) {
    throw UnimplementedError();
  }

  @override
  Future<List<BackendDeck>> fetchDecks() {
    throw UnimplementedError();
  }

  @override
  Future<BackendChatMessage> insertChatMessage(BackendChatMessage message) {
    throw UnimplementedError();
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
  Future<BackendCard> upsertCard(BackendCard card) {
    throw UnimplementedError();
  }

  @override
  Future<BackendDeck> upsertDeck(BackendDeck deck) {
    throw UnimplementedError();
  }
}

class _FakeStorageGateway implements StorageGateway {
  @override
  Future<StorageUploadResult> uploadPdf({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) {
    throw UnimplementedError();
  }
}

class _FakeAiGateway implements AiGateway {
  @override
  Future<String> chat({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> generateCardInsight({
    required String deckId,
    required String front,
    required String back,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
  }) {
    throw UnimplementedError();
  }
}
