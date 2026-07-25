import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_provider.dart';
import '../../core/backend/models/ai_quota_status.dart';

/// Consumo de IA do usuário no período corrente.
///
/// `autoDispose` de propósito: o saldo muda a cada operação de IA, e a tela de
/// perfil é aberta depois delas. Refazer a leitura a cada abertura é mais
/// barato e mais confiável do que invalidar em todo call site de IA.
final aiQuotaStatusProvider = FutureProvider.autoDispose<AiQuotaStatus>((ref) {
  return ref.watch(backendClientProvider).ai.fetchQuotaStatus();
});
