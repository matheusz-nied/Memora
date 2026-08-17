/// Quem falou. Os nomes dos valores vão para o prompt e para a coluna
/// `chat_messages.role`, então renomear um deles quebra as conversas salvas.
enum ChatRole { user, assistant }

/// Uma fala do histórico, no formato mínimo que o [AiGateway] precisa.
///
/// Separada da mensagem persistida (`ChatMessage`, na feature do agente):
/// para montar o prompt não interessa id, deck nem horário.
class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final ChatRole role;
  final String content;
}
