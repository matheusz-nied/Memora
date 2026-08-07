class BackendException implements Exception {
  const BackendException(this.message, {this.code});

  final String message;

  /// Código estável devolvido pelo backend (ex.: `quota_exceeded`,
  /// `rate_limited`). Serve para a UI reagir sem depender do texto.
  final String? code;

  static const String codeQuotaExceeded = 'quota_exceeded';
  static const String codeRateLimited = 'rate_limited';

  /// A requisição estourou o timeout do cliente antes de qualquer resposta.
  static const String codeClientTimeout = 'client_timeout';

  /// A IA não respondeu dentro do timeout aplicado pela Edge Function.
  static const String codeAiTimeout = 'deepseek_timeout';

  bool get isQuotaExceeded => code == codeQuotaExceeded;

  bool get isRateLimited => code == codeRateLimited;

  /// Falha de espera — a operação pode ser repetida como está.
  bool get isTimeout => code == codeClientTimeout || code == codeAiTimeout;

  @override
  String toString() => message;
}
