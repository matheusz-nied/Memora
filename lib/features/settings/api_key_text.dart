class ApiKeyText {
  const ApiKeyText._();

  static const String title = 'Chave da DeepSeek';
  static const String subtitle =
      'Esta versão do Memora usa a sua própria chave da DeepSeek. Ela fica '
      'guardada só neste aparelho e é usada para gerar cards, insights e '
      'conversar com o agente.';

  static const String whereToGet =
      'Crie uma chave em platform.deepseek.com, na seção "API keys". O uso é '
      'cobrado direto na sua conta lá.';

  static const String fieldLabel = 'Chave da API';
  static const String fieldHint = 'sk-...';

  static const String save = 'Salvar chave';
  static const String remove = 'Remover chave';

  static const String savedTitle = 'Chave cadastrada';
  static const String emptyTitle = 'Nenhuma chave cadastrada';
  static const String emptyMessage =
      'Sem uma chave, os recursos de IA ficam indisponíveis. O estudo dos '
      'cards que você já tem continua funcionando normalmente.';

  static const String dashboardTitle = 'Ative os recursos de IA';
  static const String dashboardMessage =
      'Cadastre sua chave da DeepSeek para gerar cards, insights e conversar '
      'com o agente.';

  static const String required = 'Cole a sua chave para continuar.';
  static const String invalidFormat =
      'A chave da DeepSeek começa com "sk-". Confira o que você colou.';

  static const String saved = 'Chave salva.';
  static const String removed = 'Chave removida.';

  static String savedKey(String masked) => 'Chave atual: $masked';
}
