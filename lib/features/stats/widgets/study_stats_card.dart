import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
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
          const SizedBox(height: AppDimensions.lg),
          if (!stats.hasHistory)
            _EmptyStats(isDark: isDark)
          else ...[
            Row(
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
            const SizedBox(height: AppDimensions.xl),
            _DailyBars(
              title: StatsText.windowTotal,
              days: stats.daily.sublist(stats.daily.length - 7),
              accent: AppColors.primary,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: AppDimensions.xl),
          _DailyBars(
            title: StatsText.upcoming,
            days: stats.upcoming,
            accent: AppColors.neonBlue,
            isDark: isDark,
          ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xs),
            child: Icon(icon, color: color, size: AppDimensions.xxl),
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          value,
          style: AppTypography.headingLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Barras proporcionais ao dia mais cheio da série.
class _DailyBars extends StatelessWidget {
  const _DailyBars({
    required this.title,
    required this.days,
    required this.accent,
    required this.isDark,
  });

  final String title;
  final List<DailyCount> days;
  final Color accent;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final day in days)
              Expanded(
                child: _Bar(
                  day: day,
                  fraction: peak == 0 ? 0 : day.count / peak,
                  accent: accent,
                  isDark: isDark,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.xs),
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: Text(
                  StatsText.weekdayInitials[day.day.weekday - 1],
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertDark
                        : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.fraction,
    required this.accent,
    required this.isDark,
  });

  static const double _maxHeight = 44;
  static const double _minHeight = 4;

  final DailyCount day;
  final double fraction;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final height = _minHeight + (_maxHeight - _minHeight) * fraction;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          day.count == 0 ? '' : '${day.count}',
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        AnimatedContainer(
          duration: AppDimensions.animNormal,
          curve: Curves.easeOutCubic,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            gradient: day.count == 0
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, accent.withValues(alpha: 0.65)],
                  ),
            color: day.count == 0
                ? (isDark ? AppColors.glassBorderDark : AppColors.border)
                : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            boxShadow: day.count == 0
                ? null
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}
