/// Textos e endereços das páginas legais.
class LegalText {
  const LegalText._();

  /// Endereço público da política. É o mesmo que vai nos formulários da Play
  /// Store e da App Store: uma vez submetido, mudá-lo exige reenviar o app
  /// para revisão, então esta constante não muda sem esse custo.
  static const String privacyPolicyUrl =
      'https://matheusz-nied.github.io/Memora/politica-de-privacidade.html';

  /// Para onde vai um relato de conteúdo problemático gerado pela IA.
  static const String contactEmail = 'matheusz.nied@gmail.com';

  /// Versão do texto aceita pelo usuário. Incrementar quando a política mudar
  /// de forma relevante faz o aviso reaparecer, que é o que a LGPD espera de
  /// uma alteração material.
  static const int acceptedVersion = 1;

  static const String privacyTitle = 'Privacidade';
  static const String privacyHint =
      'O que fica no aparelho e o que é enviado à IA.';
  static const String openPolicy = 'Ler a política de privacidade';
  static const String openPolicyFailed =
      'Não foi possível abrir a política. Acesse $privacyPolicyUrl pelo navegador.';

  /// Aceite no onboarding. Não é uma barreira: informar é obrigação, e travar
  /// a entrada num app que não coleta nada seria teatro.
  static const String consent =
      'Ao continuar, você concorda com a política de privacidade. '
      'Resumo: seus dados ficam neste aparelho; só o texto que você mandar '
      'para a IA sai daqui, direto para a DeepSeek, com a sua chave.';

  // --- Conteúdo gerado por IA ---

  /// Exigido pela App Store em app generativo, e honesto de qualquer forma.
  static const String aiDisclaimer =
      'Conteúdo gerado por IA: confira antes de estudar como verdade.';

  static const String reportContent = 'Reportar conteúdo';
  static const String reportSubject =
      'Memora — relato de conteúdo gerado por IA';
  static const String reportBody =
      'Descreva o que apareceu de errado e, se puder, cole o texto do card ou '
      'da resposta:\n\n';
  static const String reportFailed =
      'Não foi possível abrir o e-mail. Escreva para $contactEmail.';
}
