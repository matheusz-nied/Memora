import 'package:flutter/material.dart';

import '../../../core/widgets/soft_progress_bar.dart';

class StudyProgressHeader extends StatelessWidget {
  const StudyProgressHeader({
    super.key,
    required this.currentIndex,
    required this.totalCards,
    required this.isDark,
  });

  final int currentIndex;
  final int totalCards;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final completed = totalCards == 0 ? 0 : currentIndex.clamp(0, totalCards);
    final progress = totalCards == 0 ? 0.0 : completed / totalCards;

    return SoftProgressBar(
      progress: progress,
      isDark: isDark,
      height: 6,
    );
  }
}
