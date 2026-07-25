/// Consumo de IA do usuário no período corrente.
///
/// Neutro em relação ao backend: o adaptador Supabase preenche isto a partir
/// da função `ai_quota_status()`.
class AiQuotaStatus {
  const AiQuotaStatus({
    required this.used,
    required this.quota,
    required this.tier,
    required this.periodEnd,
  });

  /// Unidades de custo já consumidas no período.
  final int used;

  /// Teto de unidades do período para o tier atual.
  final int quota;

  /// Identificador do plano (`free`, `premium`).
  final String tier;

  /// Quando o contador zera.
  final DateTime periodEnd;

  int get remaining {
    final left = quota - used;
    return left < 0 ? 0 : left;
  }

  double get ratio {
    if (quota <= 0) {
      return 1;
    }
    final value = used / quota;
    return value > 1 ? 1 : value;
  }

  bool get isExhausted => remaining <= 0;
}
