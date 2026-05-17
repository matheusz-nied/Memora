import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/offline_banner.dart';
import '../cards/card_model.dart';
import '../cards/card_repository.dart';
import '../decks/deck_model.dart';
import '../decks/deck_repository.dart';
import 'card_rating_model.dart';
import 'study_session_model.dart';
import 'study_text.dart';
import 'widgets/study_flashcard.dart';
import 'widgets/study_rating_bar.dart';
import 'widgets/study_summary.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  final FlutterTts _tts = FlutterTts();
  List<CardModel>? _sessionCards;
  final Set<String> _reviewedCardIds = {};
  final Set<String> _needsReviewCardIds = {};
  var _currentIndex = 0;
  var _showBack = false;
  var _isSavingRating = false;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckStreamProvider(widget.deckId));
    final cards = ref.watch(cardsStreamProvider(widget.deckId));
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Responsive.constrainedContent(
          child: deck.when(
            loading: () => const LoadingState(),
            error: (_, __) => const ErrorState(message: StudyText.loadingError),
            data: (deckValue) {
              if (deckValue == null) {
                return const ErrorState(message: StudyText.loadingError);
              }
              return cards.when(
                loading: () => const LoadingState(),
                error: (_, __) =>
                    const ErrorState(message: StudyText.loadingError),
                data: (items) => _StudyContent(
                  deck: deckValue,
                  cards: _cardsForSession(items, isOnline: isOnline),
                  currentIndex: _currentIndex,
                  showBack: _showBack,
                  isOnline: isOnline,
                  isSavingRating: _isSavingRating,
                  reviewedCardIds: _reviewedCardIds,
                  needsReviewCardIds: _needsReviewCardIds,
                  onToggleCard: () {
                    setState(() {
                      _showBack = !_showBack;
                    });
                  },
                  onSpeak: _speak,
                  onRating: _rateCurrentCard,
                  onRestart: () => _restartSession(items, isOnline: isOnline),
                  onBackToDeck: () => context.pop(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<CardModel> _cardsForSession(
    List<CardModel> cards, {
    required bool isOnline,
  }) {
    final currentIds = cards.map((card) => card.id).join('|');
    final sessionIds = _sessionCards?.map((card) => card.id).join('|');
    final canReplaceSession = _reviewedCardIds.isEmpty && _currentIndex == 0;

    if (_sessionCards == null ||
        (canReplaceSession && sessionIds != currentIds)) {
      _sessionCards = _orderedCards(cards, isOnline: isOnline);
    }

    return _sessionCards ?? const [];
  }

  List<CardModel> _orderedCards(
    List<CardModel> cards, {
    required bool isOnline,
  }) {
    final ordered = [...cards];
    if (isOnline) {
      ordered.sort((a, b) {
        final dueCompare = a.dueDate.compareTo(b.dueDate);
        if (dueCompare != 0) {
          return dueCompare;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
      return ordered;
    }

    ordered.shuffle(math.Random(DateTime.now().millisecondsSinceEpoch));
    return ordered;
  }

  Future<void> _speak(String text, DeckModel deck) async {
    await _tts.setLanguage(_ttsLanguage(deck.agentLanguage));
    await _tts.setSpeechRate(0.48);
    await _tts.speak(text);
  }

  Future<void> _rateCurrentCard(CardRating rating) async {
    final cards = _sessionCards ?? const <CardModel>[];
    if (_isSavingRating || _currentIndex >= cards.length) {
      return;
    }

    final card = cards[_currentIndex];
    final result = calculateStudyProgress(
      currentEaseFactor: card.easeFactor,
      currentIntervalDays: card.intervalDays,
      rating: rating,
    );

    setState(() {
      _isSavingRating = true;
    });

    try {
      await ref
          .read(cardRepositoryProvider)
          .updateProgress(
            card: card,
            easeFactor: result.easeFactor,
            intervalDays: result.intervalDays,
            dueDate: result.dueDate,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _reviewedCardIds.add(card.id);
        if (rating == CardRating.again || rating == CardRating.hard) {
          _needsReviewCardIds.add(card.id);
        }
        _currentIndex += 1;
        _showBack = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingRating = false;
        });
      }
    }
  }

  void _restartSession(List<CardModel> cards, {required bool isOnline}) {
    setState(() {
      _sessionCards = _orderedCards(cards, isOnline: isOnline);
      _reviewedCardIds.clear();
      _needsReviewCardIds.clear();
      _currentIndex = 0;
      _showBack = false;
    });
  }

  String _ttsLanguage(String language) {
    final normalized = language.toLowerCase();
    if (normalized.contains('ingl') || normalized.contains('english')) {
      return 'en-US';
    }
    if (normalized.contains('espan') || normalized.contains('spanish')) {
      return 'es-ES';
    }
    return 'pt-BR';
  }
}

class _StudyContent extends StatelessWidget {
  const _StudyContent({
    required this.deck,
    required this.cards,
    required this.currentIndex,
    required this.showBack,
    required this.isOnline,
    required this.isSavingRating,
    required this.reviewedCardIds,
    required this.needsReviewCardIds,
    required this.onToggleCard,
    required this.onSpeak,
    required this.onRating,
    required this.onRestart,
    required this.onBackToDeck,
  });

  final DeckModel deck;
  final List<CardModel> cards;
  final int currentIndex;
  final bool showBack;
  final bool isOnline;
  final bool isSavingRating;
  final Set<String> reviewedCardIds;
  final Set<String> needsReviewCardIds;
  final VoidCallback onToggleCard;
  final void Function(String text, DeckModel deck) onSpeak;
  final ValueChanged<CardRating> onRating;
  final VoidCallback onRestart;
  final VoidCallback onBackToDeck;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cards.isEmpty) {
      return EmptyState(
        title: StudyText.emptyTitle,
        message: StudyText.emptyMessage,
        actionLabel: StudyText.backToDeck,
        onAction: onBackToDeck,
      );
    }

    if (currentIndex >= cards.length) {
      return StudySummary(
        summary: StudySessionSummary.fromRatings(
          totalCards: cards.length,
          reviewedCardIds: reviewedCardIds,
          needsReviewCardIds: needsReviewCardIds,
        ),
        onRestart: onRestart,
        onBackToDeck: onBackToDeck,
      );
    }

    final currentCard = cards[currentIndex];
    final completed = currentIndex.clamp(0, cards.length);
    final progress = cards.isEmpty ? 0.0 : completed / cards.length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.xl,
            horizontal: AppDimensions.xl,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress dots
                  if (cards.length <= 20)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(cards.length, (index) {
                        final isActive = index == currentIndex;
                        final isPast = index < currentIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.xs / 2,
                          ),
                          height: 6,
                          width: isActive ? 32 : 6,
                          decoration: BoxDecoration(
                            color: isActive || isPast
                                ? AppColors.primary
                                : (isDark
                                    ? const Color(0xFF324467)
                                    : AppColors.borderStrong),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusFull),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      }),
                    )
                  else
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                        backgroundColor: isDark
                            ? const Color(0xFF324467)
                            : AppColors.borderStrong,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: AppDimensions.md),
                  // Deck title
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school,
                        size: 14,
                        color: (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary)
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Flexible(
                        child: Text(
                          'SESSÃO: ${deck.title}'.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary)
                                .withValues(alpha: 0.6),
                            letterSpacing: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Close button
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color:
                      isDark ? AppColors.textSecDark : AppColors.textSecondary,
                  onPressed: onBackToDeck,
                ),
              ),
            ],
          ),
        ),
        if (!isOnline) const OfflineBanner(message: StudyText.offline),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: StudyFlashcard(
                  front: currentCard.front,
                  back: currentCard.back,
                  showBack: showBack,
                  onToggle: onToggleCard,
                  onSpeak: () => onSpeak(
                    showBack ? currentCard.back : currentCard.front,
                    deck,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.lg,
            AppDimensions.xl,
            AppDimensions.xxxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: showBack
                ? StudyRatingBar(enabled: !isSavingRating, onRating: onRating)
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onToggleCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusXl),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.visibility, size: 20),
                          const SizedBox(width: AppDimensions.sm),
                          Text(
                            StudyText.revealAnswer,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
