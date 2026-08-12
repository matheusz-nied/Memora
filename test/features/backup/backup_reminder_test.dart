import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/backup/backup_reminder.dart';

void main() {
  final now = DateTime(2026, 8, 8, 10);

  test('nunca ter exportado conta como atrasado', () {
    // É o caso de quem mais tem a perder: não sabe que a tela existe.
    expect(isBackupOverdue(lastExportAt: null, now: now), isTrue);
  });

  test('exportou hoje não lembra', () {
    expect(
      isBackupOverdue(
        lastExportAt: now
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
        now: now,
      ),
      isFalse,
    );
  });

  test('um dia antes do prazo ainda não lembra', () {
    expect(
      isBackupOverdue(
        lastExportAt: now
            .subtract(const Duration(days: 29))
            .millisecondsSinceEpoch,
        now: now,
      ),
      isFalse,
    );
  });

  test('no dia do prazo lembra', () {
    expect(
      isBackupOverdue(
        lastExportAt: now
            .subtract(BackupReminderNotifier.reminderAfter)
            .millisecondsSinceEpoch,
        now: now,
      ),
      isTrue,
    );
  });

  test('relógio para trás não trava o lembrete para sempre', () {
    // Fuso ou ajuste manual podem gravar um export "no futuro". Ele não deve
    // lembrar agora, mas também não pode inverter o sinal e virar atrasado.
    expect(
      isBackupOverdue(
        lastExportAt: now.add(const Duration(days: 2)).millisecondsSinceEpoch,
        now: now,
      ),
      isFalse,
    );
  });

  group('shouldShowBackupReminder', () {
    test('atrasado e nunca dispensado mostra', () {
      expect(
        shouldShowBackupReminder(
          lastExportAt: null,
          dismissedAt: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('atrasado e dispensado há 3 dias oculta', () {
      expect(
        shouldShowBackupReminder(
          lastExportAt: null,
          dismissedAt: now
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch,
          now: now,
        ),
        isFalse,
      );
    });

    test('atrasado e dispensado há 7+ dias mostra de novo', () {
      expect(
        shouldShowBackupReminder(
          lastExportAt: null,
          dismissedAt: now
              .subtract(BackupReminderNotifier.dismissSnooze)
              .millisecondsSinceEpoch,
          now: now,
        ),
        isTrue,
      );
    });

    test('export recente oculta mesmo se dispensado', () {
      expect(
        shouldShowBackupReminder(
          lastExportAt: now
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
          dismissedAt: now
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
