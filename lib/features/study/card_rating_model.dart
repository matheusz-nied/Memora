import 'study_text.dart';

enum CardRating {
  again,
  hard,
  good,
  easy;

  String get label {
    return switch (this) {
      CardRating.again => StudyText.again,
      CardRating.hard => StudyText.hard,
      CardRating.good => StudyText.good,
      CardRating.easy => StudyText.easy,
    };
  }
}

class StudyProgressResult {
  const StudyProgressResult({
    required this.easeFactor,
    required this.intervalDays,
    required this.dueDate,
  });

  final double easeFactor;
  final int intervalDays;
  final DateTime dueDate;
}

StudyProgressResult calculateStudyProgress({
  required double currentEaseFactor,
  required int currentIntervalDays,
  required CardRating rating,
  DateTime? now,
}) {
  final baseDate = now ?? DateTime.now();
  final normalizedToday = DateTime(baseDate.year, baseDate.month, baseDate.day);

  final nextEaseFactor = switch (rating) {
    CardRating.again => _minEaseFactor(currentEaseFactor - 0.2),
    CardRating.hard => _minEaseFactor(currentEaseFactor - 0.15),
    CardRating.good => currentEaseFactor,
    CardRating.easy => currentEaseFactor + 0.1,
  };

  final nextIntervalDays = switch (rating) {
    CardRating.again => 1,
    CardRating.hard => _maxOne(currentIntervalDays - 1),
    CardRating.good => _maxOne(
      (currentIntervalDays * currentEaseFactor).round(),
    ),
    CardRating.easy => _maxOne(
      (currentIntervalDays * currentEaseFactor * 1.3).round(),
    ),
  };

  return StudyProgressResult(
    easeFactor: nextEaseFactor,
    intervalDays: nextIntervalDays,
    dueDate: normalizedToday.add(Duration(days: nextIntervalDays)),
  );
}

double _minEaseFactor(double value) {
  return value < 1.3 ? 1.3 : value;
}

int _maxOne(int value) {
  return value < 1 ? 1 : value;
}
