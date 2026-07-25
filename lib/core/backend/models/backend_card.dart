class BackendCard {
  const BackendCard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.easeFactor,
    required this.intervalDays,
    this.repetitions = 0,
    required this.dueDate,
    this.insight,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueDate;
  final String? insight;
  final DateTime createdAt;
  final DateTime updatedAt;
}
