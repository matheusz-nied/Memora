import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state.dart';
import '../cards/card_repository.dart';
import 'generate_text.dart';
import 'generated_cards_review_args.dart';
import 'widgets/generated_card_editor.dart';

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
    final hasReview = _cards.isNotEmpty && widget.args != null;

    return PopScope(
      canPop: _allowPop || !hasReview,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _allowPop || !hasReview) {
          return;
        }

        await _confirmDiscardAndPop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text(GenerateText.reviewTitle)),
        bottomNavigationBar: hasReview
            ? _SaveReviewBar(isSaving: _isSaving, onSave: _save)
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
                          return _ReviewHeader(count: _cards.length);
                        }

                        final cardIndex = index - 1;
                        final card = _cards[cardIndex];
                        return GeneratedCardEditor(
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
  const _SaveReviewBar({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Padding(
          padding: Responsive.contentPadding(
            context,
          ).copyWith(top: AppDimensions.md, bottom: AppDimensions.md),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.kContentMaxWidth,
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: GenerateText.saveCards,
                  icon: Icons.check,
                  isLoading: isSaving,
                  onPressed: onSave,
                ),
              ),
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
