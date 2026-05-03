import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/route_constants.dart';
import 'core/sync/app_sync_service.dart';
import 'core/theme/app_dimensions.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';

class MemoraApp extends ConsumerWidget {
  const MemoraApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: RouteConstants.kRouteHome,
    routes: [
      GoRoute(
        path: RouteConstants.kRouteOnboarding,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteLogin,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteRegister,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteForgotPass,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteHome,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteDeck,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteStudy,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteGenerate,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteReview,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteChat,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
      GoRoute(
        path: RouteConstants.kRouteAgentConfig,
        builder: (context, state) => const _RoutePlaceholder(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appAutoSyncProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,
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
