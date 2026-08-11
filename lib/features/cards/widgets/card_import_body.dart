import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../card_text.dart';
import 'card_import_format_panel.dart';

class CardImportBody extends StatelessWidget {
  const CardImportBody({
    super.key,
    required this.isDark,
    required this.isImporting,
    required this.errorMessage,
    required this.onPickFile,
  });

  final bool isDark;
  final bool isImporting;
  final String? errorMessage;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return Responsive.constrainedContent(
      child: ListView(
        padding: Responsive.contentPadding(context),
        children: [
          Text(
            CardText.importJsonTitle,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            CardText.importJsonSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.xxl),
          CardImportFormatPanel(isDark: isDark),
          if (errorMessage != null) ...[
            const SizedBox(height: AppDimensions.lg),
            Text(
              errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppDimensions.xxl),
          AppButton(
            label: isImporting ? CardText.importingJson : CardText.selectJson,
            icon: Icons.upload_file_outlined,
            isLoading: isImporting,
            onPressed: isImporting ? null : onPickFile,
          ),
        ],
      ),
    );
  }
}
