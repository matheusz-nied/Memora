import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_backdrop.dart';
import 'deck_model.dart';
import 'deck_import_repository.dart';
import 'deck_repository.dart';
import 'deck_text.dart';
import 'widgets/deck_import_summary_dialog.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      floatingActionButton: _currentTabIndex == _decksTab
          ? FloatingActionButton(
              onPressed: () => _showDeckForm(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              highlightElevation: 4,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AppBackdrop(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentTabIndex,
                    children: [
                      DashboardTab(
                        isDark: isDark,
                        onCreateDeck: () => _showDeckForm(context),
                        onOpenDecksTab: () => _setTab(_decksTab),
                        onOpenProfileTab: () => _setTab(_profileTab),
                      ),
                      DecksLibraryTab(
                        isDark: isDark,
                        onCreateDeck: () => _showDeckForm(context),
                        onEditDeck: (deck) =>
                            _showDeckForm(context, deck: deck),
                        onDeleteDeck: (deck) =>
                            _confirmDeleteDeck(context: context, deck: deck),
                      ),
                      ProfileTab(isDark: isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
      backgroundColor: Colors.transparent,
      builder: (context) => DeckFormModal(
        deck: deck,
        onImportJson: deck == null ? _importDecks : null,
        onSubmit: (title, description) async {
          final repository = ref.read(deckRepositoryProvider);
          if (deck == null) {
            return await repository.createDeck(
              title: title,
              description: description,
            );
          }
          await repository.updateDeck(
            deck: deck,
            title: title,
            description: description,
          );
          return null;
        },
      ),
    );
  }

  Future<void> _importDecks() async {
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || selection == null) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(DeckText.importingDecks)));
      final summary = await ref
          .read(deckImportRepositoryProvider)
          .importFiles(
            selection.files
                .map(
                  (file) => DeckImportFile(name: file.name, bytes: file.bytes),
                )
                .toList(growable: false),
          );
      if (!mounted) {
        return;
      }
      messenger.clearSnackBars();
      await showDialog<void>(
        context: context,
        builder: (context) => DeckImportSummaryDialog(summary: summary),
      );
    } catch (error) {
      debugPrint('Falha ao importar decks: $error');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text(DeckText.importDecksFailed)),
          );
      }
    }
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
}
