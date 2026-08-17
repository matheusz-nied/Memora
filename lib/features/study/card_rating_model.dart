import 'study_text.dart';

/// A ordem importa: o índice é persistido em `reviews.rating`.
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
    required this.repetitions,
    required this.dueDate,
  });

  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueDate;
}

const double _minEaseFactor = 1.3;
const double _maxEaseFactor = 3.0;
const int _maxIntervalDays = 365;

/// Intervalos, em dias, das duas primeiras repetições de um card novo.
///
/// Sem eles um card recém-criado já entrava no ciclo longo: acertar de
/// primeira mandava a próxima revisão para daqui a ~3 dias sem nenhuma
/// consolidação intermediária.
const List<int> _learningSteps = [1, 3];

/// "Fácil" durante o aprendizado gradua o card direto, como no Anki.
const int _easyGraduationDays = 4;

/// "Difícil" cresce devagar em vez de encolher.
const double _hardIntervalMultiplier = 1.2;

const double _easyBonus = 1.3;

StudyProgressResult calculateStudyProgress({
  required double currentEaseFactor,
  required int currentIntervalDays,
  required int repetitions,
  required CardRating rating,
  DateTime? now,
}) {
  final baseDate = now ?? DateTime.now();
  final today = DateTime(baseDate.year, baseDate.month, baseDate.day);

  final nextEaseFactor = _clampEase(switch (rating) {
    CardRating.again => currentEaseFactor - 0.20,
    CardRating.hard => currentEaseFactor - 0.15,
    CardRating.good => currentEaseFactor,
    CardRating.easy => currentEaseFactor + 0.15,
  });

  // Errar devolve o card ao início do aprendizado.
  if (rating == CardRating.again) {
    return StudyProgressResult(
      easeFactor: nextEaseFactor,
      intervalDays: 1,
      repetitions: 0,
      dueDate: today.add(const Duration(days: 1)),
    );
  }

  final safeRepetitions = repetitions < 0 ? 0 : repetitions;
  var nextRepetitions = safeRepetitions + 1;
  final int rawInterval;

  if (nextRepetitions <= _learningSteps.length) {
    if (rating == CardRating.easy) {
      nextRepetitions = _learningSteps.length + 1;
      rawInterval = _easyGraduationDays;
    } else {
      rawInterval = _learningSteps[nextRepetitions - 1];
    }
  } else {
    final base = currentIntervalDays < 1 ? 1 : currentIntervalDays;
    rawInterval = switch (rating) {
      CardRating.hard => (base * _hardIntervalMultiplier).round(),
      // Usa o ease já ajustado: multiplicar pelo ease antigo fazia a nota
      // desta revisão só valer na revisão seguinte.
      CardRating.good => (base * nextEaseFactor).round(),
      CardRating.easy => (base * nextEaseFactor * _easyBonus).round(),
      CardRating.again => 1, // inalcançável: tratado no early return acima
    };
  }

  final intervalDays = rawInterval.clamp(1, _maxIntervalDays);

  return StudyProgressResult(
    easeFactor: nextEaseFactor,
    intervalDays: intervalDays,
    repetitions: nextRepetitions,
    dueDate: today.add(Duration(days: intervalDays)),
  );
}

double _clampEase(double value) {
  return value.clamp(_minEaseFactor, _maxEaseFactor);
}
