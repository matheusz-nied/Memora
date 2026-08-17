import '../../../core/backend/models/ai_chat_message.dart';
import '../../../core/database/app_database.dart';

/// Uma mensagem da conversa com o tutor do deck.
///
/// Mora aqui, e não em `core/`, porque a conversa é dado de uma feature só —
/// diferente de [AiChatMessage], que é o formato que o gateway de IA consome.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;

  factory ChatMessage.fromLocal(LocalChatMessage message) {
    return ChatMessage(
      id: message.id,
      role: roleFromName(message.role),
      content: message.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );
  }

  /// Cai em [ChatRole.assistant] no desconhecido: uma linha gravada por uma
  /// versão futura com outro papel vira uma bolha a mais na tela, não um
  /// histórico que não abre.
  static ChatRole roleFromName(String name) {
    return ChatRole.values.firstWhere(
      (role) => role.name == name,
      orElse: () => ChatRole.assistant,
    );
  }
}
