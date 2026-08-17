import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_provider.dart';
import 'legal_text.dart';

/// Qual versão da política o usuário já viu.
///
/// Guardar a versão, e não um booleano, é o que permite reapresentar o aviso
/// quando a política mudar de forma relevante — a LGPD trata alteração
/// material como algo que precisa ser comunicado, não silenciosamente
/// aplicado.
final privacyAcceptedVersionProvider =
    NotifierProvider<PrivacyConsentNotifier, int>(PrivacyConsentNotifier.new);

class PrivacyConsentNotifier extends Notifier<int> {
  static const String storageKey = 'privacy_accepted_version';

  @override
  int build() {
    return ref.watch(sharedPreferencesProvider).getInt(storageKey) ?? 0;
  }

  /// Registra o aceite da versão vigente.
  Future<void> accept() async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(storageKey, LegalText.acceptedVersion);
    state = LegalText.acceptedVersion;
  }

  bool get isCurrent => state >= LegalText.acceptedVersion;
}
