import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/models/ai_quota_status.dart';
import 'package:memora/core/backend/models/backend_exception.dart';

AiQuotaStatus _status({required int used, int quota = 30}) {
  return AiQuotaStatus(
    used: used,
    quota: quota,
    tier: 'free',
    periodEnd: DateTime(2026, 8),
  );
}

void main() {
  group('AiQuotaStatus', () {
    test('calcula restante e proporção no meio do período', () {
      final status = _status(used: 18);

      expect(status.remaining, 12);
      expect(status.ratio, closeTo(0.6, 0.0001));
      expect(status.isExhausted, isFalse);
    });

    test('nunca reporta restante negativo nem proporção acima de 1', () {
      // O servidor reserva antes de chamar a IA, mas uma mudança de tier para
      // baixo deixa `used` acima do teto.
      final status = _status(used: 45);

      expect(status.remaining, 0);
      expect(status.ratio, 1);
      expect(status.isExhausted, isTrue);
    });

    test('trata quota zero sem divisão por zero', () {
      final status = _status(used: 0, quota: 0);

      expect(status.ratio, 1);
      expect(status.remaining, 0);
      expect(status.isExhausted, isTrue);
    });

    test('marca esgotado exatamente no teto', () {
      final status = _status(used: 30);

      expect(status.remaining, 0);
      expect(status.isExhausted, isTrue);
    });
  });

  group('BackendException', () {
    test('reconhece os códigos de limite vindos das Edge Functions', () {
      const quota = BackendException('...', code: 'quota_exceeded');
      const rate = BackendException('...', code: 'rate_limited');
      const other = BackendException('...', code: 'deepseek_402');
      const none = BackendException('...');

      expect(quota.isQuotaExceeded, isTrue);
      expect(quota.isRateLimited, isFalse);
      expect(rate.isRateLimited, isTrue);
      expect(other.isQuotaExceeded, isFalse);
      expect(none.isQuotaExceeded, isFalse);
    });

    test('toString devolve só a mensagem, para a UI exibir direto', () {
      const exception = BackendException('Limite mensal atingido.');

      expect(exception.toString(), 'Limite mensal atingido.');
    });
  });
}
