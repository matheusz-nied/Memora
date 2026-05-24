import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onCreateDeck,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.xl,
          vertical: AppDimensions.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeckSearchField(
              isDark: widget.isDark,
              controller: _searchController,
              hasQuery: _searchQuery.isNotEmpty,
              onClear: _clearSearch,
            ),
            const SizedBox(height: AppDimensions.xl),
            Expanded(
              child: decksAsync.when(
                loading: () => const LoadingState(),
                error: (_, __) => const ErrorState(message: DeckText.loadError),
                data: _buildDeckList,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckList(List<DeckModel> decks) {
    final filteredDecks = decks.where(_matchesSearch).toList();
    _hasMoreDecks = decks.length >= _visibleDeckLimit;

    if (filteredDecks.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return Center(
          child: Text(
            DeckText.noDecksFound,
            style: AppTypography.bodyMedium.copyWith(
              color: widget.isDark
                  ? AppColors.textSecDark
                  : AppColors.textSecondary,
            ),
          ),
        );
      }

      return EmptyState(
        title: DeckText.emptyTitle,
        message: DeckText.emptyMessage,
        actionLabel: DeckText.newDeck,
        onAction: widget.onCreateDeck,
      );
    }

    return ListView.builder(
      controller: _scrollController,
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

class _DeckSearchField extends StatelessWidget {
  const _DeckSearchField({
    required this.isDark,
    required this.controller,
    required this.hasQuery,
    required this.onClear,
  });

  final bool isDark;
  final TextEditingController controller;
  final bool hasQuery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.minTouchTarget,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark
              ? AppColors.surface.withValues(alpha: 0.08)
              : AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        style: AppTypography.bodyLarge.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: DeckText.searchDecks,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
          ),
          suffixIcon: hasQuery
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
