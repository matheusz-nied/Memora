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
}
