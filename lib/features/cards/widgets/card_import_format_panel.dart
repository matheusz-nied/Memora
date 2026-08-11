import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../card_text.dart';

class CardImportFormatPanel extends StatelessWidget {
  const CardImportFormatPanel({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CardText.importJsonFormatTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            CardText.importJsonFormatDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.md),
          SelectableText(
            CardText.importJsonExample,
            style: AppTypography.bodyMedium.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            CardText.importJsonLimits(
              maxCards: AppConstants.kMaxCardsPerImport,
              maxSizeMb: AppConstants.kMaxCardImportSizeMb,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
