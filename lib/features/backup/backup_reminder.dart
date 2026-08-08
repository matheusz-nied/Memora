import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_provider.dart';

/// Quando o usuário exportou um backup pela última vez.
///
/// No modo local isto é a única rede de proteção que existe: perder o aparelho
/// é perder decks, cards e todo o histórico de estudo, que é justamente o dado
/// que não dá para reconstruir. A tela de backup existe desde sempre e ninguém
/// a visita sozinho — o lembrete é o que transforma um recurso disponível em
/// um recurso usado.
final backupReminderProvider = NotifierProvider<BackupReminderNotifier, int?>(
  BackupReminderNotifier.new,
);

class BackupReminderNotifier extends Notifier<int?> {
  static const String storageKey = 'backup_last_export_at';

  /// Trinta dias: perto o bastante para o prejuízo de uma perda ser suportável
  /// e longe o bastante para o aviso não virar ruído que se aprende a ignorar.
  static const Duration reminderAfter = Duration(days: 30);

  @override
  int? build() => ref.watch(sharedPreferencesProvider).getInt(storageKey);

  Future<void> markExported({DateTime? at}) async {
    final moment = (at ?? DateTime.now()).millisecondsSinceEpoch;
    await ref.read(sharedPreferencesProvider).setInt(storageKey, moment);
    state = moment;
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
