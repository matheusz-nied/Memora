class BackendException implements Exception {
  const BackendException(this.message, {this.code});

  final String message;

  /// Código estável devolvido pelo backend (ex.: `quota_exceeded`,
  /// `rate_limited`). Serve para a UI reagir sem depender do texto.
  final String? code;

  static const String codeQuotaExceeded = 'quota_exceeded';
  static const String codeRateLimited = 'rate_limited';

  bool get isQuotaExceeded => code == codeQuotaExceeded;

  bool get isRateLimited => code == codeRateLimited;

  @override
  String toString() => message;
}
