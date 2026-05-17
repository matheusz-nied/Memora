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
import '../cards/card_model.dart';
import '../cards/card_repository.dart';
import '../cards/card_text.dart';
import '../cards/widgets/card_form_modal.dart';
import '../cards/widgets/card_list_item.dart';
import 'deck_model.dart';
import 'deck_repository.dart';
import 'deck_text.dart';
import 'widgets/deck_form_modal.dart';

class DeckScreen extends ConsumerWidget {
  const DeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckStreamProvider(deckId));
    final cards = ref.watch(cardsStreamProvider(deckId));
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: DeckText.generateCards,
            onPressed: () => context.push(RouteConstants.generatePath(deckId)),
            icon: const Icon(Icons.auto_awesome),
          ),
          deck.maybeWhen(
            data: (value) => value == null
                ? const SizedBox.shrink()
                : _DeckMenu(deck: value),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCardForm(context, ref),
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
                deck.when(
                  loading: () => const LoadingState(),
                  error: (_, __) =>
                      const ErrorState(message: DeckText.loadError),
                  data: (value) => value == null
                      ? const ErrorState(message: DeckText.deckNotFound)
                      : _DeckHeader(deck: value),
                ),
                const SizedBox(height: AppDimensions.xl),
                Expanded(
                  child: cards.when(
                    loading: () => const LoadingState(),
                    error: (_, __) =>
                        const ErrorState(message: CardText.loadError),
                    data: (items) => _CardsList(
                      cards: items,
                      onCreate: () => _showCardForm(context, ref),
                      onEdit: (card) => _showCardForm(context, ref, card: card),
                      onDelete: (card) => _confirmDeleteCard(
                        context: context,
                        ref: ref,
                        card: card,
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

  Future<void> _showCardForm(
    BuildContext context,
    WidgetRef ref, {
    CardModel? card,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.92,
        child: CardFormModal(
          card: card,
          onSubmit: (front, back) {
            final repository = ref.read(cardRepositoryProvider);
            if (card == null) {
              return repository.createCard(
                deckId: deckId,
                front: front,
                back: back,
              );
            }
            return repository.updateCard(card: card, front: front, back: back);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCard({
    required BuildContext context,
    required WidgetRef ref,
    required CardModel card,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(CardText.confirmDeleteCardTitle),
        content: const Text(CardText.confirmDeleteCardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(CardText.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(CardText.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(cardRepositoryProvider).deleteCard(card);
    }
  }
}

class _DeckHeader extends StatelessWidget {
  const _DeckHeader({required this.deck});

  final DeckModel deck;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(deck.title, style: Theme.of(context).textTheme.headlineLarge),
        if (deck.description != null) ...[
          const SizedBox(height: AppDimensions.sm),
          Text(
            deck.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

class _CardsList extends StatelessWidget {
  const _CardsList({
    required this.cards,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CardModel> cards;
  final VoidCallback onCreate;
  final ValueChanged<CardModel> onEdit;
  final ValueChanged<CardModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return EmptyState(
        title: CardText.emptyTitle,
        message: CardText.emptyMessage,
        actionLabel: CardText.newCard,
        onAction: onCreate,
      );
    }

    return ListView.separated(
      itemCount: cards.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.lg),
      itemBuilder: (context, index) {
        final card = cards[index];
        return CardListItem(
          card: card,
          onEdit: () => onEdit(card),
          onDelete: () => onDelete(card),
        );
      },
    );
  }
}

class _DeckMenu extends ConsumerWidget {
  const _DeckMenu({required this.deck});

  final DeckModel deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_DeckAction>(
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) async {
        switch (action) {
          case _DeckAction.edit:
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => DeckFormModal(
                deck: deck,
                onSubmit: (title, description) {
                  return ref
                      .read(deckRepositoryProvider)
                      .updateDeck(
                        deck: deck,
                        title: title,
                        description: description,
                      );
                },
              ),
            );
          case _DeckAction.delete:
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
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _DeckAction.edit, child: Text(DeckText.edit)),
        PopupMenuItem(value: _DeckAction.delete, child: Text(DeckText.delete)),
      ],
    );
  }
}

enum _DeckAction { edit, delete }
