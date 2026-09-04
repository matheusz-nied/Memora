import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../deck_import_repository.dart';
import '../deck_text.dart';

class DeckImportSummaryDialog extends StatelessWidget {
  const DeckImportSummaryDialog({super.key, required this.summary});

  final DeckImportSummary summary;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(DeckText.importDecksResultTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DeckText.importDecksSummary(
                  decks: summary.imported.length,
                  cards: summary.totalCards,
                  failures: summary.failures.length,
                  ignored: summary.ignoredCards,
                ),
              ),
              if (summary.failures.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.lg),
                Text(
                  DeckText.importDecksFailuresTitle,
                  style: AppTypography.labelMedium,
                ),
                const SizedBox(height: AppDimensions.sm),
                for (final failure in summary.failures)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                    child: Text(
                      DeckText.importFailureDetail(
                        failure.fileName,
                        failure.message,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(DeckText.close),
        ),
      ],
    );
  }
}
