import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../generate_text.dart';

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = AppConstants.kCardQuantityOptions;
    final dividerColor =
        isDark ? AppColors.borderDarkStrong : AppColors.borderStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GenerateText.quantity,
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(color: dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    Expanded(
                      child: _QuantityOption(
                        quantity: options[i],
                        isSelected: value == options[i],
                        isDark: isDark,
                        onTap: () => onChanged(options[i]),
                      ),
                    ),
                    if (i < options.length - 1)
                      ColoredBox(
                        color: dividerColor,
                        child: const SizedBox(width: 1),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuantityOption extends StatelessWidget {
  const _QuantityOption({
    required this.quantity,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final int quantity;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

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
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
            child: Text(
              quantity.toString(),
              maxLines: 1,
              style: AppTypography.labelMedium.copyWith(
                color: labelColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
