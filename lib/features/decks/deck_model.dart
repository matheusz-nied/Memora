import '../../core/database/app_database.dart';

class DeckModel {
  const DeckModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.agentName,
    this.agentPrompt,
    required this.agentTemplate,
    required this.agentLanguage,
    required this.agentLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String agentName;
  final String? agentPrompt;
  final String agentTemplate;
  final String agentLanguage;
  final String agentLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DeckModel.fromLocal(LocalDeck deck) {
    return DeckModel(
      id: deck.id,
      userId: deck.userId,
      title: deck.title,
      description: deck.description,
      agentName: deck.agentName,
      agentPrompt: deck.agentPrompt,
      agentTemplate: deck.agentTemplate,
      agentLanguage: deck.agentLanguage,
      agentLevel: deck.agentLevel,
      createdAt: DateTime.fromMillisecondsSinceEpoch(deck.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(deck.updatedAt),
    );
  }
}
