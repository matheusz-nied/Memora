import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/scaffold_shell.dart';
import '../cards/card_repository.dart';
import 'generate_text.dart';
import 'generated_cards_review_args.dart';
import 'widgets/generated_card_editor.dart';
import '../legal/widgets/ai_disclaimer_note.dart';

class ReviewCardsScreen extends ConsumerStatefulWidget {
  const ReviewCardsScreen({super.key, required this.args});

  final GeneratedCardsReviewArgs? args;

  @override
  ConsumerState<ReviewCardsScreen> createState() => _ReviewCardsScreenState();
}

class _ReviewCardsScreenState extends ConsumerState<ReviewCardsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final List<_DraftCardControllers> _cards;
  var _isSaving = false;
  var _allowPop = false;

  @override
  void initState() {
    super.initState();
    _cards =
        widget.args?.cards
            .map(
              (card) =>
                  _DraftCardControllers(front: card.front, back: card.back),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    for (final card in _cards) {
      card.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasReview = _cards.isNotEmpty && widget.args != null;

    return PopScope(
      canPop: _allowPop || !hasReview,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _allowPop || !hasReview) {
          return;
        }

        await _confirmDiscardAndPop();
      },
      child: ScaffoldShell(
        isDark: isDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            GenerateText.reviewTitle,
            style: AppTypography.headingMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        bottomNavigationBar: hasReview
            ? _SaveReviewBar(isDark: isDark, isSaving: _isSaving, onSave: _save)
            : null,
        body: SafeArea(
          child: Responsive.constrainedContent(
            child: !hasReview
                ? EmptyState(
                    title: GenerateText.emptyReviewTitle,
                    message: GenerateText.emptyReviewMessage,
                    actionLabel: GenerateText.generate,
                    onAction: () => context.pop(),
                  )
                : Form(
                    key: _formKey,
                    child: ListView.separated(
                      padding: Responsive.contentPadding(
                        context,
                      ).copyWith(bottom: AppDimensions.xxxl),
                      itemCount: _cards.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppDimensions.lg),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ReviewHeader(count: _cards.length),
                              const AiDisclaimerNote(),
                            ],
                          );
                        }

                        final cardIndex = index - 1;
                        final card = _cards[cardIndex];
                        return GeneratedCardEditor(
                          isDark: isDark,
                          index: cardIndex,
                          frontController: card.frontController,
                          backController: card.backController,
                          onRemove: () => _removeCard(cardIndex),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _removeCard(int index) {
    setState(() {
      _cards.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || widget.args == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(cardRepositoryProvider);
      for (final card in _cards) {
        await repository.createCard(
          deckId: widget.args!.deckId,
          front: card.frontController.text,
          back: card.backController.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text(GenerateText.saved)));
        _allowPop = true;
        context.pop();
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDiscardAndPop() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(GenerateText.discardReviewTitle),
        content: const Text(GenerateText.discardReviewMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(GenerateText.discardReviewCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(GenerateText.discardReviewConfirm),
          ),
        ],
      ),
    );

    if (!mounted || shouldDiscard != true) {
      return;
    }

    setState(() => _allowPop = true);
    context.pop();
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GenerateText.reviewTitle,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          GenerateText.reviewSubtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SaveReviewBar extends StatelessWidget {
  const _SaveReviewBar({
    required this.isDark,
    required this.isSaving,
    required this.onSave,
  });

  final bool isDark;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GlassPanel(
        isDark: isDark,
        showGlow: false,
        borderRadius: BorderRadius.zero,
        showTopHighlight: false,
        padding: Responsive.contentPadding(
          context,
        ).copyWith(top: AppDimensions.md, bottom: AppDimensions.md),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.kContentMaxWidth,
            ),
            child: NeonButton(
              label: GenerateText.saveCards,
              icon: Icons.check,
              onPressed: isSaving ? null : onSave,
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftCardControllers {
  _DraftCardControllers({required String front, required String back})
    : frontController = TextEditingController(text: front),
      backController = TextEditingController(text: back);

  final TextEditingController frontController;
  final TextEditingController backController;

  void dispose() {
    frontController.dispose();
    backController.dispose();
  }
}
