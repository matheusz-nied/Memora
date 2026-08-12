import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../generate_text.dart';

enum GenerateSourceMode { text, pdf }

class SourceModeSelector extends StatelessWidget {
  const SourceModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final GenerateSourceMode value;
  final ValueChanged<GenerateSourceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor =
        isDark ? AppColors.borderDarkStrong : AppColors.borderStrong;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _ModeOption(
                  icon: Icons.notes_rounded,
                  label: GenerateText.textMode,
                  isSelected: value == GenerateSourceMode.text,
                  isDark: isDark,
                  onTap: () => onChanged(GenerateSourceMode.text),
                ),
              ),
              ColoredBox(
                color: dividerColor,
                child: const SizedBox(width: 1),
              ),
              Expanded(
                child: _ModeOption(
                  icon: Icons.picture_as_pdf_outlined,
                  label: GenerateText.pdfMode,
                  isSelected: value == GenerateSourceMode.pdf,
                  isDark: isDark,
                  onTap: () => onChanged(GenerateSourceMode.pdf),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final iconColor = isSelected ? Colors.white : AppColors.primary;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimensions.animFast,
        curve: Curves.easeOutCubic,
        height: AppDimensions.minTouchTarget,
        alignment: Alignment.center,
        color: isSelected ? AppColors.primary : Colors.transparent,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.labelMedium.copyWith(
                    color: contentColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
