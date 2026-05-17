import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../generate_text.dart';

class GeneratedCardEditor extends StatelessWidget {
  const GeneratedCardEditor({
    super.key,
    required this.index,
    required this.frontController,
    required this.backController,
    required this.onRemove,
  });

  final int index;
  final TextEditingController frontController;
  final TextEditingController backController;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${GenerateText.reviewTitle} ${index + 1}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: GenerateText.remove,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            TextFormField(
              controller: frontController,
              minLines: 2,
              maxLines: null,
              maxLength: AppConstants.kMaxCardFront,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(labelText: GenerateText.front),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? GenerateText.front : null,
            ),
            const SizedBox(height: AppDimensions.md),
            TextFormField(
              controller: backController,
              minLines: 3,
              maxLines: null,
              maxLength: AppConstants.kMaxCardBack,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(labelText: GenerateText.back),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? GenerateText.back : null,
            ),
          ],
        ),
      ),
    );
  }
}
