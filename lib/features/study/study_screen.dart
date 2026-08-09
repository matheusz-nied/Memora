import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/scaffold_shell.dart';
import '../cards/card_model.dart';
import '../cards/card_repository.dart';
import '../decks/deck_model.dart';
import '../decks/deck_card_counts_provider.dart';
import '../decks/deck_repository.dart';
import 'card_rating_model.dart';
import 'study_session_model.dart';
import 'study_text.dart';
import 'widgets/insight_widget.dart';
import 'widgets/study_flashcard.dart';
import 'widgets/study_rating_bar.dart';
import 'widgets/study_progress_header.dart';
import 'widgets/study_summary.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key, required this.deckId, this.freeStudy = false});

  final String deckId;

  /// Revisa o deck inteiro, ignorando o vencimento. Opção explícita do menu do
  /// deck — a sessão normal traz só o que vence hoje.
  final bool freeStudy;

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
    final cards = widget.freeStudy
        ? ref.watch(cardsStreamProvider(widget.deckId))
        : ref.watch(
            dueCardsStreamProvider((
              deckId: widget.deckId,
              newCardLimit: AppConstants.kNewCardsPerSession,
            )),
          );
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);
    final deckHasCards = ref
        .watch(deckCardCountsStreamProvider(widget.deckId))
        .maybeWhen(data: (counts) => counts.total > 0, orElse: () => false);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaffoldShell(
      isDark: isDark,
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
                  freeStudy: widget.freeStudy,
                  deckHasCards: deckHasCards,
                  cards: _cardsForSession(items),
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
                  onInsightGenerated: _updateCurrentCardInsight,
                  onViewInsight: (cardId) => context.push(
                    RouteConstants.cardInsightPath(deckValue.id, cardId),
                  ),
                  onRestart: () => _restartSession(items),
                  onBackToDeck: () => context.pop(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<CardModel> _cardsForSession(List<CardModel> cards) {
    final currentIds = cards.map((card) => card.id).join('|');
    final sessionIds = _sessionCards?.map((card) => card.id).join('|');
    final canReplaceSession = _reviewedCardIds.isEmpty && _currentIndex == 0;

    if (_sessionCards == null ||
        (canReplaceSession && sessionIds != currentIds)) {
      _sessionCards = _orderedCards(cards);
    } else {
      // A sessão é congelada depois de começar: o stream reemite a cada
      // avaliação e reordenar no meio embaralharia o que o usuário está vendo.
      // Só os dados de cada card são atualizados.
      final latestById = {for (final card in cards) card.id: card};
      _sessionCards = _sessionCards
          ?.map((card) => latestById[card.id] ?? card)
          .toList();
    }

    return _sessionCards ?? const [];
  }

  /// Sempre por vencimento. Antes a lista era embaralhada quando offline, o
  /// que não fazia sentido: o `dueDate` está no banco local de qualquer jeito,
  /// e a ordem mudava conforme a conexão.
  List<CardModel> _orderedCards(List<CardModel> cards) {
    final ordered = [...cards];
    ordered.sort((a, b) {
      final dueCompare = a.dueDate.compareTo(b.dueDate);
      if (dueCompare != 0) {
        return dueCompare;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return ordered;
  }

  Future<void> _speak(String text, DeckModel deck) async {
    final lang = _ttsLanguage(deck.agentLanguage, text, deck.title);
    try {
      await _tts.setLanguage(lang);
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
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
      repetitions: card.repetitions,
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
            repetitions: result.repetitions,
            dueDate: result.dueDate,
            rating: rating.index,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _reviewedCardIds.add(card.id);
        if (rating == CardRating.again || rating == CardRating.hard) {
          _needsReviewCardIds.add(card.id);
        }
        if (rating == CardRating.again) {
          // Recoloca o card no fim da fila: sem isto "Não sei" não tinha
          // nenhuma consequência dentro da sessão e o usuário nunca revia o
          // card que acabou de errar.
          _sessionCards = [...cards, card];
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

  void _updateCurrentCardInsight(String insight) {
    final cards = _sessionCards;
    if (cards == null || _currentIndex >= cards.length) {
      return;
    }

    setState(() {
      final currentCard = cards[_currentIndex];
      _sessionCards = [
        for (final card in cards)
          if (card.id == currentCard.id)
            card.copyWith(insight: insight, updatedAt: DateTime.now())
          else
            card,
      ];
    });
  }

  void _restartSession(List<CardModel> cards) {
    setState(() {
      _sessionCards = _orderedCards(cards);
      _reviewedCardIds.clear();
      _needsReviewCardIds.clear();
      _currentIndex = 0;
      _showBack = false;
    });
  }

  String _ttsLanguage(String language, String text, String deckTitle) {
    final normalized = language.toLowerCase();
    final normalizedTitle = deckTitle.toLowerCase();
    final normalizedText = text.toLowerCase().trim();

    if (normalized.contains('ingl') || normalized.contains('english')) {
      return 'en-US';
    }
    if (normalized.contains('espan') || normalized.contains('spanish')) {
      return 'es-ES';
    }

    // Heuristics: Check deck title for hints
    if (normalizedTitle.contains('ingl') ||
        normalizedTitle.contains('english') ||
        normalizedTitle.contains('vocab') ||
        normalizedTitle.contains('english study')) {
      return 'en-US';
    }
    if (normalizedTitle.contains('espan') ||
        normalizedTitle.contains('spanish')) {
      return 'es-ES';
    }

    // Heuristics: Check for common English words in card text
    final englishStopwords = {
      'the',
      'be',
      'to',
      'of',
      'and',
      'a',
      'in',
      'that',
      'have',
      'i',
      'it',
      'for',
      'not',
      'on',
      'with',
      'he',
      'as',
      'you',
      'do',
      'at',
      'this',
      'but',
      'his',
      'by',
      'from',
      'they',
      'we',
      'say',
      'her',
      'she',
      'or',
      'an',
      'will',
      'my',
      'one',
      'all',
      'would',
      'there',
      'their',
      'what',
      'so',
      'up',
      'out',
      'if',
      'about',
      'who',
      'get',
      'which',
      'go',
      'me',
    };

    final words = normalizedText
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'));

    int englishCount = 0;
    for (final word in words) {
      if (englishStopwords.contains(word)) {
        englishCount++;
      }
    }

    if (englishCount >= 1) {
      return 'en-US';
    }

    return 'pt-BR';
  }
}

class _StudyContent extends StatelessWidget {
  const _StudyContent({
    required this.deck,
    required this.freeStudy,
    required this.deckHasCards,
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
    required this.onInsightGenerated,
    required this.onViewInsight,
    required this.onRestart,
    required this.onBackToDeck,
  });

  final DeckModel deck;
  final bool freeStudy;
  final bool deckHasCards;
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
  final ValueChanged<String> onInsightGenerated;
  final ValueChanged<String> onViewInsight;
  final VoidCallback onRestart;
  final VoidCallback onBackToDeck;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cards.isEmpty) {
      // Deck com cards mas nada vencido é sucesso, não estado de erro.
      final caughtUp = deckHasCards && !freeStudy;
      return EmptyState(
        title: caughtUp ? StudyText.allCaughtUpTitle : StudyText.emptyTitle,
        message: caughtUp
            ? StudyText.allCaughtUpMessage
            : StudyText.emptyMessage,
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
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                        );
                      }),
                    )
                  else
                    SizedBox(
                      width: 200,
                      child: StudyProgressHeader(
                        currentIndex: currentIndex,
                        totalCards: cards.length,
                        isDark: isDark,
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
                        color:
                            (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary)
                                .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Flexible(
                        child: Text(
                          'SESSÃO: ${deck.title}'.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color:
                                (isDark
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
                  color: isDark
                      ? AppColors.textSecDark
                      : AppColors.textSecondary,
                  onPressed: onBackToDeck,
                ),
              ),
            ],
          ),
        ),
        if (freeStudy) const OfflineBanner(message: StudyText.freeStudyBanner),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
            child: Align(
              alignment: const Alignment(0, 0.45),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StudyFlashcard(
                        front: currentCard.front,
                        back: currentCard.back,
                        showBack: showBack,
                        onToggle: onToggleCard,
                        onSpeak: () => onSpeak(
                          showBack ? currentCard.back : currentCard.front,
                          deck,
                        ),
                      ),
                      Opacity(
                        opacity: showBack ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !showBack,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: AppDimensions.md),
                              InsightWidget(
                                deckId: deck.id,
                                card: currentCard,
                                isOnline: isOnline,
                                onInsightGenerated: onInsightGenerated,
                                onViewInsight: () =>
                                    onViewInsight(currentCard.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
            AppDimensions.sm,
            AppDimensions.xl,
            AppDimensions.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: showBack
                ? StudyRatingBar(enabled: !isSavingRating, onRating: onRating)
                : NeonButton(
                    label: StudyText.revealAnswer,
                    icon: Icons.visibility,
                    onPressed: onToggleCard,
                  ),
          ),
        ),
      ],
    );
  }
}
