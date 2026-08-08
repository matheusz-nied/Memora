import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'legal_text.dart';

/// Abre a política e o e-mail de relato.
///
/// Toda falha vira mensagem na tela em vez de exceção: um `launchUrl` recusado
/// (sem navegador, sem app de e-mail, política de intents do fabricante) não
/// pode deixar o usuário achando que tocou num botão morto — e o endereço
/// aparece na mensagem para ele conseguir chegar lá por conta própria.
class LegalLinks {
  const LegalLinks._();

  static Future<void> openPrivacyPolicy(BuildContext context) async {
    await _open(
      context,
      Uri.parse(LegalText.privacyPolicyUrl),
      LegalText.openPolicyFailed,
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> reportContent(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalText.contactEmail,
      query: Uri.encodeFull(
        'subject=${LegalText.reportSubject}&body=${LegalText.reportBody}',
      ),
    );

    await _open(context, uri, LegalText.reportFailed);
  }

  static Future<void> _open(
    BuildContext context,
    Uri uri,
    String failureMessage, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: mode);
    } catch (_) {
      opened = false;
    }

    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}
