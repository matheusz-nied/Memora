import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/backend/models/backend_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../cards/card_model.dart';
import '../insight_repository.dart';
import '../study_text.dart';

class InsightWidget extends ConsumerStatefulWidget {
  const InsightWidget({
    super.key,
    required this.deckId,
    required this.card,
    required this.isOnline,
    required this.onInsightGenerated,
    required this.onViewInsight,
  });

  final String deckId;
  final CardModel card;
  final bool isOnline;
  final ValueChanged<String> onInsightGenerated;
  final VoidCallback onViewInsight;

  @override
  ConsumerState<InsightWidget> createState() => _InsightWidgetState();
}

class _InsightWidgetState extends ConsumerState<InsightWidget> {
  String? _generatedInsight;
  String? _errorMessage;
  var _isLoading = false;

  @override
  void didUpdateWidget(covariant InsightWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _generatedInsight = null;
      _errorMessage = null;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final insight = _visibleInsight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  StudyText.insightTitle,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (insight != null)
                SizedBox(
                  height: AppDimensions.minTouchTarget,
                  child: TextButton.icon(
                    onPressed: widget.onViewInsight,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.article_outlined, size: 16),
                    label: Text(
                      StudyText.viewInsight,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Tooltip(
                  message: widget.isOnline
                      ? ''
                      : StudyText.insightOfflineTooltip,
                  child: SizedBox(
                    height: AppDimensions.minTouchTarget,
                    child: OutlinedButton.icon(
                      onPressed: widget.isOnline ? _generateInsight : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          120,
                          AppDimensions.minTouchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        side: BorderSide(
                          color: widget.isOnline
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.borderStrong,
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text(StudyText.generateInsight),
                    ),
                  ),
                ),
            ],
          ),
          if (insight == null && !_isLoading) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              StudyText.insightMessage,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
              ),
            ),
          ],
          if (_isLoading) ...[
            const SizedBox(height: AppDimensions.sm),
            const _InsightLoading(),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  String? get _visibleInsight {
    final savedInsight = widget.card.insight?.trim();
    if (savedInsight != null && savedInsight.isNotEmpty) {
      return savedInsight;
    }
    return _generatedInsight;
  }

  Future<void> _generateInsight() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final insight = await ref
          .read(insightRepositoryProvider)
          .generateInsight(deckId: widget.deckId, card: widget.card);
      if (!mounted) {
        return;
      }
      widget.onInsightGenerated(insight);
      setState(() {
        _generatedInsight = insight;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageFor(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _messageFor(Object error) {
    if (error is BackendException) {
      return error.message;
    }
    return StudyText.insightError;
  }
}

class _InsightLoading extends StatelessWidget {
  const _InsightLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.borderDark : AppColors.border;
    final highlightColor = isDark
        ? AppColors.borderDarkStrong
        : AppColors.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: const [
          _LoadingLine(widthFactor: 1),
          SizedBox(height: AppDimensions.sm),
          _LoadingLine(widthFactor: 0.86),
          SizedBox(height: AppDimensions.sm),
          _LoadingLine(widthFactor: 0.64),
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: AppDimensions.md,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),
    );
  }
}
