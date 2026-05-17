import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/route_constants.dart';
import 'core/sync/app_sync_service.dart';
import 'core/theme/app_dimensions.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/profile_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/decks/deck_screen.dart';
import 'features/decks/home_screen.dart';
import 'features/generate/generated_cards_review_args.dart';
import 'features/generate/import_content_screen.dart';
import 'features/generate/review_cards_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_state.dart';
import 'features/study/study_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  final notifier = _RouterRefreshNotifier(
    onboardingCompleted: ref.read(onboardingCompletedProvider),
    isAuthenticated: authRepository.currentSession != null,
  );

  ref.listen<bool>(onboardingCompletedProvider, (previous, next) {
    notifier.updateOnboardingCompleted(next);
  });
  ref.listen(authStateProvider, (previous, next) {
    final isAuthenticated = next.maybeWhen(
      data: (session) => session != null,
      orElse: () => ref.read(authRepositoryProvider).currentSession != null,
    );
    notifier.updateIsAuthenticated(isAuthenticated);
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

String? _redirect(GoRouterState state, _RouterRefreshNotifier notifier) {
  final path = state.uri.path;
  final isOnboardingRoute = path == RouteConstants.kRouteOnboarding;
  final isAuthRoute =
      path == RouteConstants.kRouteLogin ||
      path == RouteConstants.kRouteRegister;
  final isForgotRoute = path == RouteConstants.kRouteForgotPass;

  if (!notifier.onboardingCompleted) {
    return isOnboardingRoute ? null : RouteConstants.kRouteOnboarding;
  }

  if (isOnboardingRoute) {
    return notifier.isAuthenticated
        ? RouteConstants.kRouteHome
        : RouteConstants.kRouteLogin;
  }

  if (!notifier.isAuthenticated && !isAuthRoute && !isForgotRoute) {
    return RouteConstants.kRouteLogin;
  }

  if (notifier.isAuthenticated && isAuthRoute) {
    return RouteConstants.kRouteHome;
  }

  return null;
}

final _routes = [
  GoRoute(
    path: RouteConstants.kRouteOnboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: RouteConstants.kRouteLogin,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: RouteConstants.kRouteRegister,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: RouteConstants.kRouteForgotPass,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: RouteConstants.kRouteProfile,
    builder: (context, state) => const ProfileScreen(),
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
      return StudyScreen(deckId: deckId);
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
    builder: (context, state) => const _RoutePlaceholder(),
  ),
  GoRoute(
    path: RouteConstants.kRouteAgentConfig,
    builder: (context, state) => const _RoutePlaceholder(),
  ),
];

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier({
    required this.onboardingCompleted,
    required this.isAuthenticated,
  });

  bool onboardingCompleted;
  bool isAuthenticated;

  void updateOnboardingCompleted(bool value) {
    if (onboardingCompleted == value) {
      return;
    }
    onboardingCompleted = value;
    notifyListeners();
  }

  void updateIsAuthenticated(bool value) {
    if (isAuthenticated == value) {
      return;
    }
    isAuthenticated = value;
    notifyListeners();
  }
}

class MemoraApp extends ConsumerWidget {
  const MemoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appAutoSyncProvider);
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

class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder();

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: SafeArea(
        child: Responsive.constrainedContent(
          child: Padding(
            padding: Responsive.contentPadding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: AppDimensions.md),
                Text(route, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
