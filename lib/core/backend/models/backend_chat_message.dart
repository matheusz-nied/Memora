enum BackendChatRole { user, assistant }

class BackendChatMessage {
  const BackendChatMessage({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String deckId;
  final String userId;
  final BackendChatRole role;
  final String content;
  final DateTime createdAt;
}
