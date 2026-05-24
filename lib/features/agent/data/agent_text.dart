/// Static text constants for the agent feature (chat + config screens).
class AgentText {
  const AgentText._();

  // -- Agent Config --
  static const String configTitle = 'Configurar Agente';
  static const String agentNameLabel = 'Nome do agente';
  static const String agentNameHint = 'Ex: Tutor, Professor, Mentor...';
  static const String templateLabel = 'Template';
  static const String languageLabel = 'Idioma';
  static const String levelLabel = 'Nível';
  static const String customPromptLabel = 'Prompt personalizado';
  static const String customPromptHint =
      'Use as variáveis: {name}, {deck_title}, {deck_context}, {language}, {level}';
  static const String save = 'Salvar';
  static const String saving = 'Salvando...';
  static const String saveSuccess = 'Configuração salva com sucesso.';
  static const String saveError = 'Erro ao salvar configuração.';
  static const String configLoadError =
      'Não foi possível carregar as configurações.';
  static const String deckNotFound = 'Deck não encontrado.';

  // -- Chat --
  static const String chatTitle = 'Chat';
  static const String deckLabel = 'Deck';
  static const String inputPlaceholder = 'Pergunte sobre este deck...';
  static const String send = 'Enviar';
  static const String newConversation = 'Nova conversa';
  static const String agentConfig = 'Configurar agente';
  static const String messageLimitTitle = 'Limite de mensagens atingido';
  static const String messageLimitMessage =
      'Você atingiu o limite de 40 mensagens nesta sessão. Inicie uma nova conversa para continuar.';
  static const String offline = 'Chat requer conexão com a internet.';
  static const String loadingHistory = 'Carregando histórico...';
  static const String historyError =
      'Não foi possível carregar o histórico do chat.';
  static const String sendError = 'Erro ao enviar mensagem. Tente novamente.';
  static const String emptyChat =
      'Comece uma conversa com o agente sobre este deck.';
  static const String you = 'Você';
}
