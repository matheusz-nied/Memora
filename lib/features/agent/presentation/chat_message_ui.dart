import '../../../core/backend/models/backend_chat_message.dart';

/// UI-local model for a chat message displayed on screen.
class ChatMessageUi {
  const ChatMessageUi({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final BackendChatRole role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == BackendChatRole.user;
  bool get isAssistant => role == BackendChatRole.assistant;

  factory ChatMessageUi.fromBackend(BackendChatMessage message) {
    return ChatMessageUi(
      id: message.id,
      role: message.role,
      content: message.content,
      createdAt: message.createdAt,
    );
  }
}
