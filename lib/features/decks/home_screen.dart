import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/offline_banner.dart';
import '../auth/auth_repository.dart';
import 'deck_model.dart';
import 'deck_repository.dart';
import 'deck_text.dart';
import 'widgets/deck_card.dart';
import 'widgets/deck_form_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksStreamProvider);
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(DeckText.subtitle),
        actions: [
          IconButton(
            tooltip: DeckText.newDeck,
            onPressed: () => _showDeckForm(context, ref),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDeckForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Responsive.constrainedContent(
          child: Padding(
            padding: Responsive.contentPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOnline) ...[
                  const OfflineBanner(message: DeckText.offline),
                  const SizedBox(height: AppDimensions.lg),
                ],
                Text(
                  DeckText.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppDimensions.xl),
                Expanded(
                  child: decks.when(
                    loading: () => const LoadingState(),
                    error: (_, __) =>
                        const ErrorState(message: DeckText.loadError),
                    data: (items) => _DeckGrid(
                      decks: items,
                      onCreate: () => _showDeckForm(context, ref),
                      onOpen: (deck) =>
                          context.push(RouteConstants.deckPath(deck.id)),
                      onEdit: (deck) => _showDeckForm(context, ref, deck: deck),
                      onDelete: (deck) => _confirmDeleteDeck(
                        context: context,
                        ref: ref,
                        deck: deck,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeckForm(
    BuildContext context,
    WidgetRef ref, {
    DeckModel? deck,
  }) {
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
    required WidgetRef ref,
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

class _DeckGrid extends StatelessWidget {
  const _DeckGrid({
    required this.decks,
    required this.onCreate,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<DeckModel> decks;
  final VoidCallback onCreate;
  final ValueChanged<DeckModel> onOpen;
  final ValueChanged<DeckModel> onEdit;
  final ValueChanged<DeckModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (decks.isEmpty) {
      return EmptyState(
        title: DeckText.emptyTitle,
        message: DeckText.emptyMessage,
        actionLabel: DeckText.newDeck,
        onAction: onCreate,
      );
    }

    final columns = Responsive.isMobile(context) ? 1 : 2;
    return GridView.builder(
      itemCount: decks.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppDimensions.lg,
        crossAxisSpacing: AppDimensions.lg,
        childAspectRatio: columns == 1 ? 2.05 : 1.08,
      ),
      itemBuilder: (context, index) {
        final deck = decks[index];
        return DeckCard(
          deck: deck,
          onTap: () => onOpen(deck),
          onEdit: () => onEdit(deck),
          onDelete: () => onDelete(deck),
        );
      },
    );
  }
}
