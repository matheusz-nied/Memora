import '../../core/database/app_database.dart';

class CardModel {
  const CardModel({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.easeFactor,
    required this.intervalDays,
    required this.dueDate,
    required this.syncPending,
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
  final DateTime dueDate;
  final bool syncPending;
  final String? insight;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CardModel.fromLocal(LocalCard card) {
    return CardModel(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      easeFactor: card.easeFactor,
      intervalDays: card.intervalDays,
      dueDate: DateTime.fromMillisecondsSinceEpoch(card.dueDate),
      syncPending: card.syncPending,
      insight: card.insight,
      createdAt: DateTime.fromMillisecondsSinceEpoch(card.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(card.updatedAt),
    );
  }
}
