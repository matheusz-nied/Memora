import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../profile_text.dart';

class AppearanceTile extends ConsumerWidget {
  const AppearanceTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: () => _showThemePicker(context),
      child: GlassPanel(
        isDark: isDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        showGlow: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.sm,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppDimensions.sm),
                child: Icon(
                  Icons.brightness_6_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ProfileText.appearance,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    _labelFor(mode),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThemePicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Consumer(
        builder: (context, sheetRef, child) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.lg,
            0,
            AppDimensions.lg,
            AppDimensions.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ProfileText.chooseTheme,
                style: AppTypography.headingMedium.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              for (final option in const [
                ThemeMode.dark,
                ThemeMode.light,
                ThemeMode.system,
              ])
                _ThemeOptionTile(
                  mode: option,
                  selected: sheetRef.watch(themeModeProvider) == option,
                  onTap: () async {
                    await sheetRef
                        .read(themeModeProvider.notifier)
                        .setMode(option);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _labelFor(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => ProfileText.darkTheme,
    ThemeMode.light => ProfileText.lightTheme,
    ThemeMode.system => ProfileText.systemTheme,
  };
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, icon) = switch (mode) {
      ThemeMode.dark => (
        ProfileText.darkTheme,
        ProfileText.darkThemeHint,
        Icons.dark_mode_outlined,
      ),
      ThemeMode.light => (
        ProfileText.lightTheme,
        ProfileText.lightThemeHint,
        Icons.light_mode_outlined,
      ),
      ThemeMode.system => (
        ProfileText.systemTheme,
        ProfileText.systemThemeHint,
        Icons.settings_suggest_outlined,
      ),
    };

    return ListTile(
      minTileHeight: AppDimensions.minTouchTarget,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
