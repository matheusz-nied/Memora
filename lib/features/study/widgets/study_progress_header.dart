import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class StudyProgressHeader extends StatelessWidget {
  const StudyProgressHeader({
    super.key,
    required this.currentIndex,
    required this.totalCards,
  });

  final int currentIndex;
  final int totalCards;

  @override
  Widget build(BuildContext context) {
    final completed = totalCards == 0 ? 0 : currentIndex.clamp(0, totalCards);
    final progress = totalCards == 0 ? 0.0 : completed / totalCards;

    return LinearProgressIndicator(
      minHeight: 4,
      value: progress,
      color: AppColors.primary,
      backgroundColor: AppColors.border,
    );
  }
}
