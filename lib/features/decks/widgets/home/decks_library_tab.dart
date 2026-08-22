import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/glass_search_field.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../deck_model.dart';
import '../../deck_repository.dart';
import '../../deck_text.dart';
import 'library_deck_card.dart';

class DecksLibraryTab extends ConsumerStatefulWidget {
  const DecksLibraryTab({
    super.key,
    required this.isDark,
    required this.onCreateDeck,
    required this.onEditDeck,
    required this.onDeleteDeck,
  });

  final bool isDark;
  final VoidCallback onCreateDeck;
  final ValueChanged<DeckModel> onEditDeck;
  final ValueChanged<DeckModel> onDeleteDeck;

  @override
  ConsumerState<DecksLibraryTab> createState() => _DecksLibraryTabState();
}

class _DecksLibraryTabState extends ConsumerState<DecksLibraryTab> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  var _searchQuery = '';
  var _visibleDeckLimit = AppConstants.kLocalPageSize;
  var _hasMoreDecks = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreDecksIfNeeded);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreDecksIfNeeded);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(decksPageProvider(_visibleDeckLimit));
    final width = MediaQuery.sizeOf(context).width;
    final isTabletOrDesktop = width >= 600;

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.lg,
            AppDimensions.xl,
            AppDimensions.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: GlassSearchField(
              isDark: widget.isDark,
              controller: _searchController,
              hintText: DeckText.searchDecks,
              hasQuery: _searchQuery.isNotEmpty,
              onClear: _clearSearch,
            ),
          ),
        ),
        ...decksAsync.when(
          loading: () => [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingState(),
            ),
          ],
          error: (_, __) => [
            const SliverFillRemaining(
              hasScrollBody: true,
              child: ErrorState(message: DeckText.loadError),
            ),
          ],
          data: (decks) {
            final filteredDecks = decks.where(_matchesSearch).toList();
            _hasMoreDecks = decks.length >= _visibleDeckLimit;

            if (filteredDecks.isEmpty) {
              return [
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.xl,
                    ),
                    child: _searchQuery.isNotEmpty
                        ? Center(
                            child: Text(
                              DeckText.noDecksFound,
                              style: AppTypography.bodyMedium.copyWith(
                                color: widget.isDark
                                    ? AppColors.textSecDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          )
                        : EmptyState(
                            title: DeckText.emptyTitle,
                            message: DeckText.emptyMessage,
                            actionLabel: DeckText.newDeck,
                            onAction: widget.onCreateDeck,
                          ),
                  ),
                ),
              ];
            }

            if (isTabletOrDesktop) {
              return [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xl,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppDimensions.lg,
                          mainAxisSpacing: AppDimensions.sm,
                          childAspectRatio: 2.0,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final deck = filteredDecks[index];
                      return LibraryDeckCard(
                        deck: deck,
                        isDark: widget.isDark,
                        onEdit: () => widget.onEditDeck(deck),
                        onDelete: () => widget.onDeleteDeck(deck),
                      );
                    }, childCount: filteredDecks.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ];
            }

            return [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.xl,
                ),
                sliver: SliverList.builder(
                  itemCount: filteredDecks.length,
                  itemBuilder: (context, index) {
                    final deck = filteredDecks[index];
                    return LibraryDeckCard(
                      deck: deck,
                      isDark: widget.isDark,
                      onEdit: () => widget.onEditDeck(deck),
                      onDelete: () => widget.onDeleteDeck(deck),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ];
          },
        ),
      ],
    );
  }

  bool _matchesSearch(DeckModel deck) {
    final titleMatch = deck.title.toLowerCase().contains(_searchQuery);
    final descMatch =
        deck.description?.toLowerCase().contains(_searchQuery) ?? false;
    return titleMatch || descMatch;
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _loadMoreDecksIfNeeded() {
    if (!_hasMoreDecks || !_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter > 360) {
      return;
    }

    setState(() => _visibleDeckLimit += AppConstants.kLocalPageSize);
  }
}
