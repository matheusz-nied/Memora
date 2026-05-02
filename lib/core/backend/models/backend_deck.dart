class BackendDeck {
  const BackendDeck({
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
}
