import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/widgets/offline_banner.dart';
import '../auth/auth_repository.dart';
import '../auth/profile_text.dart';
import 'deck_model.dart';
import 'deck_repository.dart';
import 'deck_text.dart';
import 'widgets/deck_form_modal.dart';
import 'widgets/home/dashboard_tab.dart';
import 'widgets/home/decks_library_tab.dart';
import 'widgets/home/home_bottom_nav.dart';
import 'widgets/home/profile_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _dashboardTab = 0;
  static const _decksTab = 1;
  static const _profileTab = 2;

  var _currentTabIndex = _dashboardTab;
  var _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) const OfflineBanner(message: DeckText.offline),
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: [
                  DashboardTab(
                    isDark: isDark,
                    onRefresh: _syncNow,
                    onCreateDeck: () => _showDeckForm(context),
                    onOpenDecksTab: () => _setTab(_decksTab),
                    onOpenProfileTab: () => _setTab(_profileTab),
                  ),
                  DecksLibraryTab(
                    isDark: isDark,
                    onCreateDeck: () => _showDeckForm(context),
                    onEditDeck: (deck) => _showDeckForm(context, deck: deck),
                    onDeleteDeck: (deck) =>
                        _confirmDeleteDeck(context: context, deck: deck),
                  ),
                  ProfileTab(
                    isDark: isDark,
                    isSigningOut: _isSyncing,
                    onSignOut: _signOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentTabIndex,
        isDark: isDark,
        onChanged: _setTab,
      ),
    );
  }

  void _setTab(int index) {
    setState(() => _currentTabIndex = index);
  }

  Future<void> _showDeckForm(BuildContext context, {DeckModel? deck}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DeckFormModal(
        deck: deck,
        onSubmit: (title, description) {
          final repository = ref.read(deckRepositoryProvider);
          if (deck == null) {
            return repository.createDeck(
              title: title,
              description: description,
            );
          }
          return repository.updateDeck(
            deck: deck,
            title: title,
            description: description,
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteDeck({
    required BuildContext context,
    required DeckModel deck,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(DeckText.confirmDeleteDeckTitle),
        content: const Text(DeckText.confirmDeleteDeckMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(DeckText.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(DeckText.delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(deckRepositoryProvider).deleteDeck(deck.id);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(deckRepositoryProvider).syncDecks(requireSync: true);
      if (mounted) {
        _showSnackBar(DeckText.syncSuccess);
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar(_readableSyncError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSyncing = true);

    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        context.go(RouteConstants.kRouteLogin);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(ProfileText.signOutError);
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _readableSyncError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '').trim();
    return message.isEmpty ? DeckText.syncErrorFallback : message;
  }
}
