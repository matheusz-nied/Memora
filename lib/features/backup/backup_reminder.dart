import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_provider.dart';

/// Timestamps que controlam o lembrete de backup no dashboard.
class BackupReminderState {
  const BackupReminderState({
    this.lastExportAt,
    this.dismissedAt,
  });

  /// Última exportação bem-sucedida (epoch ms), ou null se nunca exportou.
  final int? lastExportAt;

  /// Quando o usuário dispensou o card (epoch ms), ou null se nunca dispensou.
  final int? dismissedAt;
}

/// Quando o usuário exportou um backup pela última vez.
///
/// No modo local isto é a única rede de proteção que existe: perder o aparelho
/// é perder decks, cards e todo o histórico de estudo, que é justamente o dado
/// que não dá para reconstruir. A tela de backup existe desde sempre e ninguém
/// a visita sozinho — o lembrete é o que transforma um recurso disponível em
/// um recurso usado.
final backupReminderProvider =
    NotifierProvider<BackupReminderNotifier, BackupReminderState>(
  BackupReminderNotifier.new,
);

class BackupReminderNotifier extends Notifier<BackupReminderState> {
  static const String storageKey = 'backup_last_export_at';
  static const String dismissedStorageKey = 'backup_reminder_dismissed_at';

  /// Trinta dias: perto o bastante para o prejuízo de uma perda ser suportável
  /// e longe o bastante para o aviso não virar ruído que se aprende a ignorar.
  static const Duration reminderAfter = Duration(days: 30);

  /// Depois de dispensar, o card fica oculto por uma semana antes de voltar.
  static const Duration dismissSnooze = Duration(days: 7);

  @override
  BackupReminderState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return BackupReminderState(
      lastExportAt: prefs.getInt(storageKey),
      dismissedAt: prefs.getInt(dismissedStorageKey),
    );
  }

  Future<void> markExported({DateTime? at}) async {
    final moment = (at ?? DateTime.now()).millisecondsSinceEpoch;
    await ref.read(sharedPreferencesProvider).setInt(storageKey, moment);
    state = BackupReminderState(
      lastExportAt: moment,
      dismissedAt: state.dismissedAt,
    );
  }

  Future<void> dismiss({DateTime? at}) async {
    final moment = (at ?? DateTime.now()).millisecondsSinceEpoch;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(dismissedStorageKey, moment);
    state = BackupReminderState(
      lastExportAt: state.lastExportAt,
      dismissedAt: moment,
    );
  }
}

/// Se está na hora de lembrar.
///
/// Nunca ter exportado conta como atrasado — é exatamente o caso de quem mais
/// tem a perder, porque não sabe que a tela existe.
bool isBackupOverdue({required int? lastExportAt, required DateTime now}) {
  if (lastExportAt == null) {
    return true;
  }

  final last = DateTime.fromMillisecondsSinceEpoch(lastExportAt);
  return now.difference(last) >= BackupReminderNotifier.reminderAfter;
}

/// Se o card do dashboard deve aparecer agora.
///
/// Só lembra quando o export está atrasado; se o usuário dispensou, espera o
/// snooze de 7 dias antes de voltar a mostrar.
bool shouldShowBackupReminder({
  required int? lastExportAt,
  required int? dismissedAt,
  required DateTime now,
}) {
  if (!isBackupOverdue(lastExportAt: lastExportAt, now: now)) {
    return false;
  }
  if (dismissedAt == null) {
    return true;
  }

  final dismissed = DateTime.fromMillisecondsSinceEpoch(dismissedAt);
  return now.difference(dismissed) >= BackupReminderNotifier.dismissSnooze;
}
