/// Erro que a UI sabe mostrar: mensagem já em português e pronta para a tela.
///
/// Continua se chamando "backend" porque é isso que ela representa — a falha
/// veio de fora do app. Hoje o único lá fora é a API da DeepSeek.
class BackendException implements Exception {
  const BackendException(this.message, {this.code});

  final String message;

  /// Código estável (ex.: `rate_limited`), para a UI reagir sem depender do
  /// texto da mensagem.
  final String? code;

  static const String codeRateLimited = 'rate_limited';

  /// A requisição estourou o timeout do cliente antes de qualquer resposta.
  static const String codeClientTimeout = 'client_timeout';

  /// A DeepSeek não respondeu dentro do timeout aplicado na chamada.
  static const String codeAiTimeout = 'deepseek_timeout';

  bool get isRateLimited => code == codeRateLimited;

  /// Falha de espera — a operação pode ser repetida como está.
  bool get isTimeout => code == codeClientTimeout || code == codeAiTimeout;

  @override
  String toString() => message;
}
