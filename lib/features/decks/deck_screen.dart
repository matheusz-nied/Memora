import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/glass_search_field.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/scaffold_shell.dart';
import '../cards/card_model.dart';
import '../cards/card_repository.dart';
import '../cards/card_text.dart';
import '../cards/widgets/card_form_modal.dart';
import '../cards/widgets/card_list_item.dart';
import '../study/study_text.dart';
import 'deck_card_counts_provider.dart';
import 'deck_model.dart';
import 'deck_repository.dart';
import 'deck_text.dart';
import 'widgets/deck_form_modal.dart';
import 'widgets/home/deck_visual_style.dart';

class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  var _visibleCardLimit = AppConstants.kLocalPageSize;
  var _hasMoreCards = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreCardsIfNeeded);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreCardsIfNeeded);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  void _loadMoreCardsIfNeeded() {
    if (!_hasMoreCards || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter > 360) {
      return;
    }

    setState(() {
      _visibleCardLimit += AppConstants.kLocalPageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deckAsync = ref.watch(deckStreamProvider(widget.deckId));
    final cardsAsync = ref.watch(
      cardsPageProvider((deckId: widget.deckId, limit: _visibleCardLimit)),
    );
    final countsAsync = ref.watch(deckCardCountsStreamProvider(widget.deckId));
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return ScaffoldShell(
      isDark: isDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detalhes do Deck',
          style: AppTypography.headingMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          deckAsync.maybeWhen(
            data: (deck) => deck == null
                ? const SizedBox.shrink()
                : _DeckSettingsMenu(deck: deck),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCardForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: deckAsync.when(
          loading: () => const LoadingState(),
          error: (_, __) => const ErrorState(message: DeckText.loadError),
          data: (deck) {
            if (deck == null) {
              return const ErrorState(message: DeckText.deckNotFound);
            }

            return Responsive.constrainedContent(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.xl,
                      AppDimensions.md,
                      AppDimensions.xl,
                      0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        countsAsync.maybeWhen(
                          data: (counts) => _DeckHeroCard(
                            deck: deck,
                            counts: counts,
                            isDark: isDark,
                          ),
                          orElse: () => _DeckHeroCard(
                            deck: deck,
                            counts: null,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),
                        _QuickActionsRow(
                          deck: deck,
                          isOnline: isOnline,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DeckText.yourCards,
                              style: AppTypography.headingMedium.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            countsAsync.maybeWhen(
                              data: (counts) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.md,
                                  vertical: AppDimensions.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Text(
                                  '${counts.total} Cards',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecDark
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        GlassSearchField(
                          isDark: isDark,
                          controller: _searchController,
                          hintText: DeckText.searchCards,
                          hasQuery: _searchQuery.isNotEmpty,
                          onClear: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                        const SizedBox(height: AppDimensions.lg),
                      ]),
                    ),
                  ),
                  ...cardsAsync.when(
                    loading: () => [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: LoadingState(),
                      ),
                    ],
                    error: (_, __) => [
                      const SliverFillRemaining(
                        hasScrollBody: true,
                        child: ErrorState(message: CardText.loadError),
                      ),
                    ],
                    data: (items) {
                      final filteredCards = items.where((card) {
                        if (_searchQuery.isEmpty) return true;
                        return card.front.toLowerCase().contains(
                              _searchQuery,
                            ) ||
                            card.back.toLowerCase().contains(_searchQuery);
                      }).toList();

                      _hasMoreCards = items.length >= _visibleCardLimit;

                      if (filteredCards.isEmpty) {
                        return [
                          SliverFillRemaining(
                            hasScrollBody: true,
                            child: _searchQuery.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(
                                      AppDimensions.xl,
                                    ),
                                    child: Text(
                                      'Nenhum flashcard corresponde à busca.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppColors.textSecDark
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : EmptyState(
                                    title: CardText.emptyTitle,
                                    message: CardText.emptyMessage,
                                    actionLabel: CardText.newCard,
                                    onAction: () => _showCardForm(context),
                                  ),
                          ),
                        ];
                      }

                      return [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.xl,
                          ),
                          sliver: SliverList.separated(
                            itemCount: filteredCards.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppDimensions.md),
                            itemBuilder: (context, index) {
                              final card = filteredCards[index];
                              return CardListItem(
                                card: card,
                                onEdit: () =>
                                    _showCardForm(context, card: card),
                                onDelete: () => _confirmDeleteCard(
                                  context: context,
                                  card: card,
                                ),
                              );
                            },
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 120),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCardForm(BuildContext context, {CardModel? card}) {
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
                deckId: widget.deckId,
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

// ==========================================
// COMPONENT: DECK HERO DETAILS CARD
// ==========================================
class _DeckHeroCard extends StatelessWidget {
  const _DeckHeroCard({
    required this.deck,
    required this.counts,
    required this.isDark,
  });

  final DeckModel deck;
  final DeckCardCounts? counts;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final visual = DeckVisualStyle.fromTitle(deck.title, isDark);
    final total = counts?.total ?? 0;
    final due = counts?.due ?? 0;

    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Title + Description Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Math colored icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: visual.backgroundColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(visual.icon, color: visual.color, size: 26),
                ),
                const SizedBox(width: AppDimensions.lg),

                // Title and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.title,
                        style: AppTypography.headingLarge.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (deck.description != null &&
                          deck.description!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.xs),
                        Text(
                          deck.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecDark
                                : AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // Horizontal stats and metadata badges
            Row(
              children: [
                const Spacer(),

                // Total cards count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textTertDark
                            : AppColors.textTertiary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$total',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppDimensions.xl),

                // Cards due counts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'A REVISAR',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textTertDark
                            : AppColors.textTertiary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$due',
                      style: AppTypography.bodyLarge.copyWith(
                        color: due > 0
                            ? AppColors.warning
                            : (isDark
                                  ? AppColors.textSecDark
                                  : AppColors.textSecondary),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
    );
  }
}

// ==========================================
// COMPONENT: HORIZONTAL QUICK ACTIONS ROW
// ==========================================
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.deck,
    required this.isOnline,
    required this.isDark,
  });

  final DeckModel deck;
  final bool isOnline;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary full-width button to Estudar Agora
        NeonButton(
          label: DeckText.studyNow,
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            context.push(RouteConstants.studyPath(deck.id));
          },
        ),
        const SizedBox(height: AppDimensions.xs),

        // Escape hatch para quem quer revisar o deck inteiro fora do
        // agendamento — a sessão normal traz só o que vence hoje.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.push(
              RouteConstants.studyPath(deck.id, freeStudy: true),
            ),
            icon: const Icon(Icons.all_inclusive, size: 18),
            label: const Text(StudyText.freeStudy),
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        // Sub horizontal grid with other three actions
        Row(
          children: [
            // Chat button
            Expanded(
              child: _QuickActionButton(
                icon: Icons.chat_bubble_outline,
                label: DeckText.chatTutor,
                isDark: isDark,
                isEnabled: isOnline,
                tooltip: isOnline
                    ? null
                    : 'Requer conexão com a internet para chat',
                onTap: () {
                  context.push(RouteConstants.chatPath(deck.id));
                },
              ),
            ),
            const SizedBox(width: AppDimensions.md),

            // Generate with AI
            Expanded(
              child: _QuickActionButton(
                icon: Icons.auto_awesome,
                label: DeckText.importAi,
                isDark: isDark,
                isEnabled: isOnline,
                tooltip: isOnline
                    ? null
                    : 'Requer conexão com a internet para gerar cards',
                onTap: () {
                  context.push(RouteConstants.generatePath(deck.id));
                },
              ),
            ),
            const SizedBox(width: AppDimensions.md),

            // Settings Config
            Expanded(
              child: _QuickActionButton(
                icon: Icons.tune,
                label: DeckText.deckSettings,
                isDark: isDark,
                isEnabled: true,
                onTap: () {
                  context.push(RouteConstants.agentConfigPath(deck.id));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Sub element of the quick action grid buttons
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isEnabled = true,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: PressableScale(
          onTap: isEnabled ? onTap : null,
          child: GlassPanel(
            isDark: isDark,
            showGlow: false,
            showTopHighlight: false,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled
                      ? AppColors.primary
                      : (isDark ? Colors.white30 : Colors.black26),
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isEnabled
                        ? (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary)
                        : (isDark ? Colors.white30 : Colors.black26),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENT: APP BAR DECK SETTINGS MENU
// ==========================================
class _DeckSettingsMenu extends ConsumerWidget {
  const _DeckSettingsMenu({required this.deck});

  final DeckModel deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<_DeckAction>(
      icon: Icon(
        Icons.more_horiz,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        size: 26,
      ),
      onSelected: (action) async {
        switch (action) {
          case _DeckAction.edit:
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => DeckFormModal(
                deck: deck,
                onSubmit: (title, description) async {
                  await ref
                      .read(deckRepositoryProvider)
                      .updateDeck(
                        deck: deck,
                        title: title,
                        description: description,
                      );
                  return null;
                },
              ),
            );
          case _DeckAction.agentConfig:
            context.push(RouteConstants.agentConfigPath(deck.id));
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
                context.pop();
              }
            }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _DeckAction.edit, child: Text(DeckText.edit)),
        PopupMenuItem(
          value: _DeckAction.agentConfig,
          child: Text(DeckText.agentConfig),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _DeckAction.delete,
          child: Text(
            DeckText.delete,
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

enum _DeckAction { edit, agentConfig, delete }
