class QuotaText {
  const QuotaText._();

  static const String title = 'CRÉDITOS DE IA';
  static const String loadError = 'Não foi possível carregar seu consumo.';
  static const String retry = 'Tentar de novo';
  static const String tierFree = 'Plano gratuito';
  static const String tierPremium = 'Plano premium';
  static const String exhausted = 'Créditos esgotados';

  static String usage(int used, int quota) {
    return '$used de $quota usados neste mês';
  }

  static String renewal(DateTime periodEnd) {
    final day = periodEnd.day.toString().padLeft(2, '0');
    final month = periodEnd.month.toString().padLeft(2, '0');
    return 'Renova em $day/$month';
  }

  /// Custo em créditos por operação, para o usuário entender o consumo.
  static const String costHint =
      'Chat e insight custam 1 crédito. Gerar cards custa 2, e por PDF custa 3.';
}
