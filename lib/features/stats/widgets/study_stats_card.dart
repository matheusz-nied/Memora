import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/soft_progress_bar.dart';
import '../stats_text.dart';
import '../study_stats.dart';
import '../study_stats_provider.dart';

/// Progresso real do estudo, direto da tabela `reviews`.
class StudyStatsCard extends ConsumerWidget {
  const StudyStatsCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(studyStatsProvider);

    return statsAsync.maybeWhen(
      data: (stats) => _StatsBody(stats: stats, isDark: isDark),
      // Estatística é acessório: enquanto carrega ou se falhar, o dashboard
      // não pode ficar com um erro no meio dele.
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats, required this.isDark});

  final StudyStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    return GlassPanel(
      isDark: isDark,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 20,
                color: isDark ? AppColors.neonCyan : AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                StatsText.title,
                style: AppTypography.headingMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!stats.hasHistory)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.lg),
              child: _EmptyStats(isDark: isDark),
            )
          else ...[
            const SizedBox(height: AppDimensions.lg),
            _MetricsRow(stats: stats, isDark: isDark),
            const SizedBox(height: AppDimensions.xl),
            _SectionHeader(
              title: StatsText.windowTotal,
              trailing: StatsText.reviews(stats.totalReviews),
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.md),
            _ActivitySparkline(days: stats.daily, isDark: isDark),
            const SizedBox(height: AppDimensions.sm),
            _SparklineCaptions(isDark: isDark),
          ],
          if (stats.upcoming.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.xl),
            _SectionHeader(
              title: StatsText.upcoming,
              trailing: StatsText.cards(
                stats.upcoming.fold<int>(0, (sum, day) => sum + day.count),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.md),
            _UpcomingList(days: stats.upcoming, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      StatsText.emptyMessage,
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.stats, required this.isDark});

  final StudyStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        color: isDark
            ? AppColors.surfaceDeep.withValues(alpha: 0.65)
            : AppColors.background.withValues(alpha: 0.7),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.md,
          horizontal: AppDimensions.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: _Metric(
                icon: Icons.local_fire_department_outlined,
                color: AppColors.warning,
                label: StatsText.streak,
                value: StatsText.days(stats.streakDays),
                isDark: isDark,
              ),
            ),
            _MetricDivider(isDark: isDark),
            Expanded(
              child: _Metric(
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                label: StatsText.accuracy,
                value: stats.accuracy == null
                    ? '—'
                    : StatsText.percent(stats.accuracy!),
                isDark: isDark,
              ),
            ),
            _MetricDivider(isDark: isDark),
            Expanded(
              child: _Metric(
                icon: Icons.today_outlined,
                color: AppColors.neonCyan,
                label: StatsText.reviewsToday,
                value: '${stats.reviewsToday}',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: isDark
          ? AppColors.glassBorderDark
          : AppColors.textPrimary.withValues(alpha: 0.08),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: AppDimensions.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: AppTypography.headingMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    required this.isDark,
  });

  final String title;
  final String trailing;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          trailing,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActivitySparkline extends StatelessWidget {
  const _ActivitySparkline({required this.days, required this.isDark});

  static const double _maxHeight = 36;
  static const double _minHeight = 3;
  static const double _barWidth = 5;

  final List<DailyCount> days;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final peak = days.fold<int>(
      0,
      (max, day) => day.count > max ? day.count : max,
    );

    return SizedBox(
      height: _maxHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _SparkBar(
                  height: peak == 0
                      ? _minHeight
                      : _minHeight +
                            (_maxHeight - _minHeight) * (days[i].count / peak),
                  width: _barWidth,
                  filled: days[i].count > 0,
                  highlight: i == days.length - 1,
                  accent: AppColors.primary,
                  isDark: isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SparkBar extends StatelessWidget {
  const _SparkBar({
    required this.height,
    required this.width,
    required this.filled,
    required this.highlight,
    required this.accent,
    required this.isDark,
  });

  final double height;
  final double width;
  final bool filled;
  final bool highlight;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = filled
        ? (highlight ? AppColors.neonCyan : accent)
        : (isDark ? AppColors.glassBorderDark : AppColors.border);

    return AnimatedContainer(
      duration: AppDimensions.animNormal,
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: filled ? null : color,
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withValues(alpha: 0.7)],
              )
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
    );
  }
}

class _SparklineCaptions extends StatelessWidget {
  const _SparklineCaptions({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
    );

    return Row(
      children: [
        Text(StatsText.windowStart, style: style),
        const Spacer(),
        Text(StatsText.reviewsToday, style: style),
      ],
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.days, required this.isDark});

  final List<DailyCount> days;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final peak = days.fold<int>(
      0,
      (max, day) => day.count > max ? day.count : max,
    );

    return Column(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimensions.sm),
          _UpcomingRow(
            label: i == 0
                ? StatsText.reviewsToday
                : StatsText.weekdayShort[days[i].day.weekday - 1],
            count: days[i].count,
            progress: peak == 0 || days[i].count == 0
                ? 0
                : (days[i].count / peak).clamp(0.08, 1.0),
            isDark: isDark,
            emphasize: i == 0,
          ),
        ],
      ],
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.label,
    required this.count,
    required this.progress,
    required this.isDark,
    required this.emphasize,
  });

  final String label;
  final int count;
  final double progress;
  final bool isDark;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final labelColor = emphasize
        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
        : (isDark ? AppColors.textSecDark : AppColors.textSecondary);
    final countColor = count == 0
        ? (isDark ? AppColors.textTertDark : AppColors.textTertiary)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: labelColor,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: SoftProgressBar(
            progress: progress,
            isDark: isDark,
            height: 8,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: AppTypography.bodySmall.copyWith(
              color: countColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
