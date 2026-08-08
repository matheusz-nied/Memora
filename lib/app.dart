import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/route_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/agent/presentation/agent_config_screen.dart';
import 'features/agent/presentation/chat_screen.dart';
import 'features/backup/backup_screen.dart';
import 'features/decks/deck_screen.dart';
import 'features/decks/home_screen.dart';
import 'features/generate/generated_cards_review_args.dart';
import 'features/generate/import_content_screen.dart';
import 'features/generate/review_cards_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_state.dart';
import 'features/settings/api_key_screen.dart';
import 'features/study/insight_screen.dart';
import 'features/study/study_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(
    onboardingCompleted: ref.read(onboardingCompletedProvider),
  );

  ref.listen<bool>(onboardingCompletedProvider, (previous, next) {
    notifier.updateOnboardingCompleted(next);
  });

  final router = GoRouter(
    refreshListenable: notifier,
    initialLocation: RouteConstants.kRouteHome,
    redirect: (context, state) => _redirect(state, notifier),
    routes: _routes,
  );
  ref.onDispose(router.dispose);
  ref.onDispose(notifier.dispose);
  return router;
});

/// O onboarding é o único portão que existe.
///
/// Não há login: a identidade nasce no bootstrap e nunca some, então quem
/// terminou a apresentação vai direto para a biblioteca.
String? _redirect(GoRouterState state, _RouterRefreshNotifier notifier) {
  final isOnboardingRoute = state.uri.path == RouteConstants.kRouteOnboarding;

  if (!notifier.onboardingCompleted) {
    return isOnboardingRoute ? null : RouteConstants.kRouteOnboarding;
  }

  return isOnboardingRoute ? RouteConstants.kRouteHome : null;
}

final _routes = [
  GoRoute(
    path: RouteConstants.kRouteOnboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: RouteConstants.kRouteApiKey,
    builder: (context, state) => const ApiKeyScreen(),
  ),
  GoRoute(
    path: RouteConstants.kRouteBackup,
    builder: (context, state) => const BackupScreen(),
  ),
  GoRoute(
    path: RouteConstants.kRouteHome,
    builder: (context, state) => const HomeScreen(),
  ),
  GoRoute(
    path: RouteConstants.kRouteDeck,
    builder: (context, state) {
      final deckId = state.pathParameters[RouteConstants.deckIdParam]!;
      return DeckScreen(deckId: deckId);
    },
  ),
  GoRoute(
    path: RouteConstants.kRouteStudy,
    builder: (context, state) {
      final deckId = state.pathParameters[RouteConstants.deckIdParam]!;
      final freeStudy =
          state.uri.queryParameters[RouteConstants.freeStudyParam] == '1';
      return StudyScreen(deckId: deckId, freeStudy: freeStudy);
    },
  ),
  GoRoute(
    path: RouteConstants.kRouteCardInsight,
    builder: (context, state) {
      final deckId = state.pathParameters[RouteConstants.deckIdParam]!;
      final cardId = state.pathParameters[RouteConstants.cardIdParam]!;
      return InsightScreen(deckId: deckId, cardId: cardId);
    },
  ),
  GoRoute(
    path: RouteConstants.kRouteGenerate,
    builder: (context, state) {
      final deckId = state.pathParameters[RouteConstants.deckIdParam]!;
      return ImportContentScreen(deckId: deckId);
    },
  ),
  GoRoute(
    path: RouteConstants.kRouteReview,
    builder: (context, state) {
      final args = state.extra is GeneratedCardsReviewArgs
          ? state.extra as GeneratedCardsReviewArgs
          : null;
      return ReviewCardsScreen(args: args);
    },
  ),
  GoRoute(
    path: RouteConstants.kRouteChat,
    builder: (context, state) {
      final deckId = state.pathParameters[RouteConstants.deckIdParam]!;
      return ChatScreen(deckId: deckId);
    },
  ),
  GoRoute(
    path: RouteConstants.kRouteAgentConfig,
    builder: (context, state) {
      final deckId = state.pathParameters[RouteConstants.deckIdParam]!;
      return AgentConfigScreen(deckId: deckId);
    },
  ),
];

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier({required this.onboardingCompleted});

  bool onboardingCompleted;

  void updateOnboardingCompleted(bool value) {
    if (onboardingCompleted == value) {
      return;
    }
    onboardingCompleted = value;
    notifyListeners();
  }
}

class MemoraApp extends ConsumerWidget {
  const MemoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
