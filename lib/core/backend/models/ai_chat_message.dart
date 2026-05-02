import 'backend_chat_message.dart';

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final BackendChatRole role;
  final String content;
}
